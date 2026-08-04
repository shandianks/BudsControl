import SwiftUI

struct FindMyBudsView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var isSearching = false
    @State private var searchTimer: Timer?
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 80))
                .foregroundColor(isSearching ? .red : .blue)
                .scaleEffect(isSearching ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isSearching)
            
            Text("Find My Buds")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(isSearching ? "Playing sound on your earbuds..." : "Make your earbuds play a sound to help you find them.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if isSearching {
                VStack(spacing: 15) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Searching...")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text("Your earbuds are playing a loud beeping sound.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: {
                toggleSearch()
            }) {
                HStack {
                    Image(systemName: isSearching ? "stop.fill" : "play.fill")
                    Text(isSearching ? "Stop" : "Start Searching")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSearching ? Color.red : Color.blue)
                .cornerRadius(15)
            }
            .padding(.horizontal, 40)
            
            if !isSearching {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tips:")
                        .font(.headline)
                    
                    TipRow(icon: "earbuds", text: "Make sure your earbuds are within Bluetooth range.")
                    TipRow(icon: "speaker.wave.3", text: "The sound will play for 1 minute or until you stop it.")
                    TipRow(icon: "lightbulb", text: "Try searching in quiet environments for better results.")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.top, 30)
        .navigationTitle("Find My Buds")
        .onDisappear {
            stopSearch()
        }
    }
    
    private func toggleSearch() {
        if isSearching {
            stopSearch()
        } else {
            startSearch()
        }
    }
    
    private func startSearch() {
        isSearching = true
        bluetoothManager.findMyBuds(start: true)
        
        // Auto-stop after 60 seconds
        searchTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { _ in
            stopSearch()
        }
    }
    
    private func stopSearch() {
        isSearching = false
        bluetoothManager.findMyBuds(start: false)
        searchTimer?.invalidate()
        searchTimer = nil
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct FindMyBudsView_Previews: PreviewProvider {
    static var previews: some View {
        FindMyBudsView()
            .environmentObject(BluetoothManager())
    }
}
