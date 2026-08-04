import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var deviceName = "Galaxy Buds2"
    @State private var showResetAlert = false
    
    var body: some View {
        List {
            Section(header: Text("Device")) {
                HStack {
                    Text("Name")
                    Spacer()
                    TextField("Device Name", text: $deviceName)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                
                Button("Rename Device") {
                    bluetoothManager.sendMessage(
                        MessageEncoder.encodeRename(name: deviceName)
                    )
                }
                
                HStack {
                    Text("Model")
                    Spacer()
                    Text("Galaxy Buds2")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Firmware")
                    Spacer()
                    Text(bluetoothManager.firmwareVersion)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Serial Number")
                    Spacer()
                    Text(bluetoothManager.serialNumber)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Connection")) {
                Toggle("Seamless Connection", isOn: .constant(true))
                
                Text("Automatically switch between devices.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Enter Pairing Mode") {
                    bluetoothManager.sendMessage(
                        MessageEncoder.encodePairingMode()
                    )
                }
            }
            
            Section(header: Text("Advanced")) {
                NavigationLink("Debug Information") {
                    DebugInfoView()
                }
                
                Button("Request Status Update") {
                    bluetoothManager.requestStatusUpdate()
                }
                
                Button("Update Device Time") {
                    bluetoothManager.updateTime()
                }
            }
            
            Section(header: Text("Danger Zone")) {
                Button("Reset to Factory Defaults") {
                    showResetAlert = true
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Settings")
        .alert("Reset Device", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                bluetoothManager.sendMessage(
                    MessageEncoder.encodeReset()
                )
            }
        } message: {
            Text("This will reset your Galaxy Buds2 to factory defaults. All settings will be lost.")
        }
    }
}

struct DebugInfoView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        List {
            Section(header: Text("Device Status")) {
                StatusRow(label: "Connected", value: bluetoothManager.isConnected ? "Yes" : "No")
                StatusRow(label: "Battery Left", value: "\(bluetoothManager.batteryLeft)%")
                StatusRow(label: "Battery Right", value: "\(bluetoothManager.batteryRight)%")
                StatusRow(label: "Battery Case", value: "\(bluetoothManager.batteryCase)%")
                StatusRow(label: "Left Charging", value: bluetoothManager.isLeftCharging ? "Yes" : "No")
                StatusRow(label: "Right Charging", value: bluetoothManager.isRightCharging ? "Yes" : "No")
                StatusRow(label: "Case Charging", value: bluetoothManager.isCaseCharging ? "Yes" : "No")
                StatusRow(label: "Left Wearing", value: bluetoothManager.isLeftWearing ? "Yes" : "No")
                StatusRow(label: "Right Wearing", value: bluetoothManager.isRightWearing ? "Yes" : "No")
                StatusRow(label: "Coupled", value: bluetoothManager.isCoupled ? "Yes" : "No")
            }
            
            Section(header: Text("Settings")) {
                StatusRow(label: "Ambient Sound", value: bluetoothManager.isAmbientSoundOn ? "On" : "Off")
                StatusRow(label: "Ambient Volume", value: "\(bluetoothManager.ambientVolume)")
                StatusRow(label: "Touchpad Lock", value: bluetoothManager.isTouchpadLocked ? "Locked" : "Unlocked")
                StatusRow(label: "EQ Preset", value: bluetoothManager.currentEQPreset.rawValue)
                StatusRow(label: "Noise Control", value: bluetoothManager.noiseControlMode.rawValue)
                StatusRow(label: "Gaming Mode", value: bluetoothManager.isGamingModeOn ? "On" : "Off")
            }
            
            Section(header: Text("Actions")) {
                Button("Get Serial Number") {
                    bluetoothManager.sendMessage(
                        MessageEncoder.encodeDebugSerialNumber()
                    )
                }
                
                Button("Get Build Info") {
                    bluetoothManager.sendMessage(
                        MessageEncoder.encodeDebugBuildInfo()
                    )
                }
                
                Button("Get All Data") {
                    bluetoothManager.sendMessage(
                        MessageEncoder.encodeDebugGetAllData()
                    )
                }
                
                Button("Run Self Test") {
                    bluetoothManager.sendMessage(
                        MessageEncoder.encodeSelfTest()
                    )
                }
            }
        }
        .navigationTitle("Debug Info")
    }
}

struct StatusRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(BluetoothManager())
    }
}
