import Foundation
import CoreBluetooth
import Combine

// MARK: - SPP Message Structure
struct SPPMessage {
    var id: UInt8
    var payload: Data
    var isResponse: Bool = false
    var isFragment: Bool = false
    
    static let som: UInt8 = 0xFD
    static let eom: UInt8 = 0xDD
    static let smepSom: UInt8 = 0xFE
    static let smepEom: UInt8 = 0xEE
    
    func encode() -> Data {
        var data = Data()
        data.append(SPPMessage.som)
        
        let payloadSize = UInt16(1 + payload.count + 2) // msgId + payload + crc
        var header = payloadSize
        if isFragment { header |= 0x2000 }
        if isResponse { header |= 0x1000 }
        
        data.append(UInt8((header >> 8) & 0xFF))
        data.append(UInt8(header & 0xFF))
        data.append(id)
        data.append(contentsOf: payload)
        
        let crcData = Data([id]) + payload
        let crc = CRC16.ccitt(crcData)
        data.append(UInt8(crc & 0xFF))
        data.append(UInt8((crc >> 8) & 0xFF))
        data.append(SPPMessage.eom)
        
        return data
    }
}

// MARK: - CRC16-CCITT
enum CRC16 {
    private static let table: [UInt16] = {
        var table = [UInt16](repeating: 0, count: 256)
        for i in 0..<256 {
            var crc = UInt16(i) << 8
            for _ in 0..<8 {
                if crc & 0x8000 != 0 {
                    crc = (crc << 1) ^ 0x1021
                } else {
                    crc = crc << 1
                }
            }
            table[i] = crc
        }
        return table
    }()
    
    static func ccitt(_ data: Data) -> UInt16 {
        var crc: UInt16 = 0x0000
        for byte in data {
            let idx = Int((crc >> 8) ^ UInt16(byte)) & 0xFF
            crc = (crc << 8) ^ table[idx]
        }
        return crc
    }
}

// MARK: - Message IDs
enum MsgId: UInt8 {
    case statusUpdated = 0x60
    case extendedStatusUpdated = 0x61
    case updateTime = 0x64
    case managerInfo = 0x65
    case equalizer = 0x66
    case lockTouchpad = 0x67
    case setAmbientMode = 0x68
    case ambientVolume = 0x69
    case gameMode = 0x6F
    case findMyEarbudsStart = 0x70
    case findMyEarbudsStop = 0x71
    case serialNumber = 0x72
    case debugGetAllData = 0x74
    case debugBuildInfo = 0x75
    case acknowledgement = 0x7C
    case versionInfo = 0x7D
    case ambientModeUpdate = 0x7E
    case ambientVoiceFocus = 0x7F
    case ambientWearingUpdate = 0x80
    case noiseReduction = 0x81
    case anc = 0x86
    case ancLevel = 0x87
    case noiseControl = 0x93
    case noiseControlDual = 0x94
    case chargingState = 0x95
    case smartThingsFind = 0x97
}

// MARK: - Device Models
enum DeviceModel: String, CaseIterable {
    case buds2 = "Buds2"
    case buds2Pro = "Buds2 Pro"
    case budsPro = "Buds Pro"
    case budsLive = "Buds Live"
    case budsPlus = "Buds+"
    case buds3 = "Buds3"
    case buds3Pro = "Buds3 Pro"
    case budsFE = "Buds FE"
    
    var supportsNoiseControl: Bool {
        switch self {
        case .buds2, .buds2Pro, .budsPro, .buds3, .buds3Pro:
            return true
        default:
            return false
        }
    }
    
    var supportsANC: Bool {
        switch self {
        case .buds2Pro, .budsPro, .buds3Pro:
            return true
        default:
            return false
        }
    }
    
    var supportsAmbientSound: Bool {
        switch self {
        case .buds2, .buds2Pro, .budsPro, .budsLive, .buds3, .buds3Pro, .budsFE:
            return true
        default:
            return false
        }
    }
    
    var supportsCaseBattery: Bool {
        switch self {
        case .budsPlus, .buds2, .buds2Pro, .budsPro, .buds3, .buds3Pro, .budsFE:
            return true
        default:
            return false
        }
    }
    
