import SwiftUI

struct GameOverView: View {
    
    // MARK: - Properties
    /// MultipeerManager'dan geçirilen environment object
    @EnvironmentObject var multipeerManager: MultipeerManager
    
    /// Kazanan oyuncu
    private var winner: Player? {
        multipeerManager.gameState.activePlayers.first
    }
    
    /// Toplam tur sayısı
    private var totalRounds: Int {
        multipeerManager.gameState.currentRound
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 40) {
            
            // MARK: - Header
            headerSection
            
            // MARK: - Winner Section
            winnerSection
            
            // MARK: - Stats Section
            statsSection
            
            // MARK: - Action Button
            actionButton
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 15) {
            Text("🏆")
                .font(.system(size: 80))
                .scaleEffect(1.2)
            
            Text("Oyun Bitti!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Turnuva tamamlandı")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    // MARK: - Winner Section
    private var winnerSection: some View {
        VStack(spacing: 20) {
            
            if let winner = winner {
                // Kazanan var
                VStack(spacing: 16) {
                    // Winner avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.yellow, .orange]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                            )
                        
                        Text(String(winner.displayName.prefix(2).uppercased()))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        // Crown overlay
                        Text("👑")
                            .font(.system(size: 40))
                            .offset(y: -50)
                    }
                    
                    VStack(spacing: 8) {
                        Text("KAZANAN")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                        
                        Text(winner.displayName)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Tebrikler! 🎉")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.vertical, 30)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.yellow.opacity(0.3), .orange.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.yellow.opacity(0.5), lineWidth: 2)
                        )
                )
                
            } else {
                // Kazanan yok
                VStack(spacing: 16) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    
                    Text("Kazanan Yok")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Turnuva sonuçlanamadı")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 30)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(spacing: 16) {
            Text("📊 Turnuva İstatistikleri")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack(spacing: 30) {
                // Toplam tur
                VStack(spacing: 4) {
                    Text("\(totalRounds)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Toplam Tur")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Toplam oyuncu
                VStack(spacing: 4) {
                    Text("\(multipeerManager.gameState.players.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Oyuncu")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Oyun modu
                VStack(spacing: 4) {
                    Text(multipeerManager.gameState.gameMode?.rawValue.prefix(1).uppercased() ?? "?")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    
                    Text("Oyun Modu")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Action Button
    private var actionButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                multipeerManager.resetGame()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.title2)
                    
                    Text("Ana Menüye Dön")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
            }
            .scaleEffect(1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: multipeerManager.gameState.gamePhase)
            
            Text("Yeni bir turnuva başlatmak için lobiye dönün")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Preview
#Preview {
    GameOverView()
        .environmentObject(MultipeerManager())
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}
