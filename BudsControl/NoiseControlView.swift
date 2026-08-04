import SwiftUI

struct NoiseControlView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        List {
            Section(header: Text("Noise Control Mode")) {
                ForEach(NoiseControlMode.allCases, id: \.self) { mode in
                    Button(action: {
                        bluetoothManager.setNoiseControl(mode: mode)
                    }) {
                        HStack {
                            Image(systemName: modeIcon(mode))
                                .foregroundColor(modeColor(mode))
                            
                            VStack(alignment: .leading) {
                                Text(mode.rawValue)
                                    .foregroundColor(.primary)
                                Text(modeDescription(mode))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if bluetoothManager.noiseControlMode == mode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("Ambient Sound")) {
                Toggle("Enable Ambient Sound", isOn: $bluetoothManager.isAmbientSoundOn)
                    .onChange(of: bluetoothManager.isAmbientSoundOn) { newValue in
                        bluetoothManager.setAmbientSound(enabled: newValue)
                    }
                
                if bluetoothManager.isAmbientSoundOn {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ambient Volume")
                            .font(.subheadline)
                        
                        HStack {
                            Text("Low")
                                .font(.caption)
                            Slider(value: Binding(
                                get: { Double(bluetoothManager.ambientVolume) },
                                set: { bluetoothManager.setAmbientVolume(Int($0)) }
                            ), in: 0...3, step: 1)
                            Text("High")
                                .font(.caption)
                        }
                        
                        Text("Level: \(bluetoothManager.ambientVolume)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Gaming Mode")) {
                Toggle("Low Latency Mode", isOn: $bluetoothManager.isGamingModeOn)
                    .onChange(of: bluetoothManager.isGamingModeOn) { newValue in
                        bluetoothManager.setGamingMode(newValue)
                    }
                
                Text("Reduces audio delay for better gaming experience.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Noise Control")
    }
    
    private func modeIcon(_ mode: NoiseControlMode) -> String {
        switch mode {
        case .off:
            return "speaker.slash"
        case .ambient:
            return "ear"
        case .anc:
            return "wave.3.left"
        }
    }
    
    private func modeColor(_ mode: NoiseControlMode) -> Color {
        switch mode {
        case .off:
            return .gray
        case .ambient:
            return .blue
        case .anc:
            return .purple
        }
    }
    
    private func modeDescription(_ mode: NoiseControlMode) -> String {
        switch mode {
        case .off:
            return "No noise control active"
        case .ambient:
            return "Hear your surroundings"
        case .anc:
            return "Active noise cancellation"
        }
    }
}

struct NoiseControlView_Previews: PreviewProvider {
    static var previews: some View {
        NoiseControlView()
            .environmentObject(BluetoothManager())
    }
}