    var supportsChargingState: Bool {
        switch self {
        case .buds2, .buds2Pro, .buds3, .buds3Pro:
            return true
        default:
            return false
        }
    }
    
    var supportsGamingMode: Bool {
        switch self {
        case .buds2, .buds2Pro, .budsPro, .buds3, .buds3Pro:
            return true
        default:
            return false
        }
    }
    
    var serviceUUID: String {
        return "2e889123-5b00-4e0a-8fd1-5c55e0ce711c"
    }
    
    var maximumAmbientVolume: Int {
        return 2
    }
}

// MARK: - EQ Preset
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

// MARK: - Noise Control Mode
enum NoiseControlMode: String, CaseIterable {
    case off = "Off"
    case ambient = "Ambient Sound"
    case anc = "Active Noise Canceling"
    
    var id: Int {
        switch self {
        case .off: return 0
        case .ambient: return 1
        case .anc: return 2
        }
    }
}

// MARK: - Device Side
enum DeviceSide {
    case left
    case right
}

// MARK: - Placement State
enum PlacementState: String {
    case idle = "Idle"
    case wearing = "Wearing"
    case charging = "Charging"
    case inCase = "In Case"
    case unknown = "Unknown"
}

// MARK: - Buds Device
struct BudsDevice: Identifiable {
    let id = UUID()
    let name: String
    let uuid: UUID
    let peripheral: CBPeripheral?
    let rssi: Int
    var model: DeviceModel = .buds2
}

