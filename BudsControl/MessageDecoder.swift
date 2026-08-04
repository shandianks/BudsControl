import Foundation

// MARK: - Status Update Structure
struct StatusUpdate {
    let revision: Int
    let batteryL: Int
    let batteryR: Int
    let isCoupled: Bool
    let mainConnection: DeviceSide
    let placementL: PlacementState
    let placementR: PlacementState
    let batteryCase: Int
    let isLeftCharging: Bool
    let isRightCharging: Bool
    let isCaseCharging: Bool
}

// MARK: - Extended Status Update Structure
struct ExtendedStatusUpdate {
    let revision: Int
    let batteryL: Int
    let batteryR: Int
    let isCoupled: Bool
    let mainConnection: DeviceSide
    let placementL: PlacementState
    let placementR: PlacementState
    let batteryCase: Int
    let isLeftCharging: Bool
    let isRightCharging: Bool
    let isCaseCharging: Bool
    let ambientSoundEnabled: Bool
    let ambientSoundType: Int
    let adjustSoundSync: Int
    let equalizerMode: Int
    let touchLock: Bool
    let touchOptions: Int
    let deviceColor: Int
    let sideToneEnable: Bool
    let extraHighAmbientEnable: Bool
    let ambientVolume: Int
}

// MARK: - Message Decoder
struct MessageDecoder {
    
    // MARK: - Status Update (0x60)
    static func decodeStatusUpdate(_ message: SPPMessage) -> StatusUpdate? {
        guard message.payload.count >= 7 else { return nil }
        
        let revision = Int(message.payload[0])
        let batteryL = Int(message.payload[1])
        let batteryR = Int(message.payload[2])
        let isCoupled = message.payload[3] != 0
        let mainConnection: DeviceSide = message.payload[4] == 1 ? .left : .right
        
        // Placement status: MSB = Left, LSB = Right
        let placementByte = message.payload[5]
        let placementL = decodePlacementState(Int((placementByte & 0xF0) >> 4))
        let placementR = decodePlacementState(Int(placementByte & 0x0F))
        
        let batteryCase = Int(message.payload[6])
        
        var isLeftCharging = false
        var isRightCharging = false
        var isCaseCharging = false
        
        // Charging state (Buds2 and later)
        if message.payload.count >= 8 {
            let chargingStatus = message.payload[7]
            isLeftCharging = ((chargingStatus >> 4) & 0x01) == 1
            isRightCharging = ((chargingStatus >> 2) & 0x01) == 1
            isCaseCharging = (chargingStatus & 0x01) == 1
        }
        
        return StatusUpdate(
            revision: revision,
            batteryL: batteryL,
            batteryR: batteryR,
            isCoupled: isCoupled,
            mainConnection: mainConnection,
            placementL: placementL,
            placementR: placementR,
            batteryCase: batteryCase,
            isLeftCharging: isLeftCharging,
            isRightCharging: isRightCharging,
            isCaseCharging: isCaseCharging
        )
    }
    
    // MARK: - Extended Status Update (0x61)
    static func decodeExtendedStatusUpdate(_ message: SPPMessage) -> ExtendedStatusUpdate? {
        guard message.payload.count >= 17 else { return nil }
        
        let revision = Int(message.payload[0])
        let batteryL = Int(message.payload[1])
        let batteryR = Int(message.payload[2])
        let isCoupled = message.payload[3] != 0
        let mainConnection: DeviceSide = message.payload[4] == 1 ? .left : .right
        
        let placementByte = message.payload[5]
        let placementL = decodePlacementState(Int((placementByte & 0xF0) >> 4))
        let placementR = decodePlacementState(Int(placementByte & 0x0F))
        
        let batteryCase = Int(message.payload[6])
        
        var isLeftCharging = false
        var isRightCharging = false
        var isCaseCharging = false
        
        if message.payload.count >= 8 {
            let chargingStatus = message.payload[7]
            isLeftCharging = ((chargingStatus >> 4) & 0x01) == 1
            isRightCharging = ((chargingStatus >> 2) & 0x01) == 1
            isCaseCharging = (chargingStatus & 0x01) == 1
        }
        
        let ambientSoundEnabled = message.payload[8] != 0
        let ambientSoundType = Int(message.payload[9])
        let adjustSoundSync = Int(message.payload[10])
        let equalizerMode = Int(message.payload[11])
        let touchLock = message.payload[12] != 0
        let touchOptions = Int(message.payload[13])
        let deviceColor = Int(message.payload[14])
        let sideToneEnable = message.payload[15] != 0
        let extraHighAmbientEnable = message.payload[16] != 0
        let ambientVolume = message.payload.count >= 18 ? Int(message.payload[17]) : 0
        
        return ExtendedStatusUpdate(
            revision: revision,
            batteryL: batteryL,
            batteryR: batteryR,
            isCoupled: isCoupled,
            mainConnection: mainConnection,
            placementL: placementL,
            placementR: placementR,
            batteryCase: batteryCase,
            isLeftCharging: isLeftCharging,
            isRightCharging: isRightCharging,
            isCaseCharging: isCaseCharging,
            ambientSoundEnabled: ambientSoundEnabled,
            ambientSoundType: ambientSoundType,
            adjustSoundSync: adjustSoundSync,
            equalizerMode: equalizerMode,
            touchLock: touchLock,
            touchOptions: touchOptions,
            deviceColor: deviceColor,
            sideToneEnable: sideToneEnable,
            extraHighAmbientEnable: extraHighAmbientEnable,
            ambientVolume: ambientVolume
        )
    }
    
