import Foundation

// MARK: - Message Encoder
struct MessageEncoder {
    
    // MARK: - Equalizer
    static func encodeEqualizer(preset: EQPreset) -> SPPMessage {
        return SPPMessage(
            id: .equalizer,
            type: .request,
            payload: [UInt8(preset.id)]
        )
    }
    
    // MARK: - Ambient Mode
    static func encodeAmbientMode(enabled: Bool) -> SPPMessage {
        return SPPMessage(
            id: .setAmbientMode,
            type: .request,
            payload: [enabled ? 0x01 : 0x00]
        )
    }
    
    // MARK: - Ambient Volume
    static func encodeAmbientVolume(volume: Int) -> SPPMessage {
        return SPPMessage(
            id: .ambientVolume,
            type: .request,
            payload: [UInt8(volume)]
        )
    }
    
    // MARK: - Touchpad Lock
    static func encodeTouchpadLock(locked: Bool) -> SPPMessage {
        return SPPMessage(
            id: .lockTouchpad,
            type: .request,
            payload: [locked ? 0x01 : 0x00]
        )
    }
    
    // MARK: - Touchpad Options
    static func encodeTouchpadOptions(left: TouchpadAction, right: TouchpadAction) -> SPPMessage {
        return SPPMessage(
            id: .setTouchpadOption,
            type: .request,
            payload: [left.rawValue, right.rawValue]
        )
    }
    
    // MARK: - Main Connection Change
    static func encodeMainChange(side: DeviceSide) -> SPPMessage {
        return SPPMessage(
            id: .mainChange,
            type: .request,
            payload: [side == .left ? 0x01 : 0x00]
        )
    }
    
    // MARK: - Gaming Mode
    static func encodeGamingMode(enabled: Bool) -> SPPMessage {
        var status: UInt8 = 0x00
        if enabled {
            status |= 0x10 // Flip fifth bit for game in foreground
        }
        status |= 0x01 // Screen is on
        
        return SPPMessage(
            id: .gameMode,
            type: .request,
            payload: [status]
        )
    }
    
    // MARK: - Update Time
    static func encodeUpdateTime() -> SPPMessage {
        let timestamp = UInt64(Date().timeIntervalSince1970 * 1000)
        let timezoneOffset = TimeZone.current.secondsFromGMT() * 1000
        
        var payload = [UInt8]()
        
        // Timestamp (8 bytes, little endian)
        payload.append(UInt8(timestamp & 0xFF))
        payload.append(UInt8((timestamp >> 8) & 0xFF))
        payload.append(UInt8((timestamp >> 16) & 0xFF))
        payload.append(UInt8((timestamp >> 24) & 0xFF))
        payload.append(UInt8((timestamp >> 32) & 0xFF))
        payload.append(UInt8((timestamp >> 40) & 0xFF))
        payload.append(UInt8((timestamp >> 48) & 0xFF))
        payload.append(UInt8((timestamp >> 56) & 0xFF))
        
        // Timezone offset (4 bytes, little endian)
        let offset = Int32(timezoneOffset)
        payload.append(UInt8(offset & 0xFF))
        payload.append(UInt8((offset >> 8) & 0xFF))
        payload.append(UInt8((offset >> 16) & 0xFF))
        payload.append(UInt8((offset >> 24) & 0xFF))
        
        return SPPMessage(
            id: .updateTime,
            type: .request,
            payload: payload
        )
    }
    
    // MARK: - Manager Info
    static func encodeManagerInfo() -> SPPMessage {
        return SPPMessage(
            id: .managerInfo,
            type: .request,
            payload: [
                0x01, // ClientType: Wearable App
                0x02, // IsSamsungDevice: Other manufacturer
                0x21  // AndroidSdk: API 33 (Android 13)
            ]
        )
    }
    
    // MARK: - Voice Notification
    static func encodeVoiceNotiStatus(enabled: Bool) -> SPPMessage {
        return SPPMessage(
            id: .voiceNotiStatus,
            type: .request,
            payload: [enabled ? 0x01 : 0x00]
        )
    }
    
    // MARK: - Notification Info
    static func encodeNotificationInfo(playSound: Bool) -> SPPMessage {
        return SPPMessage(
            id: .notificationInfo,
            type: .request,
            payload: [playSound ? 0x01 : 0x00]
        )
    }
    
