import Foundation

// MARK: - Device Models and Feature Support

struct BudsDeviceModel {
    let model: DeviceModels
    let deviceBaseName: String
    let serviceUUID: String
    let supports: [DeviceFeature]
    let maximumAmbientVolume: Int
    let startOfMessage: UInt8
    let endOfMessage: UInt8
    
    static let buds2 = BudsDeviceModel(
        model: .buds2,
        deviceBaseName: "Buds2",
        serviceUUID: "2e889123-5b00-4e0a-8fd1-5c55e0ce711c",
        supports: [
            .seamlessConnection,
            .stereoPan,
            .firmwareUpdates,
            .noiseControl,
            .ambientSound,
            .anc,
            .gamingMode,
            .caseBattery,
            .fragmentedMessages,
            .bixbyWakeup,
            .gearFitTest,
            .doubleTapVolume,
            .advancedTouchLock,
            .noiseControlsWithOneEarbud,
            .ambientCustomize,
            .ambientSidetone,
            .fmgRingWhileWearing,
            .debugSku,
            .callPathControl,
            .chargingState,
            .noiseControlModeDualSide,
            .pairingMode,
            .ambientSoundVolume,
            .deviceColor,
            .rename,
            .spatialSensor,
            .smartThingsFind,
            .usageReport
        ],
        maximumAmbientVolume: 2,
        startOfMessage: 0xFD,
        endOfMessage: 0xDD
    )
}

enum DeviceFeature {
    case seamlessConnection
    case stereoPan
    case firmwareUpdates
    case noiseControl
    case ambientSound
    case anc
    case gamingMode
    case caseBattery
    case fragmentedMessages
    case bixbyWakeup
    case gearFitTest
    case doubleTapVolume
    case advancedTouchLock
    case advancedTouchLockForCalls
    case noiseControlsWithOneEarbud
    case ambientCustomize
    case ambientSidetone
    case fmgRingWhileWearing
    case debugSku
    case callPathControl
    case chargingState
    case noiseControlModeDualSide
    case pairingMode
    case ambientSoundVolume
    case deviceColor
    case rename
    case spatialSensor
    case smartThingsFind
    case usageReport
}

// MARK: - UUIDs
struct BudsUUIDs {
    // SPP Service UUIDs
    static let sppNew = UUID(uuidString: "2e889123-5b00-4e0a-8fd1-5c55e0ce711c")!
    static let sppLegacy = UUID(uuidString: "00001101-0000-1000-8000-00805F9B34FB")!
    
    // Characteristic UUIDs
    static let sppCharacteristic = UUID(uuidString: "2e889124-5b00-4e0a-8fd1-5c55e0ce711c")!
    
    // Other service UUIDs
    static let handsfree = UUID(uuidString: "0000111E-0000-1000-8000-00805F9B34FB")!
    static let leAudio = UUID(uuidString: "0000184E-0000-1000-8000-00805F9B34FB")!
}

// MARK: - Device IDs for identification
enum DeviceIds: Int32 {
    case buds = 0x01
    case budsPlus = 0x02
    case budsLive = 0x03
    case budsPro = 0x04
    case buds2 = 0x05
    case buds2Pro = 0x06
    case budsFE = 0x07
    case buds3 = 0x08
    case buds3Pro = 0x09
    case unknown = 0x00
    
    func getAssociatedModel() -> DeviceModels? {
        switch self {
        case .buds: return .buds
        case .budsPlus: return .budsPlus
        case .budsLive: return .budsLive
        case .budsPro: return .budsPro
        case .buds2: return .buds2
        case .buds2Pro: return .buds2Pro
        case .budsFE: return .budsFE
        case .buds3: return .buds3
        case .buds3Pro: return .buds3Pro
        case .unknown: return nil
        }
    }
}

// MARK: - Feature Rules
struct FeatureRule {
    let minimumRevision: Int
    
    init(_ minimumRevision: Int) {
        self.minimumRevision = minimumRevision
    }
    
    func isSupported(revision: Int) -> Bool {
        return revision >= minimumRevision
    }
}

// MARK: - Touch Map Types
protocol TouchMap {
    func getAction(for gesture: TouchGesture, side: DeviceSide) -> TouchpadAction
}

struct StandardTouchMap: TouchMap {
    func getAction(for gesture: TouchGesture, side: DeviceSide) -> TouchpadAction {
        switch gesture {
        case .singleTap:
            return .voiceAssistant
        case .doubleTap:
            return side == .left ? .volume : .ambientSound
        case .tripleTap:
            return .noiseControl
        case .touchAndHold:
            return .custom
        }
    }
}

enum TouchGesture {
    case singleTap
    case doubleTap
    case tripleTap
    case touchAndHold
}

// MARK: - Tray Item Types
enum TrayItemTypes {
    case toggleNoiseControl
    case toggleEqualizer
    case lockTouchpad
    case toggleAmbient
    case findMyBuds
}

// MARK: - Message Constants
struct MsgConstants {
    static let som: UInt8 = 0xFD
    static let eom: UInt8 = 0xDD
    static let smepSom: UInt8 = 0xFE
    static let smepEom: UInt8 = 0xEE
}
