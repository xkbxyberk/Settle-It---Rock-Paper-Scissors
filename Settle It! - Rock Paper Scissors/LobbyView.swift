import SwiftUI

struct LobbyView: View {
    
    // MARK: - Properties
    /// MultipeerManager'dan geçirilen environment object
    @EnvironmentObject var multipeerManager: MultipeerManager
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 30) {
            
            // MARK: - Header
            headerSection
            
            // MARK: - Players List
            playersListSection
            
            // MARK: - Start Game Button
            startGameSection
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("🎯")
                .font(.system(size: 60))
            
            Text("Taş Kağıt Makas")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Turnuva")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.9))
            
            Text("Yakındaki oyuncuları bekliyor...")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - Players List Section
    private var playersListSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            
            // Başlık
            HStack {
                Text("👥 Turnuvaya Katılanlar")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Oyuncu sayısı badge
                Text("\(multipeerManager.gameState.players.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
            
            // Oyuncular listesi
            if multipeerManager.gameState.players.isEmpty {
                // Boş durum
                emptyPlayersView
            } else {
                // Oyuncular var
                playersListView
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Empty Players View
    private var emptyPlayersView: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.5))
            
            Text("Henüz kimse katılmadı")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Text("Diğer cihazların MultipeerConnectivity'yi açmasını bekleyin")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Players List View
    private var playersListView: some View {
        LazyVStack(spacing: 12) {
            ForEach(multipeerManager.gameState.players, id: \.id) { player in
                PlayerRowView(player: player)
            }
        }
    }
    
    // MARK: - Start Game Section
    private var startGameSection: some View {
        VStack(spacing: 15) {
            if multipeerManager.gameState.players.count >= 2 {
                // Oyun başlatma butonu
                Button(action: {
                    multipeerManager.startGame()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                        
                        Text("Oylamayı Başlat")
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
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: multipeerManager.gameState.players.count)
                
            } else {
                // Yetersiz oyuncu mesajı
                VStack(spacing: 8) {
                    Text("⏳ En az 2 oyuncu gerekli")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Diğer cihazların katılmasını bekleyin")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
}

// MARK: - Player Row View
struct PlayerRowView: View {
    let player: Player
    
    var body: some View {
        HStack(spacing: 12) {
            // Oyuncu avatarı
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(player.displayName.prefix(1).uppercased()))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            // Oyuncu bilgileri
            VStack(alignment: .leading, spacing: 2) {
                Text(player.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("Hazır")
                    .font(.caption)
                    .foregroundColor(.green.opacity(0.8))
            }
            
            Spacer()
            
            // Bağlantı durumu
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.green.opacity(0.8))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Preview
#Preview {
    LobbyView()
        .environmentObject(MultipeerManager())
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}
