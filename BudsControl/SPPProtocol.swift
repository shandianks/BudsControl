import Foundation

// MARK: - SPP Message Structure
struct SPPMessage {
    // Protocol Constants
    static let som: UInt8 = 0xFD
    static let eom: UInt8 = 0xDD
    static let smepSom: UInt8 = 0xFE
    static let smepEom: UInt8 = 0xEE
    
    var id: MsgIds
    var type: MsgTypes
    var payload: [UInt8]
    var isFragment: Bool = false
    
    var size: Int {
        return 1 + payload.count + 2 // MsgId + Payload + CRC
    }
    
    var totalPacketSize: Int {
        return 1 + 2 + 1 + payload.count + 2 + 1 // SOM + Header + MsgId + Payload + CRC + EOM
    }
    
    // MARK: - Encode
    func encode() -> Data {
        var data = Data()
        
        // Start of Message
        data.append(SPPMessage.som)
        
        // Header (2 bytes)
        var header = UInt16(size)
        if isFragment {
            header |= 0x2000
        }
        if type == .response {
            header |= 0x1000
        }
        
        data.append(UInt8(header & 0xFF))
        data.append(UInt8((header >> 8) & 0xFF))
        
        // Message ID
        data.append(id.rawValue)
        
        // Payload
        data.append(contentsOf: payload)
        
        // CRC16-CCITT
        let crcData = [id.rawValue] + payload
        let crc = CRC16.ccitt(crcData)
        data.append(UInt8(crc & 0xFF))
        data.append(UInt8((crc >> 8) & 0xFF))
        
        // End of Message
        data.append(SPPMessage.eom)
        
        return data
    }
    
    // MARK: - Decode
    static func decode(from data: Data) throws -> (message: SPPMessage, consumed: Int) {
        guard data.count >= 6 else {
            throw SPPError.incompletePacket
        }
        
        var index = 0
        
        // Find SOM
        while index < data.count && data[index] != som {
            index += 1
        }
        
        guard index < data.count else {
            throw SPPError.noStartOfMessage
        }
        
        // Check minimum size
        guard data.count - index >= 6 else {
            throw SPPError.incompletePacket
        }
        
        index += 1 // Skip SOM
        
        // Read header
        let headerLow = data[index]
        let headerHigh = data[index + 1]
        let header = UInt16(headerLow) | (UInt16(headerHigh) << 8)
        
        let isFragment = (header & 0x2000) != 0
        let msgType: MsgTypes = (header & 0x1000) != 0 ? .response : .request
        let size = Int(header & 0x07FF)
        
        index += 2
        
        // Read Message ID
        let msgId = data[index]
        index += 1
        
        // Calculate payload size
        let payloadSize = size - 3 // Subtract MsgId (1) + CRC (2)
        
        guard payloadSize >= 0 else {
            throw SPPError.invalidSize
        }
        
        guard data.count - index >= payloadSize + 3 else {
            throw SPPError.incompletePacket
        }
        
        // Read payload
        let payload = Array(data[index..<index + payloadSize])
        index += payloadSize
        
        // Read CRC
        let crcLow = data[index]
        let crcHigh = data[index + 1]
        let receivedCrc = UInt16(crcLow) | (UInt16(crcHigh) << 8)
        index += 2
        
        // Verify CRC
        let crcData = [msgId] + payload
        let calculatedCrc = CRC16.ccitt(crcData)
        
        guard calculatedCrc == receivedCrc else {
            throw SPPError.invalidChecksum
        }
        
        // Verify EOM
        guard index < data.count && data[index] == eom else {
            throw SPPError.invalidEndOfMessage
        }
        index += 1
        
        guard let messageId = MsgIds(rawValue: msgId) else {
            throw SPPError.unknownMessageId
        }
        
        let message = SPPMessage(
            id: messageId,
            type: msgType,
            payload: payload,
            isFragment: isFragment
        )
        
        return (message, index)
    }
}

// MARK: - Message Types
enum MsgTypes {
    case request
    case response
}

// MARK: - Message IDs
enum MsgIds: UInt8 {
    case unknown0 = 0x00
    
    // Status
    case statusUpdated = 0x60
    case extendedStatusUpdated = 0x61
    
    // Settings
    case updateTime = 0x64
    case managerInfo = 0x65
    case equalizer = 0x66
    case lockTouchpad = 0x67
    case setAmbientMode = 0x68
    case ambientVolume = 0x69
    case muteEarbud = 0x6A
    case setTouchpadOption = 0x6B
    case mainChange = 0x6C
    
    // Features
    case voiceNotiStatus = 0x6D
    case notificationInfo = 0x6E
    case gameMode = 0x6F
    
