import SwiftUI

struct TouchpadView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    let leftActions: [TouchpadAction] = [.voiceAssistant, .volume, .ambientSound, .noiseControl]
    let rightActions: [TouchpadAction] = [.voiceAssistant, .volume, .ambientSound, .noiseControl]
    
    @State private var leftAction: TouchpadAction = .voiceAssistant
    @State private var rightAction: TouchpadAction = .ambientSound
    
    var body: some View {
        List {
            Section {
                Toggle("Lock Touchpad", isOn: $bluetoothManager.isTouchpadLocked)
                    .onChange(of: bluetoothManager.isTouchpadLocked) { newValue in
                        bluetoothManager.setTouchpadLock(newValue)
                    }
            }
            
            if !bluetoothManager.isTouchpadLocked {
                Section(header: Text("Left Earbud")) {
                    Picker("Action", selection: $leftAction) {
                        ForEach(leftActions, id: \.self) { action in
                            Text(actionDescription(action))
                                .tag(action)
                        }
                    }
                    .onChange(of: leftAction) { newValue in
                        bluetoothManager.sendMessage(
                            MessageEncoder.encodeTouchpadOptions(left: newValue, right: rightAction)
                        )
                    }
                }
                
                Section(header: Text("Right Earbud")) {
                    Picker("Action", selection: $rightAction) {
                        ForEach(rightActions, id: \.self) { action in
                            Text(actionDescription(action))
                                .tag(action)
                        }
                    }
                    .onChange(of: rightAction) { newValue in
                        bluetoothManager.sendMessage(
                            MessageEncoder.encodeTouchpadOptions(left: leftAction, right: newValue)
                        )
                    }
                }
                
                Section(header: Text("Double Tap Volume")) {
                    Toggle("Enable", isOn: .constant(true))
                    
                    Text("Double-tap the edge of the touchpad to adjust volume.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Touchpad Gestures")) {
                GestureRow(
                    gesture: "Single Tap",
                    action: "Play/Pause"
                )
                GestureRow(
                    gesture: "Double Tap",
                    action: "Next Track / Answer Call"
                )
                GestureRow(
                    gesture: "Triple Tap",
                    action: "Previous Track"
                )
                GestureRow(
                    gesture: "Touch and Hold",
                    action: "Custom Action"
                )
            }
        }
        .navigationTitle("Touchpad")
    }
    
    private func actionDescription(_ action: TouchpadAction) -> String {
        switch action {
        case .unused:
            return "None"
        case .voiceAssistant:
            return "Voice Assistant"
        case .volume:
            return "Volume Control"
        case .ambientSound:
            return "Ambient Sound"
        case .spotify:
            return "Spotify"
        case .noiseControl:
            return "Noise Control"
        case .custom:
            return "Custom"
        }
    }
}

struct GestureRow: View {
    let gesture: String
    let action: String
    
    var body: some View {
        HStack {
            Text(gesture)
            Spacer()
            Text(action)
                .foregroundColor(.secondary)
        }
    }
}

struct TouchpadView_Previews: PreviewProvider {
    static var previews: some View {
        TouchpadView()
            .environmentObject(BluetoothManager())
    }
}