    // MARK: - Version Info (0x7D)
    static func decodeVersionInfo(_ message: SPPMessage) -> String? {
        guard !message.payload.isEmpty else { return nil }
        
        // Version info is typically a string or structured data
        if let versionString = String(bytes: message.payload, encoding: .utf8) {
            return versionString.trimmingCharacters(in: .controlCharacters)
        }
        
        // Fallback: return as hex string
        return message.payload.map { String(format: "%02X", $0) }.joined()
    }
    
    // MARK: - Serial Number (0x72)
    static func decodeSerialNumber(_ message: SPPMessage) -> String? {
        guard !message.payload.isEmpty else { return nil }
        
        if let serialString = String(bytes: message.payload, encoding: .utf8) {
            return serialString.trimmingCharacters(in: .controlCharacters)
        }
        
        return message.payload.map { String(format: "%02X", $0) }.joined()
    }
    
    // MARK: - Debug Build Info (0x75)
    static func decodeBuildInfo(_ message: SPPMessage) -> String? {
        guard !message.payload.isEmpty else { return nil }
        
        if let buildString = String(bytes: message.payload, encoding: .utf8) {
            return buildString.trimmingCharacters(in: .controlCharacters)
        }
        
        return nil
    }
    
    // MARK: - Debug Get All Data (0x74)
    static func decodeAllData(_ message: SPPMessage) -> [String: Any]? {
        guard message.payload.count >= 4 else { return nil }
        
        var result: [String: Any] = [:]
        
        // Parse version and sensor data
        // This is device-specific and may vary
        if message.payload.count >= 8 {
            result["version"] = Int(message.payload[0])
            result["sensor1"] = Int(message.payload[1])
            result["sensor2"] = Int(message.payload[2])
            result["sensor3"] = Int(message.payload[3])
        }
        
        return result
    }
    
    // MARK: - Ambient Mode Update (0x7E)
    static func decodeAmbientModeUpdate(_ message: SPPMessage) -> Bool? {
        guard message.payload.count >= 1 else { return nil }
        return message.payload[0] != 0
    }
    
    // MARK: - Ambient Voice Focus (0x7F)
    static func decodeAmbientVoiceFocus(_ message: SPPMessage) -> Bool? {
        guard message.payload.count >= 1 else { return nil }
        return message.payload[0] != 0
    }
    
    // MARK: - Ambient Wearing Update (0x80)
    static func decodeAmbientWearingUpdate(_ message: SPPMessage) -> (left: Bool, right: Bool)? {
        guard message.payload.count >= 1 else { return nil }
        
        let wearingByte = message.payload[0]
        let leftWearing = (wearingByte & 0x01) != 0
        let rightWearing = (wearingByte & 0x02) != 0
        
        return (left: leftWearing, right: rightWearing)
    }
    
    // MARK: - Noise Reduction (0x81)
    static func decodeNoiseReduction(_ message: SPPMessage) -> Int? {
        guard message.payload.count >= 1 else { return nil }
        return Int(message.payload[0])
    }
    
    // MARK: - Noise Control (0x93)
    static func decodeNoiseControl(_ message: SPPMessage) -> NoiseControlMode? {
        guard message.payload.count >= 1 else { return nil }
        
        switch message.payload[0] {
        case 0x00: return .off
        case 0x01: return .ambient
        case 0x02: return .anc
        default: return nil
        }
    }
    
