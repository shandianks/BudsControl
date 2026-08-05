# BudsControl

iOS app to control Samsung Galaxy Buds2 via reverse-engineered SPP protocol.

## Features

- **Bluetooth Connection**: Scan and connect to Galaxy Buds2
- **Battery Status**: Real-time battery levels for left, right earbuds and case
- **Equalizer**: 6 preset modes (Normal, Bass Boost, Soft, Dynamic, Clear, Treble Boost)
- **Noise Control**: Toggle between Off, Ambient Sound, and ANC (model dependent)
- **Ambient Sound**: Adjust ambient sound volume
- **Touchpad Lock**: Lock/unlock touchpad controls
- **Gaming Mode**: Low latency mode for gaming
- **Find My Buds**: Make earbuds beep to locate them
- **Device Info**: Firmware version, serial number, device color

## Protocol

Based on reverse engineering of Samsung Galaxy Buds2 SPP (Serial Port Profile) protocol, referencing [GalaxyBudsClient](https://github.com/timschneeb/GalaxyBudsClient) by timschneeb.

### SPP Message Structure

```
[SOM: 1B] [Header: 2B] [MsgID: 1B] [Payload: N B] [CRC16: 2B] [EOM: 1B]
```

- SOM: 0xFD
- EOM: 0xDD
- Header: 11-bit size + fragment flag + response flag
- CRC16-CCITT over [MsgID] + [Payload]

## Requirements

- iOS 16.0+
- Xcode 15+
- Samsung Galaxy Buds2 (or compatible models)

## Build

This project uses [xcodegen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project.

```bash
brew install xcodegen
xcodegen generate
xcodebuild -project BudsControl.xcodeproj -scheme BudsControl -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Note

This is an unofficial app based on reverse-engineered protocol. iOS Bluetooth permissions are stricter than Android, so some features may have limitations compared to the official Samsung Wearable app.

Standard Buds2 has limited ANC support (Buds2 Pro has full ANC).
