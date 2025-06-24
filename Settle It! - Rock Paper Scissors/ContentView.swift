import SwiftUI

struct ContentView: View {
    
    // MARK: - Properties
    /// Uygulamanın ana ağ yöneticisi
    @StateObject private var multipeerManager = MultipeerManager()
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient arkaplan
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Ana içerik - oyun aşamasına göre değişir
                gamePhaseView
            }
        }
        .environmentObject(multipeerManager)
        .onDisappear {
            // Uygulama kapatılırken servisleri durdur
            multipeerManager.stopServices()
        }
        .alert(item: $multipeerManager.connectionAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("Tamam"))
            )
        }
    }
    
    // MARK: - Game Phase View
    /// Oyunun mevcut aşamasına göre uygun view'u döndürür
    @ViewBuilder
    private var gamePhaseView: some View {
        switch multipeerManager.gameState.gamePhase {
        case .lobi:
            LobbyView()
            
        case .oylama:
            VotingView()
            
        case .geriSayim, .turOynaniyor:
            GamePlayView()
            
        case .sonucGosteriliyor:
            ResultsView()
            
        case .oyunBitti:
            GameOverView()
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
