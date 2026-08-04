import SwiftUI

struct BudsStatusView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Connection Status
                ConnectionStatusCard()
                
                // Battery Status
                BatteryView()
                
                // Quick Settings
                QuickSettingsGrid()
                
                // Device Info
                DeviceInfoCard()
            }
            .padding(.vertical)
        }
    }
}

struct ConnectionStatusCard: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        HStack {
            Image(systemName: bluetoothManager.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(bluetoothManager.isConnected ? .green : .red)
            
            VStack(alignment: .leading) {
                Text(bluetoothManager.isConnected ? "Connected" : "Disconnected")
                    .font(.headline)
                Text(bluetoothManager.isConnected ? "Galaxy Buds2" : "Tap to connect")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct QuickSettingsGrid: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Quick Settings")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                QuickSettingButton(
                    icon: "ear",
                    title: "Ambient",
                    isOn: bluetoothManager.isAmbientSoundOn
                ) {
                    bluetoothManager.setAmbientSound(enabled: !bluetoothManager.isAmbientSoundOn)
                }
                
                QuickSettingButton(
                    icon: "hand.tap",
                    title: "Touchpad",
                    isOn: !bluetoothManager.isTouchpadLocked
                ) {
                    bluetoothManager.setTouchpadLock(!bluetoothManager.isTouchpadLocked)
                }
                
                QuickSettingButton(
                    icon: "gamecontroller",
                    title: "Gaming",
                    isOn: bluetoothManager.isGamingModeOn
                ) {
                    bluetoothManager.setGamingMode(!bluetoothManager.isGamingModeOn)
                }
                
                QuickSettingButton(
                    icon: "waveform",
                    title: "EQ",
                    isOn: bluetoothManager.currentEQPreset != .normal
                ) {
                    // Cycle through EQ presets
                    let presets: [EQPreset] = [.normal, .bassBoost, .soft, .dynamic, .clear, .trebleBoost]
                    if let currentIndex = presets.firstIndex(of: bluetoothManager.currentEQPreset) {
                        let nextIndex = (currentIndex + 1) % presets.count
                        bluetoothManager.setEqualizer(preset: presets[nextIndex])
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct QuickSettingButton: View {
    let icon: String
    let title: String
    let isOn: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isOn ? .blue : .secondary)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Circle()
                    .fill(isOn ? Color.blue : Color.clear)
                    .frame(width: 8, height: 8)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(15)
        }
    }
}

struct BudsStatusView_Previews: PreviewProvider {
    static var previews: some View {
        BudsStatusView()
            .environmentObject(BluetoothManager())
    }
}