// MARK: - Bluetooth Manager
class BluetoothManager: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var isConnected = false
    @Published var discoveredDevices: [BudsDevice] = []
    @Published var errorMessage: String?
    @Published var bluetoothDiagnostics: [String] = []
    
    // Battery
    @Published var batteryLeft: Int = 0
    @Published var batteryRight: Int = 0
    @Published var batteryCase: Int = 0
    @Published var isLeftCharging = false
    @Published var isRightCharging = false
    @Published var isCaseCharging = false
    
    // Status
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
    @Published var currentModel: DeviceModel = .buds2
    
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var sppCharacteristic: CBCharacteristic?
    private var currentDevice: BudsDevice?
    private var pendingConnection = false
    
    private let sppServiceUUID = CBUUID(string: "2e889123-5b00-4e0a-8fd1-5c55e0ce711c")
    private let sppCharacteristicUUID = CBUUID(string: "2e889124-5b00-4e0a-8fd1-5c55e0ce711c")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            errorMessage = "Bluetooth is not powered on"
            return
        }
        
        isScanning = true
        errorMessage = nil
        bluetoothDiagnostics.removeAll()
        discoveredDevices.removeAll()
        
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        
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
        pendingConnection = true
        isConnected = false
        errorMessage = "Connecting to \(device.name)…"
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        resetState()
    }
    
    private func resetState() {
        isConnected = false
        pendingConnection = false
        connectedPeripheral = nil
        sppCharacteristic = nil
        currentDevice = nil
        batteryLeft = 0
        batteryRight = 0
        batteryCase = 0
        isLeftCharging = false
        isRightCharging = false
        isCaseCharging = false
        isLeftWearing = false
        isRightWearing = false
        isAmbientSoundOn = false
        ambientVolume = 0
        isTouchpadLocked = false
        currentEQPreset = .normal
        noiseControlMode = .off
        isGamingModeOn = false
        firmwareVersion = "Unknown"
        serialNumber = "Unknown"
        deviceColor = "Unknown"
    }
    
    // MARK: - Send Commands
    
    private func sendMessage(_ message: SPPMessage) {
        guard let characteristic = sppCharacteristic,
              let peripheral = connectedPeripheral else { return }
        
        let data = message.encode()
        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write)
            ? .withResponse
            : .withoutResponse
        peripheral.writeValue(data, for: characteristic, type: writeType)
    }
    
    func setEqualizer(_ preset: EQPreset) {
        let message = SPPMessage(id: MsgId.equalizer.rawValue, payload: Data([UInt8(preset.id)]))
        sendMessage(message)
        currentEQPreset = preset
    }
    
    func setAmbientMode(_ enabled: Bool) {
        let message = SPPMessage(id: MsgId.setAmbientMode.rawValue, payload: Data([enabled ? 0x01 : 0x00]))
        sendMessage(message)
        isAmbientSoundOn = enabled
    }
    
    func setAmbientVolume(_ volume: Int) {
        let clampedVolume = max(0, min(volume, currentModel.maximumAmbientVolume))
        let message = SPPMessage(id: MsgId.ambientVolume.rawValue, payload: Data([UInt8(clampedVolume)]))
        sendMessage(message)
        ambientVolume = clampedVolume
    }
    
    func setTouchpadLock(_ locked: Bool) {
        let message = SPPMessage(id: MsgId.lockTouchpad.rawValue, payload: Data([locked ? 0x01 : 0x00]))
        sendMessage(message)
        isTouchpadLocked = locked
    }
    
    func setNoiseControl(_ mode: NoiseControlMode) {
        guard currentModel.supportsNoiseControl else { return }
        let message = SPPMessage(id: MsgId.noiseControl.rawValue, payload: Data([UInt8(mode.id)]))
        sendMessage(message)
        noiseControlMode = mode
    }
    
    func setGamingMode(_ enabled: Bool) {
        guard currentModel.supportsGamingMode else { return }
        let message = SPPMessage(id: MsgId.gameMode.rawValue, payload: Data([enabled ? 0x01 : 0x00]))
        sendMessage(message)
        isGamingModeOn = enabled
    }
    
    func startFindMyEarbuds() {
        let message = SPPMessage(id: MsgId.findMyEarbudsStart.rawValue, payload: Data())
        sendMessage(message)
    }
    
    func stopFindMyEarbuds() {
        let message = SPPMessage(id: MsgId.findMyEarbudsStop.rawValue, payload: Data())
        sendMessage(message)
    }
    
    // MARK: - Decode Messages
    
    private func decodeMessage(_ data: Data) {
        guard data.count >= 5 else { return }
        guard data[0] == SPPMessage.som else { return }
        
        let header = (UInt16(data[1]) << 8) | UInt16(data[2])
        let msgId = data[3]
        let payloadSize = Int(header & 0x07FF) - 3
        
        guard data.count >= 5 + payloadSize + 1 else { return }
        
        let payload = data.subdata(in: 4..<(4 + payloadSize))
        
        switch msgId {
        case MsgId.statusUpdated.rawValue:
            decodeStatusUpdate(payload)
        case MsgId.extendedStatusUpdated.rawValue:
            decodeExtendedStatusUpdate(payload)
        case MsgId.versionInfo.rawValue:
            decodeVersionInfo(payload)
        case MsgId.serialNumber.rawValue:
            decodeSerialNumber(payload)
        case MsgId.chargingState.rawValue:
            decodeChargingState(payload)
        case MsgId.noiseControl.rawValue:
            decodeNoiseControl(payload)
        default:
            break
        }
    }
    
    private func decodeStatusUpdate(_ payload: Data) {
        guard payload.count >= 7 else { return }
        
        batteryLeft = Int(payload[1])
        batteryRight = Int(payload[2])
        isCoupled = payload[3] != 0
        mainConnection = payload[4] == 1 ? .left : .right
        
        let placementByte = payload[5]
        let leftPlacement = Int((placementByte & 0xF0) >> 4)
        let rightPlacement = Int(placementByte & 0x0F)
        
        isLeftWearing = leftPlacement == 1
        isRightWearing = rightPlacement == 1
        
        if payload.count >= 8 && currentModel.supportsCaseBattery {
            batteryCase = Int(payload[6])
        }
        
        if payload.count >= 9 && currentModel.supportsChargingState {
            let chargingByte = payload[7]
            isLeftCharging = ((chargingByte >> 4) & 0x01) != 0
            isRightCharging = ((chargingByte >> 2) & 0x01) != 0
            isCaseCharging = (chargingByte & 0x01) != 0
        }
    }
    
    private func decodeExtendedStatusUpdate(_ payload: Data) {
        guard payload.count >= 18 else { return }
        
        isAmbientSoundOn = payload[8] != 0
        ambientVolume = Int(payload[17])
        isTouchpadLocked = payload[12] != 0
        
        if payload[11] < 6 {
            currentEQPreset = EQPreset.allCases[Int(payload[11])]
        }
    }
    
    private func decodeVersionInfo(_ payload: Data) {
        if let version = String(bytes: payload, encoding: .utf8) {
            firmwareVersion = version.trimmingCharacters(in: .controlCharacters)
        }
    }
    
    private func decodeSerialNumber(_ payload: Data) {
        if let serial = String(bytes: payload, encoding: .utf8) {
            serialNumber = serial.trimmingCharacters(in: .controlCharacters)
        }
    }
    
    private func decodeChargingState(_ payload: Data) {
        guard payload.count >= 1 else { return }
        let chargingByte = payload[0]
        isLeftCharging = ((chargingByte >> 4) & 0x01) != 0
        isRightCharging = ((chargingByte >> 2) & 0x01) != 0
        isCaseCharging = (chargingByte & 0x01) != 0
    }
    
    private func decodeNoiseControl(_ payload: Data) {
        guard payload.count >= 1 else { return }
        switch payload[0] {
        case 0x00: noiseControlMode = .off
        case 0x01: noiseControlMode = .ambient
        case 0x02: noiseControlMode = .anc
        default: break
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            errorMessage = "Bluetooth is not available"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? "Unknown Device"
        
        // Check if it's a Galaxy Buds device
        let budsKeywords = ["Buds2", "Galaxy Buds", "Buds Pro", "Buds Live", "Buds+", "Buds3"]
        let isBudsDevice = budsKeywords.contains { name.contains($0) }
        
        if isBudsDevice {
            let device = BudsDevice(
                name: name,
                uuid: peripheral.identifier,
                peripheral: peripheral,
                rssi: RSSI.intValue
            )
            
            if !discoveredDevices.contains(where: { $0.uuid == device.uuid }) {
                discoveredDevices.append(device)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        pendingConnection = true
        errorMessage = "Connected; discovering Buds control service…"
        // Do not restrict discovery to one guessed UUID. Firmware revisions can
        // expose the SPP service differently on iOS.
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        errorMessage = "Failed to connect: \(error?.localizedDescription ?? "Unknown error")"
        resetState()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        resetState()
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            errorMessage = "Service discovery failed: \(error!.localizedDescription)"
            return
        }

        let services = peripheral.services ?? []
        guard !services.isEmpty else {
            errorMessage = "Buds returned no Bluetooth services"
            return
        }

        bluetoothDiagnostics = services.map { "Service: \($0.uuid.uuidString)" }

        // Discover every characteristic. Do not assume that a classic SPP UUID
        // is also exposed as a BLE GATT characteristic.
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            errorMessage = "Characteristic discovery failed: \(error!.localizedDescription)"
            return
        }

        for characteristic in service.characteristics ?? [] {
            let isKnownSPP = characteristic.uuid == sppCharacteristicUUID
            let canWrite = characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse)
            let canNotify = characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate)
            let properties = characteristic.properties.map { String(describing: $0) }.joined(separator: ",")
            bluetoothDiagnostics.append("Characteristic: \(service.uuid.uuidString) / \(characteristic.uuid.uuidString) [\(properties)]")

            if isKnownSPP || (canWrite && canNotify) {
                sppCharacteristic = characteristic
                if canNotify {
                    peripheral.setNotifyValue(true, for: characteristic)
                }

                isConnected = true
                pendingConnection = false
                errorMessage = nil

                let statusMsg = SPPMessage(id: MsgId.managerInfo.rawValue, payload: Data())
                sendMessage(statusMsg)
                return
            }
        }

        if sppCharacteristic == nil {
            errorMessage = "Connected, but no writable Buds control characteristic was found"
        }
    }

    func diagnosticsText() -> String {
        if bluetoothDiagnostics.isEmpty {
            return "No BLE GATT services have been reported yet."
        }
        return bluetoothDiagnostics.joined(separator: "\n")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value else { return }
        decodeMessage(data)
    }
}