    // MARK: - Mute Earbud
    static func encodeMuteEarbud(left: Bool, right: Bool) -> SPPMessage {
        return SPPMessage(
            id: .muteEarbud,
            type: .request,
            payload: [
                left ? 0x01 : 0x00,
                right ? 0x01 : 0x00
            ]
        )
    }
    
    // MARK: - Noise Control (Buds2 specific)
    static func encodeNoiseControl(mode: NoiseControlMode) -> SPPMessage {
        let modeValue: UInt8
        switch mode {
        case .off:
            modeValue = 0x00
        case .ambient:
            modeValue = 0x01
        case .anc:
            modeValue = 0x02
        }
        
        return SPPMessage(
            id: .noiseControl,
            type: .request,
            payload: [modeValue]
        )
    }
    
    // MARK: - ANC Level (Buds2 Pro specific)
    static func encodeANCLevel(level: Int) -> SPPMessage {
        return SPPMessage(
            id: .ancLevel,
            type: .request,
            payload: [UInt8(level)]
        )
    }
    
    // MARK: - Bixby Wakeup
    static func encodeBixbyWakeup(enabled: Bool) -> SPPMessage {
        return SPPMessage(
            id: .bixbyWakeup,
            type: .request,
            payload: [enabled ? 0x01 : 0x00]
        )
    }
    
    // MARK: - Double Tap Volume
    static func encodeDoubleTapVolume(enabled: Bool) -> SPPMessage {
        return SPPMessage(
            id: .doubleTapVolume,
            type: .request,
            payload: [enabled ? 0x01 : 0x00]
        )
    }
    
    // MARK: - Extra High Ambient
    static func encodeExtraHighAmbient(enabled: Bool) -> SPPMessage {
        return SPPMessage(
            id: .extraHighAmbient,
            type: .request,
            payload: [enabled ? 0x01 : 0x00]
        )
    }
    
    // MARK: - Seamless Connection
    static func encodeSeamlessConnection(enabled: Bool) -> SPPMessage {
        return SPPMessage(
            id: .seamlessConnection,
            type: .request,
            payload: [enabled ? 0x01 : 0x00]
        )
    }
    
    // MARK: - Spatial Audio
    static func encodeSpatialAudio(enabled: Bool) -> SPPMessage {
        return SPPMessage(
            id: .spatialAudio,
            type: .request,
            payload: [enabled ? 0x01 : 0x00]
        )
    }
    
    // MARK: - Pairing Mode
    static func encodePairingMode() -> SPPMessage {
        return SPPMessage(
            id: .pairingMode,
            type: .request,
            payload: []
        )
    }
    
    // MARK: - Rename Device
    static func encodeRename(name: String) -> SPPMessage {
        let nameData = Array(name.utf8)
        // Pad or truncate to maximum length (likely 20-30 bytes)
        let maxLength = 20
        var payload = Array(nameData.prefix(maxLength))
        while payload.count < maxLength {
            payload.append(0x00)
        }
        
        return SPPMessage(
            id: .rename,
            type: .request,
            payload: payload
        )
    }
    
    // MARK: - Reset Device
    static func encodeReset() -> SPPMessage {
        return SPPMessage(
            id: .reset,
            type: .request,
            payload: []
        )
    }
    
    // MARK: - Log Session
    static func encodeLogSession(open: Bool) -> SPPMessage {
        return SPPMessage(
            id: open ? .logSessionOpen : .logSessionClose,
            type: .request,
            payload: []
        )
    }
    
    // MARK: - Debug Commands
    static func encodeDebugSerialNumber() -> SPPMessage {
        return SPPMessage(
            id: .debugSerialNumber,
            type: .request,
            payload: []
        )
    }
    
    static func encodeDebugBuildInfo() -> SPPMessage {
        return SPPMessage(
            id: .debugBuildInfo,
            type: .request,
            payload: []
        )
    }
    
    static func encodeDebugGetAllData() -> SPPMessage {
        return SPPMessage(
            id: .debugGetAllData,
            type: .request,
            payload: []
        )
    }
    
    static func encodeSelfTest() -> SPPMessage {
        return SPPMessage(
            id: .selfTest,
            type: .request,
            payload: []
        )
    }
}

// MARK: - Touchpad Actions
enum TouchpadAction: UInt8 {
    case unused = 0
    case voiceAssistant = 1
    case volume = 2
    case ambientSound = 3
    case spotify = 4
    case noiseControl = 5
    case custom = 6
}
