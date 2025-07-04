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
    
    /// Tekrar oyna durumu
    private var playAgainState: PlayAgainState {
        if !multipeerManager.gameState.isWaitingForPlayAgainResponses {
            return .notStarted
        }
        
        let totalPlayers = multipeerManager.gameState.players.count
        let responseCount = multipeerManager.gameState.playAgainRequests.count
        let currentUserResponse = multipeerManager.gameState.playAgainRequests[multipeerManager.getCurrentUserDeviceID()]
        
        if responseCount == totalPlayers {
            // Tüm yanıtlar geldi - kabul eden oyuncu sayısını kontrol et
            let acceptingCount = multipeerManager.gameState.playAgainRequests.values.filter { $0 }.count
            
            if acceptingCount >= 2 {
                return .acceptedWithSomePlayers(acceptingCount: acceptingCount, totalPlayers: totalPlayers)
            } else {
                return .insufficientPlayers(acceptingCount: acceptingCount)
            }
        } else if currentUserResponse != nil {
            return .waitingForOthers
        } else {
            return .waitingForResponse
        }
    }
    
    // MARK: - Body
    var body: some View {
        ResponsiveContainer {
            VStack(spacing: ResponsiveSpacing.huge) {
                
                // MARK: - Header
                headerSection
                
                // MARK: - Winner Section
                winnerSection
                
                // MARK: - Final Standings
                finalStandingsSection
                
                // MARK: - Stats Section
                statsSection
                
                // MARK: - Play Again Section
                playAgainSection
                
                // MARK: - Action Button
                actionButton
                
                Spacer()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            Text("🏆")
                .font(ResponsiveFont.emoji(size: .large))
                .scaleEffect(1.2)
            
            Text("Turnuva Bitti!")
                .font(ResponsiveFont.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Tebrikler! Harika bir turnuva oldu.")
                .font(ResponsiveFont.title3)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Winner Section
    private var winnerSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            
            if let winner = winner {
                // Kazanan var
                VStack(spacing: ResponsiveSpacing.medium) {
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
                            .frame(width: ResponsiveSize.avatarExtraLarge, height: ResponsiveSize.avatarExtraLarge)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                            )
                        
                        Text(winner.avatar)
                            .font(ResponsiveFont.emoji(size: .medium))
                        
                        // Crown overlay
                        Text("👑")
                            .font(ResponsiveFont.emoji(size: .small))
                            .offset(y: -ResponsiveSize.avatarExtraLarge * 0.35)
                    }
                    
                    VStack(spacing: ResponsiveSpacing.small) {
                        Text("🏆 BÜYÜK KAZANAN")
                            .font(ResponsiveFont.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                        
                        Text(winner.displayName)
                            .font(ResponsiveFont.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Mükemmel performans! 🎉")
                            .font(ResponsiveFont.title2)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.vertical, ResponsiveSpacing.extraLarge)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.yellow.opacity(0.3), .orange.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                                .stroke(Color.yellow.opacity(0.5), lineWidth: 2)
                        )
                )
                
            } else {
                // Kazanan yok
                VStack(spacing: ResponsiveSpacing.medium) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(ResponsiveFont.emoji(size: .large))
                        .foregroundColor(.gray)
                    
                    Text("Kazanan Yok")
                        .font(ResponsiveFont.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Turnuva sonuçlanamadı")
                        .font(ResponsiveFont.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, ResponsiveSpacing.extraLarge)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Final Standings Section - DÜZELTİLDİ
    private var finalStandingsSection: some View {
        VStack(alignment: .leading, spacing: ResponsiveSpacing.medium) {
            Text("🏅 Final Sıralaması")
                .font(ResponsiveFont.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: ResponsiveSpacing.small) {
                // Kazanan (1. sıra)
                if let winner = winner {
                    PlayerStandingRow(
                        position: 1,
                        player: winner,
                        isWinner: true
                    )
                }
                
                // Diğer oyuncular (kazanan hariç - deviceID ile güvenli kontrol)
                let otherPlayers = multipeerManager.gameState.players.filter { player in
                    guard let winner = winner else { return true }
                    return winner.deviceID != player.deviceID
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
        .padding(ResponsivePadding.content)
        .background(
            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            Text("📊 Turnuva İstatistikleri")
                .font(ResponsiveFont.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack(spacing: ResponsiveSpacing.extraLarge) {
                // Toplam tur
                VStack(spacing: ResponsiveSpacing.tiny) {
                    Text("\(totalRounds)")
                        .font(ResponsiveFont.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Toplam Tur")
                        .font(ResponsiveFont.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Toplam oyuncu
                VStack(spacing: ResponsiveSpacing.tiny) {
                    Text("\(multipeerManager.gameState.players.count)")
                        .font(ResponsiveFont.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Oyuncu")
                        .font(ResponsiveFont.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Oyun modu
                VStack(spacing: ResponsiveSpacing.tiny) {
                    Text(modeIcon)
                        .font(ResponsiveFont.title)
                    
                    Text("Oyun Modu")
                        .font(ResponsiveFont.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.vertical, ResponsiveSpacing.medium)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Play Again Section
    private var playAgainSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            
            switch playAgainState {
            case .notStarted:
                // Tekrar oyna butonu (sadece host için)
                if multipeerManager.isHost {
                    Button(action: {
                        multipeerManager.playHaptic(style: .medium)
                        multipeerManager.requestPlayAgain()
                    }) {
                        HStack(spacing: ResponsiveSpacing.medium) {
                            Image(systemName: "repeat.circle.fill")
                                .font(ResponsiveFont.title2)
                            
                            VStack(alignment: .leading, spacing: ResponsiveSpacing.tiny) {
                                Text("Tekrar Oyna")
                                    .font(ResponsiveFont.headline)
                                    .fontWeight(.semibold)
                                
                                Text("(Aynı Oyuncularla)")
                                    .font(ResponsiveFont.subheadline)
                                    .opacity(0.8)
                            }
                        }
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ResponsiveSpacing.medium)
                        .background(
                            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                    }
                }
                
            case .waitingForResponse:
                // Kullanıcı yanıtı bekleniyor
                VStack(spacing: ResponsiveSpacing.medium) {
                    Text("🔄 Tekrar Oyna Teklifi")
                        .font(ResponsiveFont.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Aynı oyuncularla yeni bir turnuva başlatmak ister misin?")
                        .font(ResponsiveFont.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: ResponsiveSpacing.medium) {
                        Button("Hayır") {
                            multipeerManager.playHaptic(style: .light)
                            multipeerManager.respondToPlayAgain(accepted: false)
                        }
                        .foregroundColor(.red)
                        .padding(.vertical, ResponsiveSpacing.medium)
                        .padding(.horizontal, ResponsiveSpacing.large)
                        .background(
                            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        )
                        
                        Button("Evet") {
                            multipeerManager.playHaptic(style: .success)
                            multipeerManager.respondToPlayAgain(accepted: true)
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .padding(.vertical, ResponsiveSpacing.medium)
                        .padding(.horizontal, ResponsiveSpacing.large)
                        .background(
                            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                                .fill(Color.green)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        )
                    }
                }
                .padding(.vertical, ResponsiveSpacing.medium)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                        .fill(Color.blue.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                                .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                        )
                )
                
            case .waitingForOthers:
                // Diğer oyuncular bekleniyor
                VStack(spacing: ResponsiveSpacing.medium) {
                    Text("⏳ Diğer Oyuncular Bekleniyor")
                        .font(ResponsiveFont.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Yanıtın alındı. Diğer oyuncuların karar vermesi bekleniyor...")
                        .font(ResponsiveFont.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    // Progress göstergesi
                    PlayAgainProgressView(
                        responses: multipeerManager.gameState.playAgainRequests,
                        players: multipeerManager.gameState.players
                    )
                }
                .padding(.vertical, ResponsiveSpacing.medium)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                        .fill(Color.orange.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                                .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                        )
                )
                
            case .acceptedWithSomePlayers(let acceptingCount, let totalPlayers):
                // Bazı oyuncular kabul etti - yeni turnuva başlıyor
                VStack(spacing: ResponsiveSpacing.medium) {
                    Text("🎉 Yeni Turnuva Başlıyor!")
                        .font(ResponsiveFont.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text(acceptingCount == totalPlayers
                         ? "Tüm oyuncular kabul etti. Birazdan lobi ekranına döneceksiniz..."
                         : "\(acceptingCount)/\(totalPlayers) oyuncu kabul etti. Reddeden oyuncular çıkarılıp yeni turnuva başlayacak..."
                    )
                    .font(ResponsiveFont.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                }
                .padding(.vertical, ResponsiveSpacing.medium)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                        .fill(Color.green.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                                .stroke(Color.green.opacity(0.4), lineWidth: 1)
                        )
                )
                
            case .insufficientPlayers(let acceptingCount):
                // Yetersiz oyuncu kabul etti - ana menüye dönülecek
                VStack(spacing: ResponsiveSpacing.medium) {
                    Text("❌ Yetersiz Kabul")
                        .font(ResponsiveFont.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("Sadece \(acceptingCount) oyuncu kabul etti (minimum 2 gerekli). Ana menüye dönülecek...")
                        .font(ResponsiveFont.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, ResponsiveSpacing.medium)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                        .fill(Color.red.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                                .stroke(Color.red.opacity(0.4), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Action Button
    private var actionButton: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            // Ana menü butonu - her zaman göster
            Button(action: {
                multipeerManager.playHaptic(style: .heavy)
                multipeerManager.resetGame()
            }) {
                HStack(spacing: ResponsiveSpacing.medium) {
                    Image(systemName: "house.circle.fill")
                        .font(ResponsiveFont.title2)
                    
                    Text("Ana Menü")
                        .font(ResponsiveFont.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ResponsiveSpacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
            }
            .scaleEffect(1.0)
            .animation(ResponsiveAnimation.fast, value: multipeerManager.gameState.gamePhase)
            
            Text("Ana menüye dönmek için her şeyi sıfırlar")
                .font(ResponsiveFont.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Helper Properties
    private var modeIcon: String {
        switch multipeerManager.gameState.gameMode {
        case .dokunma: return "👆"
        case .sallama: return "📱"
        case .asamaliTurnuva: return "🏆"
        case .none: return "❓"
        }
    }
}

// MARK: - Play Again State
enum PlayAgainState {
    case notStarted
    case waitingForResponse
    case waitingForOthers
    case acceptedWithSomePlayers(acceptingCount: Int, totalPlayers: Int)
    case insufficientPlayers(acceptingCount: Int)
}

// MARK: - Play Again Progress View
struct PlayAgainProgressView: View {
    let responses: [String: Bool]
    let players: [Player]
    
    var body: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            HStack {
                Text("Yanıtlar: \(responses.count)/\(players.count)")
                    .font(ResponsiveFont.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                // Kabul/ret sayısı
                let acceptingCount = responses.values.filter { $0 }.count
                let rejectingCount = responses.values.filter { !$0 }.count
                
                HStack(spacing: ResponsiveSpacing.medium) {
                    Label("\(acceptingCount)", systemImage: "checkmark.circle.fill")
                        .font(ResponsiveFont.caption)
                        .foregroundColor(.green)
                    
                    Label("\(rejectingCount)", systemImage: "xmark.circle.fill")
                        .font(ResponsiveFont.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Oyuncu yanıt durumları
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: min(players.count, 4)), spacing: ResponsiveSpacing.small) {
                ForEach(players.prefix(8), id: \.id) { player in
                    PlayerResponseIndicator(
                        player: player,
                        response: responses[player.deviceID]
                    )
                }
            }
            
            // Ek bilgi
            if responses.count == players.count {
                let acceptingCount = responses.values.filter { $0 }.count
                Text(acceptingCount >= 2
                     ? "✅ \(acceptingCount) oyuncu devam edecek"
                     : "❌ Minimum 2 oyuncu gerekli (\(acceptingCount) kabul etti)"
                )
                .font(ResponsiveFont.caption)
                .foregroundColor(acceptingCount >= 2 ? .green : .red)
                .fontWeight(.medium)
            }
        }
    }
}

// MARK: - Player Response Indicator
struct PlayerResponseIndicator: View {
    let player: Player
    let response: Bool?
    
    var body: some View {
        VStack(spacing: ResponsiveSpacing.tiny) {
            ZStack {
                Circle()
                    .fill(responseColor.opacity(0.3))
                    .frame(width: ResponsiveSize.avatarSmall * 0.8, height: ResponsiveSize.avatarSmall * 0.8)
                    .overlay(
                        Circle()
                            .stroke(responseColor, lineWidth: 2)
                    )
                
                if let response = response {
                    Image(systemName: response ? "checkmark" : "xmark")
                        .font(ResponsiveFont.caption)
                        .fontWeight(.bold)
                        .foregroundColor(responseColor)
                } else {
                    Text(player.avatar)
                        .font(.system(size: ResponsiveSize.avatarSmall * 0.3))
                }
            }
            
            Text(player.displayName)
                .font(ResponsiveFont.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
        }
    }
    
    private var responseColor: Color {
        guard let response = response else { return .white.opacity(0.5) }
        return response ? .green : .red
    }
}

// MARK: - Player Standing Row
struct PlayerStandingRow: View {
    let position: Int
    let player: Player
    let isWinner: Bool
    
    var body: some View {
        HStack(spacing: ResponsiveSpacing.medium) {
            // Position
            ZStack {
                Circle()
                    .fill(positionColor.opacity(0.3))
                    .frame(width: ResponsiveSize.avatarSmall * 0.8, height: ResponsiveSize.avatarSmall * 0.8)
                    .overlay(
                        Circle()
                            .stroke(positionColor, lineWidth: 2)
                    )
                
                Text("\(position)")
                    .font(ResponsiveFont.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(positionColor)
            }
            
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: ResponsiveSize.avatarSmall, height: ResponsiveSize.avatarSmall)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                
                Text(player.avatar)
                    .font(.system(size: ResponsiveSize.avatarSmall * 0.7))
                
                // Crown for winner
                if isWinner {
                    Text("👑")
                        .font(ResponsiveFont.caption)
                        .offset(x: ResponsiveSize.avatarSmall * 0.3, y: -ResponsiveSize.avatarSmall * 0.3)
                }
            }
            
            // Player info
            VStack(alignment: .leading, spacing: ResponsiveSpacing.tiny) {
                Text(player.displayName)
                    .font(ResponsiveFont.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(isWinner ? "KAZANAN" : "Elendi")
                    .font(ResponsiveFont.caption)
                    .foregroundColor(isWinner ? .yellow : .white.opacity(0.6))
            }
            
            Spacer()
            
            // Medal/Status
            if isWinner {
                Text("🏆")
                    .font(ResponsiveFont.title2)
            } else {
                Image(systemName: "checkmark.circle")
                    .font(ResponsiveFont.subheadline)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.vertical, ResponsiveSpacing.small)
        .padding(.horizontal, ResponsiveSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                .fill(isWinner ? Color.yellow.opacity(0.15) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
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
