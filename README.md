# BudsControl - Galaxy Buds2 Manager for iOS

An unofficial iOS app to control Samsung Galaxy Buds2 (and potentially other Galaxy Buds models) using the reverse-engineered Bluetooth SPP protocol.

## Features

- **Real-time Battery Monitoring**: View battery levels for left, right, and case
- **Equalizer Control**: Switch between 6 EQ presets (Normal, Bass Boost, Soft, Dynamic, Clear, Treble Boost)
- **Ambient Sound Control**: Toggle ambient sound and adjust volume levels
- **Noise Control**: Switch between Off, Ambient, and ANC modes (device dependent)
- **Touchpad Settings**: Lock/unlock touchpad and customize gestures
- **Gaming Mode**: Enable low latency mode for gaming
- **Find My Buds**: Make your earbuds play a sound to locate them
- **Device Information**: View firmware version, serial number, and other details

## Supported Devices

- Galaxy Buds2 (primary target)
- Galaxy Buds2 Pro (partial support)
- Galaxy Buds+ (partial support)
- Other Galaxy Buds models may work with limited functionality

## Technical Details

### Protocol

This app uses the Samsung RFComm/SPP protocol documented in the [GalaxyBudsClient](https://github.com/timschneeb/GalaxyBudsClient) project by timschneeb.

#### Packet Structure

```
+----------+--------+--------+---------+--------+----------+
| Preamble | Header | Msg ID | Payload | CRC16  | Postamble|
|  1 byte  | 2 bytes| 1 byte |  N bytes| 2 bytes|  1 byte  |
+----------+--------+--------+---------+--------+----------+
```

- **Preamble**: `0xFD`
- **Header**: Encoded message type and size information
- **Msg ID**: Message identifier
- **Payload**: Message-specific data
- **CRC16**: CRC16-CCITT checksum
- **Postamble**: `0xDD`

### Architecture

```
BudsControl/
├── BudsControlApp.swift          # App entry point
├── ContentView.swift             # Main UI with navigation
├── BluetoothManager.swift        # Core Bluetooth management
├── SPPProtocol.swift             # Protocol definitions
├── CRC16.swift                   # CRC16-CCITT implementation
├── MessageEncoder.swift          # Message encoding
├── MessageDecoder.swift          # Message decoding
├── DeviceModels.swift            # Device specifications
├── Views/
│   ├── BatteryView.swift         # Battery status display
│   ├── EqualizerView.swift       # EQ settings
│   ├── NoiseControlView.swift    # Noise control settings
│   ├── AmbientSoundView.swift    # Ambient sound settings
│   ├── TouchpadView.swift        # Touchpad configuration
│   ├── FindMyBudsView.swift      # Find my buds feature
│   ├── SettingsView.swift        # Device settings
│   └── BudsStatusView.swift      # Status overview
└── Assets.xcassets/              # App icons and assets
```

## Requirements

- iOS 16.0+
- Xcode 14.0+
- Swift 5.0+
- Galaxy Buds2 (or compatible device)

## Building

1. Open `BudsControl.xcodeproj` in Xcode
2. Select your target device (iPhone with iOS 16.0+)
3. Build and run (⌘+R)

## Usage

1. **Pair your Buds**: Make sure your Galaxy Buds2 are paired with your iPhone via Bluetooth
2. **Open the app**: Launch BudsControl
3. **Connect**: Tap "Scan for Buds" and select your device
4. **Control**: Use the various screens to control your Buds settings

## Implementation Status

### Phase 1: Core Protocol ✅
- [x] SPP packet encoding/decoding
- [x] CRC16-CCITT implementation
- [x] Message ID definitions
- [x] Basic status parsing

### Phase 2: Bluetooth Connectivity ✅
- [x] CoreBluetooth integration
- [x] Device scanning
- [x] Connection management
- [x] Data transmission

### Phase 3: Basic Features ✅
- [x] Battery status display
- [x] Equalizer control
- [x] Ambient sound toggle
- [x] Touchpad lock

### Phase 4: Advanced Features ✅
- [x] Noise control modes
- [x] Gaming mode
- [x] Find my buds
- [x] Device information

### Phase 5: Polish (In Progress)
- [ ] Error handling improvements
- [ ] Background operation
- [ ] Widget support
- [ ] Siri shortcuts

## Known Limitations

- iOS Bluetooth restrictions may limit some functionality compared to Android
- Some advanced features may require Samsung-specific APIs not available on iOS
- ANC control is limited on standard Buds2 (Buds2 Pro has full ANC support)

## Credits

- Protocol documentation: [GalaxyBudsClient](https://github.com/timschneeb/GalaxyBudsClient) by timschneeb
- Inspired by the unofficial Galaxy Buds Manager for desktop platforms

## License

This project is for educational purposes. Samsung and Galaxy Buds are trademarks of Samsung Electronics Co., Ltd.
