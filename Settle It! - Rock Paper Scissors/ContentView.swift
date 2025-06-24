import SwiftUI

struct ContentView: View {
    
    // MARK: - Properties
    /// Menünün gösterilip gösterilmediğini kontrol eder
    @State private var showMenu = true
    
    /// Uygulamanın ana ağ yöneticisi - lazy initialization
    @StateObject private var multipeerManager = MultipeerManager()
    
    // MARK: - Body
    var body: some View {
        ZStack {
            if showMenu {
                // Ana menü
                MenuView(showMenu: $showMenu)
                    .environmentObject(multipeerManager)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                // Oyun ekranları
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
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Ana Menü") {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    // Oyunu sıfırla ve ana menüye dön
                                    multipeerManager.resetGame()
                                    showMenu = true
                                }
                            }
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            // Game phase indicator
                            gamePhaseIndicator
                        }
                    }
                }
                .environmentObject(multipeerManager)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
                .alert(item: $multipeerManager.connectionAlert) { (alert: ConnectionAlert) in
                    Alert(
                        title: Text(alert.title),
                        message: Text(alert.message),
                        dismissButton: .default(Text("Tamam"))
                    )
                }
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showMenu)
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
    
    // MARK: - Game Phase Indicator
    @ViewBuilder
    private var gamePhaseIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(getPhaseColor())
                .frame(width: 8, height: 8)
                .animation(.easeInOut(duration: 0.3), value: multipeerManager.gameState.gamePhase)
            
            Text(getPhaseText())
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helper Methods
    private func getPhaseColor() -> Color {
        switch multipeerManager.gameState.gamePhase {
        case .lobi: return .blue
        case .oylama: return .orange
        case .geriSayim: return .yellow
        case .turOynaniyor: return .green
        case .sonucGosteriliyor: return .purple
        case .oyunBitti: return .red
        }
    }
    
    private func getPhaseText() -> String {
        switch multipeerManager.gameState.gamePhase {
        case .lobi: return "Lobi"
        case .oylama: return "Oylama"
        case .geriSayim: return "Hazırlık"
        case .turOynaniyor: return "Oyun"
        case .sonucGosteriliyor: return "Sonuç"
        case .oyunBitti: return "Bitti"
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