    // Find My
    case findMyEarbudsStart = 0x70
    case findMyEarbudsStop = 0x71
    
    // Debug
    case debugSerialNumber = 0x72
    case reset = 0x73
    case debugGetAllData = 0x74
    case debugBuildInfo = 0x75
    case logSessionOpen = 0x76
    case logSessionClose = 0x77
    case batteryType = 0x78
    case debugSku = 0x79
    case debugPeRssi = 0x7A
    case selfTest = 0x7B
    
    // Acknowledgement
    case acknowledgement = 0x7C
    
    // Version
    case versionInfo = 0x7D
    
    // Additional Buds2 specific
    case ambientModeUpdate = 0x7E
    case ambientVoiceFocus = 0x7F
    case ambientWearingUpdate = 0x80
    case noiseReduction = 0x81
    case seamlessConnection = 0x82
    case spatialAudio = 0x83
    
    // Touchpad
    case touchpadOption = 0x84
    case touchpadOtherOption = 0x85
    
    // ANC
    case anc = 0x86
    case ancLevel = 0x87
    
    // Advanced features
    case bixbyWakeup = 0x88
    case voiceWakeUp = 0x89
    case extraHighAmbient = 0x8A
    case doubleTapVolume = 0x8B
    
    // Firmware
    case firmwareVersion = 0x8C
    case firmwareUpdate = 0x8D
    
    // Misc
    case usageReport = 0x8E
    case callPath = 0x8F
    case pairingMode = 0x90
    case deviceColor = 0x91
    case rename = 0x92
    
    // Buds2 specific
    case noiseControl = 0x93
    case noiseControlDual = 0x94
    case chargingState = 0x95
    case spatialSensor = 0x96
    case smartThingsFind = 0x97
}

// MARK: - SPP Errors
enum SPPError: Error {
    case incompletePacket
    case noStartOfMessage
    case invalidSize
    case invalidChecksum
    case invalidEndOfMessage
    case unknownMessageId
}

// MARK: - Device Models
enum DeviceModels: String {
    case buds = "Galaxy Buds"
    case budsPlus = "Galaxy Buds+"
    case budsLive = "Galaxy Buds Live"
    case budsPro = "Galaxy Buds Pro"
    case buds2 = "Galaxy Buds2"
    case buds2Pro = "Galaxy Buds2 Pro"
    case budsFE = "Galaxy Buds FE"
    case buds3 = "Galaxy Buds3"
    case buds3Pro = "Galaxy Buds3 Pro"
    case unknown = "Unknown"
    
    static func fromName(_ name: String) -> DeviceModels {
        if name.contains("Buds2 Pro") { return .buds2Pro }
        if name.contains("Buds2") { return .buds2 }
        if name.contains("Buds3 Pro") { return .buds3Pro }
        if name.contains("Buds3") { return .buds3 }
        if name.contains("Buds Pro") { return .budsPro }
        if name.contains("Buds Live") { return .budsLive }
        if name.contains("Buds FE") { return .budsFE }
        if name.contains("Buds+") { return .budsPlus }
        if name.contains("Buds") { return .buds }
        return .unknown
    }
}

// MARK: - Feature Support
struct FeatureSupport {
    static func supportsNoiseControl(model: DeviceModels) -> Bool {
        switch model {
        case .buds2, .buds2Pro, .budsPro, .buds3, .buds3Pro:
            return true
        default:
            return false
        }
    }
    
    static func supportsANC(model: DeviceModels) -> Bool {
        switch model {
        case .buds2Pro, .budsPro, .buds3Pro:
            return true
        default:
            return false
        }
    }
    
    static func supportsGamingMode(model: DeviceModels) -> Bool {
        switch model {
        case .buds2, .buds2Pro, .budsPro, .buds3, .buds3Pro:
            return true
        default:
            return false
        }
    }
    
    static func supportsTouchpadCustomization(model: DeviceModels) -> Bool {
        switch model {
        case .buds2, .buds2Pro, .budsPro, .buds3, .buds3Pro:
            return true
        default:
            return false
        }
    }
    
    static func supportsAmbientSound(model: DeviceModels) -> Bool {
        switch model {
        case .buds2, .buds2Pro, .budsPro, .budsLive, .buds3, .buds3Pro:
            return true
        default:
            return false
        }
    }
    
    static func supportsCaseBattery(model: DeviceModels) -> Bool {
        switch model {
        case .budsPlus, .buds2, .buds2Pro, .budsPro, .buds3, .buds3Pro, .budsFE:
            return true
        default:
            return false
        }
    }
    
    static func supportsChargingState(model: DeviceModels) -> Bool {
        switch model {
        case .buds2, .buds2Pro, .buds3, .buds3Pro:
            return true
        default:
            return false
        }
    }
}
