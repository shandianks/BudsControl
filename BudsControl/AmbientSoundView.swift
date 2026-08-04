import SwiftUI

struct AmbientSoundView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        List {
            Section {
                Toggle("Ambient Sound", isOn: $bluetoothManager.isAmbientSoundOn)
                    .onChange(of: bluetoothManager.isAmbientSoundOn) { newValue in
                        bluetoothManager.setAmbientSound(enabled: newValue)
                    }
            }
            
            if bluetoothManager.isAmbientSoundOn {
                Section(header: Text("Volume Level")) {
                    VStack(spacing: 15) {
                        HStack {
                            Image(systemName: "speaker.fill")
                                .foregroundColor(.secondary)
                            
                            Slider(value: Binding(
                                get: { Double(bluetoothManager.ambientVolume) },
                                set: { bluetoothManager.setAmbientVolume(Int($0)) }
                            ), in: 0...3, step: 1)
                            
                            Image(systemName: "speaker.wave.3.fill")
                                .foregroundColor(.secondary)
                        }
                        
                        Text(volumeDescription(bluetoothManager.ambientVolume))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 10)
                }
                
                Section(header: Text("Voice Focus")) {
                    Toggle("Focus on Voice", isOn: .constant(false))
                    
                    Text("Enhances voices in ambient sound mode.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Extra High Volume")) {
                    Toggle("Extra Volume Step", isOn: .constant(false))
                    
                    Text("Adds an extra volume level for ambient sound.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("About")) {
                Text("Ambient sound allows you to hear your surroundings while wearing your Galaxy Buds2. This is useful when you need to be aware of your environment.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Ambient Sound")
    }
    
    private func volumeDescription(_ level: Int) -> String {
        switch level {
        case 0:
            return "Low - Minimal ambient sound"
        case 1:
            return "Medium - Balanced ambient sound"
        case 2:
            return "High - Maximum ambient sound"
        case 3:
            return "Extra High - Enhanced ambient sound"
        default:
            return "Unknown"
        }
    }
}

struct AmbientSoundView_Previews: PreviewProvider {
    static var previews: some View {
        AmbientSoundView()
            .environmentObject(BluetoothManager())
    }
}