    // MARK: - Charging State (0x95)
    static func decodeChargingState(_ message: SPPMessage) -> (left: Bool, right: Bool, case: Bool)? {
        guard message.payload.count >= 1 else { return nil }
        
        let chargingByte = message.payload[0]
        let leftCharging = ((chargingByte >> 4) & 0x01) != 0
        let rightCharging = ((chargingByte >> 2) & 0x01) != 0
        let caseCharging = (chargingByte & 0x01) != 0
        
        return (left: leftCharging, right: rightCharging, case: caseCharging)
    }
    
    // MARK: - Device Color (0x91)
    static func decodeDeviceColor(_ message: SPPMessage) -> String? {
        guard message.payload.count >= 1 else { return nil }
        
        let colorByte = message.payload[0]
        let leftColor = Int((colorByte & 0xF0) >> 4)
        let rightColor = Int(colorByte & 0x0F)
        
        return "Left: \(leftColor), Right: \(rightColor)"
    }
    
    // MARK: - Acknowledgement (0x7C)
    static func decodeAcknowledgement(_ message: SPPMessage) -> Bool {
        return true
    }
    
    // MARK: - Battery Type (0x78)
    static func decodeBatteryType(_ message: SPPMessage) -> String? {
        guard !message.payload.isEmpty else { return nil }
        
        if let typeString = String(bytes: message.payload, encoding: .utf8) {
            return typeString.trimmingCharacters(in: .controlCharacters)
        }
        
        return nil
    }
    
    // MARK: - Touchpad Option (0x84)
    static func decodeTouchpadOption(_ message: SPPMessage) -> (left: TouchpadAction, right: TouchpadAction)? {
        guard message.payload.count >= 2 else { return nil }
        
        let leftAction = TouchpadAction(rawValue: message.payload[0]) ?? .unused
        let rightAction = TouchpadAction(rawValue: message.payload[1]) ?? .unused
        
        return (left: leftAction, right: rightAction)
    }
    
    // MARK: - ANC Level (0x87)
    static func decodeANCLevel(_ message: SPPMessage) -> Int? {
        guard message.payload.count >= 1 else { return nil }
        return Int(message.payload[0])
    }
    
    // MARK: - Usage Report (0x8E)
    static func decodeUsageReport(_ message: SPPMessage) -> [String: Any]? {
        guard message.payload.count >= 4 else { return nil }
        
        var result: [String: Any] = [:]
        
        // Parse usage data
        let usageTime = UInt32(message.payload[0]) |
                       (UInt32(message.payload[1]) << 8) |
                       (UInt32(message.payload[2]) << 16) |
                       (UInt32(message.payload[3]) << 24)
        
        result["usageTime"] = usageTime
        
        return result
    }
    
    // MARK: - Helper Methods
    private static func decodePlacementState(_ value: Int) -> PlacementState {
        switch value {
        case 0: return .unknown
        case 1: return .wearing
        case 2: return .idle
        case 3: return .inCase
        case 4: return .charging
        default: return .unknown
        }
    }
}

// MARK: - Legacy Status Update (for original Galaxy Buds)
struct LegacyStatusUpdate {
    let earType: Int
    let batteryL: Int
    let batteryR: Int
    let isCoupled: Bool
    let mainConnection: DeviceSide
    let wearState: LegacyWearState
}

enum LegacyWearState {
    case none
    case left
    case right
    case both
    
    init(rawValue: UInt8) {
        switch rawValue {
        case 1: self = .left
        case 2: self = .right
        case 3: self = .both
        default: self = .none
        }
    }
}

// MARK: - Legacy Decoder
struct LegacyMessageDecoder {
    static func decodeStatusUpdate(_ message: SPPMessage) -> LegacyStatusUpdate? {
        guard message.payload.count >= 6 else { return nil }
        
        let earType = Int(message.payload[0])
        let batteryL = Int(message.payload[1])
        let batteryR = Int(message.payload[2])
        let isCoupled = message.payload[3] != 0
        let mainConnection: DeviceSide = message.payload[4] == 1 ? .left : .right
        let wearState = LegacyWearState(rawValue: message.payload[5])
        
        return LegacyStatusUpdate(
            earType: earType,
            batteryL: batteryL,
            batteryR: batteryR,
            isCoupled: isCoupled,
            mainConnection: mainConnection,
            wearState: wearState
        )
    }
}
