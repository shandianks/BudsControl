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
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Battery Status Card
                BatteryView()
                
                // Quick Actions Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    NavigationLink(destination: EqualizerView()) {
                        ControlCard(
                            icon: "waveform",
                            title: "Equalizer",
                            subtitle: bluetoothManager.currentEQPreset.rawValue
                        )
                    }
                    
                    NavigationLink(destination: NoiseControlView()) {
                        ControlCard(
                            icon: "earbuds",
                            title: "Noise Control",
                            subtitle: bluetoothManager.noiseControlMode.rawValue
                        )
                    }
                    
                    NavigationLink(destination: AmbientSoundView()) {
                        ControlCard(
                            icon: "ear",
                            title: "Ambient Sound",
                            subtitle: bluetoothManager.isAmbientSoundOn ? "On" : "Off"
                        )
                    }
                    
                    NavigationLink(destination: TouchpadView()) {
                        ControlCard(
                            icon: "hand.tap",
                            title: "Touchpad",
                            subtitle: bluetoothManager.isTouchpadLocked ? "Locked" : "Active"
                        )
                    }
                }
                .padding(.horizontal)
                
                // Find My Buds
                NavigationLink(destination: FindMyBudsView()) {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.title2)
                        Text("Find My Buds")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                }
                .padding(.horizontal)
                
                // Device Info
                DeviceInfoCard()
            }
            .padding(.vertical)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    bluetoothManager.disconnect()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
        }
    }
}

struct ControlCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

struct DeviceInfoCard: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Device Information")
                .font(.headline)
            
            HStack {
                Text("Model")
                    .foregroundColor(.secondary)
                Spacer()
                Text("Galaxy Buds2")
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Firmware")
                    .foregroundColor(.secondary)
                Spacer()
                Text(bluetoothManager.firmwareVersion)
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Serial Number")
                    .foregroundColor(.secondary)
                Spacer()
                Text(bluetoothManager.serialNumber)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(BluetoothManager())
    }
}
