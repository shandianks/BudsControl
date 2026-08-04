import Foundation
import CoreBluetooth
import Combine

class BluetoothManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isScanning = false
    @Published var isConnected = false
    @Published var discoveredDevices: [BudsDevice] = []
    @Published var errorMessage: String?
    
    // Device Status
    @Published var batteryLeft: Int = 0
    @Published var batteryRight: Int = 0
    @Published var batteryCase: Int = 0
    @Published var isLeftCharging = false
    @Published var isRightCharging = false
    @Published var isCaseCharging = false
    @Published var isLeftWearing = false
    @Published var isRightWearing = false
    @Published var isCoupled = false
    @Published var mainConnection: DeviceSide = .left
    
    // Settings
    @Published var isAmbientSoundOn = false
    @Published var ambientVolume: Int = 0
    @Published var isTouchpadLocked = false
    @Published var currentEQPreset: EQPreset = .normal
    @Published var noiseControlMode: NoiseControlMode = .off
    @Published var isGamingModeOn = false
    
    // Device Info
    @Published var firmwareVersion = "Unknown"
    @Published var serialNumber = "Unknown"
    @Published var deviceColor = "Unknown"
    
    // MARK: - Private Properties
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var sppCharacteristic: CBCharacteristic?
    private var currentDevice: BudsDevice?
    
    // Galaxy Buds2 Service UUIDs
    private let sppServiceUUID = CBUUID(string: "2e889123-5b00-4e0a-8fd1-5c55e0ce711c")
    private let sppCharacteristicUUID = CBUUID(string: "2e889124-5b00-4e0a-8fd1-5c55e0ce711c")
    
    // Legacy service UUIDs for fallback
    private let legacyServiceUUIDs: [CBUUID] = [
        CBUUID(string: "00001101-0000-1000-8000-00805F9B34FB"), // Standard SPP
        CBUUID(string: "2e889123-5b00-4e0a-8fd1-5c55e0ce711c")  // Buds2 specific
    ]
    
    private var messageBuffer = Data()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    // MARK: - Public Methods
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            errorMessage = "Bluetooth is not powered on"
            return
        }
        
        isScanning = true
        errorMessage = nil
        discoveredDevices.removeAll()
        
        // Scan for devices with Galaxy Buds2 service or general Bluetooth devices
        centralManager.scanForPeripherals(
            withServices: nil, // Scan all devices to find Buds2 by name
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        
        // Stop scanning after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.stopScanning()
        }
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }
    
    func connect(to device: BudsDevice) {
        stopScanning()
        
        guard let peripheral = device.peripheral else {
            errorMessage = "Invalid peripheral"
            return
        }
        
        currentDevice = device
        connectedPeripheral = peripheral
        peripheral.delegate = self
        
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        resetState()
    }
    
    // MARK: - Send Commands
    func sendMessage(_ message: SPPMessage) {
        guard let peripheral = connectedPeripheral,
              let characteristic = sppCharacteristic else {
            print("Cannot send message: not connected")
            return
        }
        
        let data = message.encode()
        peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
    }
    
    func requestStatusUpdate() {
        let message = SPPMessage(
            id: .statusUpdated,
            type: .request,
            payload: []
        )
        sendMessage(message)
    }
    
    func setEqualizer(preset: EQPreset) {
        let message = MessageEncoder.encodeEqualizer(preset: preset)
        sendMessage(message)
        currentEQPreset = preset
    }
    
    func setAmbientSound(enabled: Bool) {
        let message = MessageEncoder.encodeAmbientMode(enabled: enabled)
        sendMessage(message)
        isAmbientSoundOn = enabled
    }
    
    func setAmbientVolume(_ volume: Int) {
        let message = MessageEncoder.encodeAmbientVolume(volume: volume)
        sendMessage(message)
        ambientVolume = volume
    }
    
    func setTouchpadLock(_ locked: Bool) {
        let message = MessageEncoder.encodeTouchpadLock(locked: locked)
        sendMessage(message)
        isTouchpadLocked = locked
    }
    
    func setNoiseControl(mode: NoiseControlMode) {
        // Buds2 uses ambient mode for noise control
        switch mode {
        case .off:
            setAmbientSound(enabled: false)
        case .ambient:
            setAmbientSound(enabled: true)
        case .anc:
            // ANC is not available on standard Buds2, only on Buds2 Pro
            break
        }
        noiseControlMode = mode
    }
    
    func findMyBuds(start: Bool) {
        let message = start ?
            SPPMessage(id: .findMyEarbudsStart, type: .request, payload: []) :
            SPPMessage(id: .findMyEarbudsStop, type: .request, payload: [])
        sendMessage(message)
    }
    
    func setGamingMode(_ enabled: Bool) {
        let message = MessageEncoder.encodeGamingMode(enabled: enabled)
        sendMessage(message)
        isGamingModeOn = enabled
    }
    
    func updateTime() {
        let message = MessageEncoder.encodeUpdateTime()
        sendMessage(message)
    }
    
    func sendManagerInfo() {
        let message = MessageEncoder.encodeManagerInfo()
        sendMessage(message)
    }
    
    // MARK: - Private Methods
    private func resetState() {
        isConnected = false
        connectedPeripheral = nil
        sppCharacteristic = nil
        currentDevice = nil
        messageBuffer.removeAll()
        
        // Reset status
        batteryLeft = 0
        batteryRight = 0
        batteryCase = 0
        isLeftCharging = false
        isRightCharging = false
        isCaseCharging = false
        isLeftWearing = false
        isRightWearing = false
        isAmbientSoundOn = false
        isTouchpadLocked = false
        currentEQPreset = .normal
        noiseControlMode = .off
        firmwareVersion = "Unknown"
        serialNumber = "Unknown"
    }
    
    private func processReceivedData(_ data: Data) {
        messageBuffer.append(data)
        
        // Try to decode messages from buffer
        while messageBuffer.count >= 6 {
            do {
                let (message, consumed) = try SPPMessage.decode(from: messageBuffer)
                handleMessage(message)
                messageBuffer.removeFirst(consumed)
            } catch SPPError.incompletePacket {
                // Need more data
                break
            } catch {
                // Invalid packet, try to find next SOM
                if let somIndex = messageBuffer.dropFirst().firstIndex(of: SPPMessage.som) {
                    messageBuffer.removeFirst(somIndex)
                } else {
                    messageBuffer.removeAll()
                }
            }
        }
    }
    
    private func handleMessage(_ message: SPPMessage) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch message.id {
            case .statusUpdated:
                if let status = MessageDecoder.decodeStatusUpdate(message) {
                    self.batteryLeft = status.batteryL
                    self.batteryRight = status.batteryR
                    self.batteryCase = status.batteryCase
                    self.isLeftCharging = status.isLeftCharging
                    self.isRightCharging = status.isRightCharging
                    self.isCaseCharging = status.isCaseCharging
                    self.isLeftWearing = status.placementL == .wearing
                    self.isRightWearing = status.placementR == .wearing
                    self.isCoupled = status.isCoupled
                    self.mainConnection = status.mainConnection
                }
                
            case .extendedStatusUpdated:
                if let status = MessageDecoder.decodeExtendedStatusUpdate(message) {
                    self.batteryLeft = status.batteryL
                    self.batteryRight = status.batteryR
                    self.batteryCase = status.batteryCase
                    self.isAmbientSoundOn = status.ambientSoundEnabled
                    self.ambientVolume = status.ambientVolume
                    self.isTouchpadLocked = status.touchLock
                    self.currentEQPreset = EQPreset(rawValue: status.equalizerMode) ?? .normal
                    
                    // Send acknowledgment
                    self.sendManagerInfo()
                }
                
            case .acknowledgement:
                print("Received acknowledgement")
                
            case .versionInfo:
                if let version = MessageDecoder.decodeVersionInfo(message) {
                    self.firmwareVersion = version
                }
                
            case .serialNumber:
                if let serial = MessageDecoder.decodeSerialNumber(message) {
                    self.serialNumber = serial
                }
                
            default:
                print("Received message: \(message.id)")
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
        case .poweredOff:
            errorMessage = "Bluetooth is turned off"
        case .unsupported:
            errorMessage = "Bluetooth is not supported on this device"
        case .unauthorized:
            errorMessage = "Bluetooth permission denied"
        default:
            errorMessage = "Bluetooth unavailable"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name else { return }
        
        // Filter for Galaxy Buds devices
        let budsKeywords = ["Buds2", "Galaxy Buds", "Buds Pro", "Buds Live", "Buds FE"]
        let isBudsDevice = budsKeywords.contains { name.contains($0) }
        
        if isBudsDevice {
            let device = BudsDevice(
                id: peripheral.identifier.uuidString,
                name: name,
                uuid: peripheral.identifier,
                peripheral: peripheral,
                rssi: RSSI.intValue
            )
            
            DispatchQueue.main.async { [weak self] in
                if !(self?.discoveredDevices.contains(where: { $0.id == device.id }) ?? false) {
                    self?.discoveredDevices.append(device)
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Unknown")")
        isConnected = true
        peripheral.discoverServices([sppServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        errorMessage = "Failed to connect: \(error?.localizedDescription ?? "Unknown error")"
        resetState()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.name ?? "Unknown")")
        resetState()
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid == sppServiceUUID {
                peripheral.discoverCharacteristics([sppCharacteristicUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == sppCharacteristicUUID {
                sppCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                
                // Request initial status
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.updateTime()
                    self?.requestStatusUpdate()
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        processReceivedData(data)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Failed to enable notifications: \(error.localizedDescription)")
        } else {
            print("Notifications enabled for \(characteristic.uuid)")
        }
    }
}

// MARK: - Supporting Types
struct BudsDevice: Identifiable {
    let id: String
    let name: String
    let uuid: UUID
    let peripheral: CBPeripheral?
    let rssi: Int
}

enum DeviceSide {
    case left
    case right
}

enum EQPreset: String, CaseIterable {
    case normal = "Normal"
    case bassBoost = "Bass Boost"
    case soft = "Soft"
    case dynamic = "Dynamic"
    case clear = "Clear"
    case trebleBoost = "Treble Boost"
    
    var id: Int {
        switch self {
        case .normal: return 0
        case .bassBoost: return 1
        case .soft: return 2
        case .dynamic: return 3
        case .clear: return 4
        case .trebleBoost: return 5
        }
    }
}

enum NoiseControlMode: String {
    case off = "Off"
    case ambient = "Ambient"
    case anc = "ANC"
}

enum PlacementState {
    case idle
    case wearing
    case charging
    case inCase
    case unknown
}
