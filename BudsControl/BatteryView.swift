import SwiftUI

struct BatteryView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Battery Status")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                BatteryIndicator(
                    label: "Left",
                    percentage: bluetoothManager.batteryLeft,
                    isCharging: bluetoothManager.isLeftCharging,
                    isWearing: bluetoothManager.isLeftWearing
                )
                
                BatteryIndicator(
                    label: "Case",
                    percentage: bluetoothManager.batteryCase,
                    isCharging: bluetoothManager.isCaseCharging,
                    isWearing: false
                )
                
                BatteryIndicator(
                    label: "Right",
                    percentage: bluetoothManager.batteryRight,
                    isCharging: bluetoothManager.isRightCharging,
                    isWearing: bluetoothManager.isRightWearing
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct BatteryIndicator: View {
    let label: String
    let percentage: Int
    let isCharging: Bool
    let isWearing: Bool
    
    var batteryColor: Color {
        if percentage <= 20 {
            return .red
        } else if percentage <= 50 {
            return .orange
        } else {
            return .green
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Battery outline
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.secondary, lineWidth: 2)
                    .frame(width: 30, height: 50)
                
                // Battery fill
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 2)
                        .fill(batteryColor)
                        .frame(width: 24, height: CGFloat(max(0, 44 * Double(percentage) / 100)))
                }
                .frame(width: 30, height: 50)
                
                // Charging indicator
                if isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
                
                // Wearing indicator
                if isWearing {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .offset(x: 18, y: -22)
                }
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(percentage)%")
                .font(.caption2)
                .fontWeight(.medium)
        }
    }
}

struct BatteryView_Previews: PreviewProvider {
    static var previews: some View {
        BatteryView()
            .environmentObject(BluetoothManager())
    }
}
