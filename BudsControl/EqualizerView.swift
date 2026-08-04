import SwiftUI

struct EqualizerView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    let presets: [EQPreset] = [.normal, .bassBoost, .soft, .dynamic, .clear, .trebleBoost]
    
    var body: some View {
        List {
            Section(header: Text("Equalizer Presets")) {
                ForEach(presets, id: \.self) { preset in
                    Button(action: {
                        bluetoothManager.setEqualizer(preset: preset)
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
                    }
                }
            }
            
            Section(header: Text("Current Setting")) {
                HStack {
                    Text("Active Preset")
                    Spacer()
                    Text(bluetoothManager.currentEQPreset.rawValue)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Description")) {
                Text(eqDescription(bluetoothManager.currentEQPreset))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Equalizer")
    }
    
    private func eqDescription(_ preset: EQPreset) -> String {
        switch preset {
        case .normal:
            return "Balanced sound with no modifications."
        case .bassBoost:
            return "Enhanced low frequencies for deeper bass."
        case .soft:
            return "Smoother sound with reduced harshness."
        case .dynamic:
            return "Automatically adjusts based on content."
        case .clear:
            return "Enhanced clarity for vocals and details."
        case .trebleBoost:
            return "Enhanced high frequencies for brighter sound."
        }
    }
}

struct EqualizerView_Previews: PreviewProvider {
    static var previews: some View {
        EqualizerView()
            .environmentObject(BluetoothManager())
    }
}
