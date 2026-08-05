import SwiftUI

struct ContentView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        NavigationView {
            Group {
                if bluetoothManager.isConnected {
                    MainControlView()
                } else {
                    ConnectionView()
                }
            }
            .navigationTitle("BudsControl")
        }
    }
}

struct ConnectionView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "earbuds")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("BudsControl")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Galaxy Buds2 Manager")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if bluetoothManager.isScanning {
                VStack(spacing: 15) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Searching for Galaxy Buds2...")
                        .foregroundColor(.secondary)
                }
            } else if let error = bluetoothManager.errorMessage {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Button(action: {
                bluetoothManager.startScanning()
            }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text(bluetoothManager.isScanning ? "Scanning..." : "Scan for Buds")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(bluetoothManager.isScanning ? Color.gray : Color.blue)
                .cornerRadius(15)
            }
            .disabled(bluetoothManager.isScanning)
            .padding(.horizontal, 40)
            
            if !bluetoothManager.discoveredDevices.isEmpty {
                List(bluetoothManager.discoveredDevices) { device in
                    Button(action: {
                        bluetoothManager.connect(to: device)
                    }) {
                        HStack {
                            Image(systemName: "earbuds")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text(device.name)
                                    .font(.headline)
                                Text(device.uuid.uuidString.prefix(8) + "...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
    }
}

struct MainControlView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Battery Status
                BatteryStatusView()
                
                Divider()
                
                // Equalizer
                EqualizerView()
                
                Divider()
                
                // Noise Control
                if bluetoothManager.currentModel.supportsNoiseControl {
                    NoiseControlView()
                    Divider()
                }
                
                // Ambient Sound
                if bluetoothManager.currentModel.supportsAmbientSound {
                    AmbientSoundView()
                    Divider()
                }
                
                // Touchpad
                TouchpadView()
                
                Divider()
                
                // Gaming Mode
                if bluetoothManager.currentModel.supportsGamingMode {
                    GamingModeView()
                    Divider()
                }
                
                // Find My Buds
                FindMyBudsView()
                
                Divider()
                
                // Device Info
                DeviceInfoView()
                
                // Disconnect Button
                Button(action: {
                    bluetoothManager.disconnect()
                }) {
                    Text("Disconnect")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(15)
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
}

struct BatteryStatusView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Battery Status")
                .font(.headline)
            
            HStack(spacing: 20) {
                BatteryItemView(
                    label: "Left",
                    percentage: bluetoothManager.batteryLeft,
                    isCharging: bluetoothManager.isLeftCharging
                )
                
                BatteryItemView(
                    label: "Right",
                    percentage: bluetoothManager.batteryRight,
                    isCharging: bluetoothManager.isRightCharging
                )
                
                if bluetoothManager.currentModel.supportsCaseBattery {
                    BatteryItemView(
                        label: "Case",
                        percentage: bluetoothManager.batteryCase,
                        isCharging: bluetoothManager.isCaseCharging
                    )
                }
            }
        }
    }
}

struct BatteryItemView: View {
    let label: String
    let percentage: Int
    let isCharging: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: CGFloat(percentage) / 100)
                    .stroke(batteryColor, lineWidth: 8)
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(percentage)%")
                        .font(.caption)
                        .fontWeight(.bold)
                    
                    if isCharging {
                        Image(systemName: "bolt.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    var batteryColor: Color {
        if percentage > 60 {
            return .green
        } else if percentage > 20 {
            return .yellow
        } else {
            return .red
        }
    }
}

struct EqualizerView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Equalizer")
                .font(.headline)
            
            ForEach(EQPreset.allCases, id: \.self) { preset in
                Button(action: {
                    bluetoothManager.setEqualizer(preset)
                }) {
                    HStack {
                        Text(preset.rawValue)
                            .foregroundColor(.primary)
                        Spacer()
                        if bluetoothManager.currentEQPreset == preset {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(
                        bluetoothManager.currentEQPreset == preset
                        ? Color.blue.opacity(0.1)
                        : Color.gray.opacity(0.1)
                    )
                    .cornerRadius(10)
                }
            }
        }
    }
}

struct NoiseControlView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Noise Control")
                .font(.headline)
            
            ForEach(NoiseControlMode.allCases, id: \.self) { mode in
                Button(action: {
                    bluetoothManager.setNoiseControl(mode)
                }) {
                    HStack {
                        Image(systemName: modeIcon(mode))
                            .foregroundColor(.blue)
                        Text(mode.rawValue)
                            .foregroundColor(.primary)
                        Spacer()
                        if bluetoothManager.noiseControlMode == mode {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(
                        bluetoothManager.noiseControlMode == mode
                        ? Color.blue.opacity(0.1)
                        : Color.gray.opacity(0.1)
                    )
                    .cornerRadius(10)
                }
            }
        }
    }
    
    func modeIcon(_ mode: NoiseControlMode) -> String {
        switch mode {
        case .off: return "speaker"
        case .ambient: return "ear"
        case .anc: return "minus.circle"
        }
    }
}

struct AmbientSoundView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Ambient Sound")
                .font(.headline)
            
            Toggle("Enable Ambient Sound", isOn: $bluetoothManager.isAmbientSoundOn)
                .onChange(of: bluetoothManager.isAmbientSoundOn) { newValue in
                    bluetoothManager.setAmbientMode(newValue)
                }
            
            if bluetoothManager.isAmbientSoundOn {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Volume: \(bluetoothManager.ambientVolume)")
                        .font(.subheadline)
                    
                    Slider(
                        value: Binding(
                            get: { Double(bluetoothManager.ambientVolume) },
                            set: { bluetoothManager.setAmbientVolume(Int($0)) }
                        ),
                        in: 0...Double(bluetoothManager.currentModel.maximumAmbientVolume),
                        step: 1
                    )
                }
            }
        }
    }
}

struct TouchpadView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Touchpad")
                .font(.headline)
            
            Toggle("Lock Touchpad", isOn: $bluetoothManager.isTouchpadLocked)
                .onChange(of: bluetoothManager.isTouchpadLocked) { newValue in
                    bluetoothManager.setTouchpadLock(newValue)
                }
        }
    }
}

struct GamingModeView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Gaming Mode")
                .font(.headline)
            
            Toggle("Low Latency Mode", isOn: $bluetoothManager.isGamingModeOn)
                .onChange(of: bluetoothManager.isGamingModeOn) { newValue in
                    bluetoothManager.setGamingMode(newValue)
                }
        }
    }
}

struct FindMyBudsView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var isFinding = false
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Find My Buds")
                .font(.headline)
            
            Button(action: {
                if isFinding {
                    bluetoothManager.stopFindMyEarbuds()
                    isFinding = false
                } else {
                    bluetoothManager.startFindMyEarbuds()
                    isFinding = true
                    // Auto stop after 30 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                        if isFinding {
                            bluetoothManager.stopFindMyEarbuds()
                            isFinding = false
                        }
                    }
                }
            }) {
                HStack {
                    Image(systemName: isFinding ? "speaker.wave.3.fill" : "speaker.wave.2")
                    Text(isFinding ? "Stop Beeping" : "Find My Buds")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFinding ? Color.orange : Color.blue)
                .cornerRadius(15)
            }
        }
    }
}

struct DeviceInfoView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Device Info")
                .font(.headline)
            
            InfoRow(label: "Model", value: bluetoothManager.currentModel.rawValue)
            InfoRow(label: "Firmware", value: bluetoothManager.firmwareVersion)
            InfoRow(label: "Serial", value: bluetoothManager.serialNumber)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(BluetoothManager())
    }
}
