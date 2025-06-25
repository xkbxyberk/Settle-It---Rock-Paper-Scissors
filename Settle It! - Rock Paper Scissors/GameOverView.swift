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
            
            // MARK: - Final Standings
            finalStandingsSection
            
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
            
            Text("Turnuva Bitti!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Tebrikler! Harika bir turnuva oldu.")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Winner Section
    private var winnerSection: some View {
        VStack(spacing: 20) {
            
            if let winner = winner {
                // Kazanan var
                VStack(spacing: 16) {
                    // Winner avatar with crown
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
                        
                        Text(winner.avatar)
                            .font(.system(size: 50))
                        
                        // Crown overlay
                        Text("👑")
                            .font(.system(size: 40))
                            .offset(y: -50)
                    }
                    
                    VStack(spacing: 8) {
                        Text("🏆 BÜYÜK KAZANAN")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                        
                        Text(winner.displayName)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Mükemmel performans! 🎉")
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
    
    // MARK: - Final Standings Section
    private var finalStandingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🏅 Final Sıralaması")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                // Kazanan (1. sıra)
                if let winner = winner {
                    PlayerStandingRow(
                        position: 1,
                        player: winner,
                        isWinner: true
                    )
                }
                
                // Diğer oyuncular (son elemeler)
                let otherPlayers = multipeerManager.gameState.players.filter { player in
                    winner?.id != player.id
                }
                
                ForEach(Array(otherPlayers.enumerated()), id: \.element.id) { index, player in
                    PlayerStandingRow(
                        position: index + 2,
                        player: player,
                        isWinner: false
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
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
                    Text(modeIcon)
                        .font(.title)
                    
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
                multipeerManager.playHaptic(style: .heavy)
                multipeerManager.resetGame()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.title2)
                    
                    Text("Yeni Turnuva")
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
            
            Text("Ana menüye dönmek için yeni turnuva başlatın")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Helper Properties
    private var modeIcon: String {
        switch multipeerManager.gameState.gameMode {
        case .dokunma: return "👆"
        case .sallama: return "📱"
        case .none: return "❓"
        }
    }
}

// MARK: - Player Standing Row
struct PlayerStandingRow: View {
    let position: Int
    let player: Player
    let isWinner: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Position
            ZStack {
                Circle()
                    .fill(positionColor.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(positionColor, lineWidth: 2)
                    )
                
                Text("\(position)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(positionColor)
            }
            
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                
                Text(player.avatar)
                    .font(.title3)
                
                // Crown for winner
                if isWinner {
                    Text("👑")
                        .font(.caption)
                        .offset(x: 12, y: -12)
                }
            }
            
            // Player info
            VStack(alignment: .leading, spacing: 2) {
                Text(player.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(isWinner ? "KAZANAN" : "Elendi")
                    .font(.caption)
                    .foregroundColor(isWinner ? .yellow : .white.opacity(0.6))
            }
            
            Spacer()
            
            // Medal/Status
            if isWinner {
                Text("🏆")
                    .font(.title2)
            } else {
                Image(systemName: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isWinner ? Color.yellow.opacity(0.15) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isWinner ? Color.yellow.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var positionColor: Color {
        switch position {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .white.opacity(0.6)
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
