import SwiftUI
import UIKit

struct LobbyView: View {
    
    // MARK: - Properties
    /// MultipeerManager'dan geçirilen environment object
    @EnvironmentObject var multipeerManager: MultipeerManager
    
    /// Ana menüye dönüş closure'ı
    let returnToMainMenu: () -> Void
    
    @State private var showCreateRoom = false
    @State private var showJoinRoom = false
    @State private var newRoomName = ""
    @State private var roomCodeInput = ""
    @State private var isJoiningRoom = false
    
    /// Host olup olmadığını kontrol eder
    private var isHost: Bool {
        multipeerManager.isHost
    }
    
    /// Oda bilgisi
    private var currentRoom: GameRoom? {
        multipeerManager.gameState.currentRoom
    }
    
    // MARK: - Body
    var body: some View {
        ResponsiveContainer {
            VStack(spacing: ResponsiveSpacing.extraLarge) {
                
                // MARK: - Header
                headerSection
                
                // MARK: - Room Section
                if currentRoom != nil {
                    roomInfoSection
                    playersListSection
                    startGameSection
                } else {
                    noRoomSection
                    createRoomSection
                }
                
                Spacer()
            }
        }
        .onAppear {
            // Lobi'ye geldiğimizde servisleri yeniden başlat
            multipeerManager.restartServices()
        }
        .alert("Oda Oluştur", isPresented: $showCreateRoom) {
            TextField("Oda adı", text: $newRoomName)
            Button("İptal", role: .cancel) {}
            Button("Oluştur") {
                multipeerManager.createRoom(name: newRoomName.isEmpty ? "Yeni Oda" : newRoomName)
                newRoomName = ""
            }
        } message: {
            Text("Yeni bir oyun odası oluşturun ve arkadaşlarınızın katılmasını bekleyin.")
        }
        .alert("Odaya Katıl", isPresented: $showJoinRoom) {
            TextField("Oda kodu (4 hane)", text: $roomCodeInput)
                .keyboardType(.numberPad)
            Button("İptal", role: .cancel) {
                roomCodeInput = ""
            }
            Button("Katıl") {
                if roomCodeInput.count == 4 {
                    isJoiningRoom = true
                    multipeerManager.joinRoom(withCode: roomCodeInput)
                    roomCodeInput = ""
                }
            }
            .disabled(roomCodeInput.count != 4)
        } message: {
            Text("4 haneli oda kodunu girerek arkadaşının odasına katıl.")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: ResponsiveSpacing.small) {
            Text("🎯")
                .font(ResponsiveFont.emoji(size: .medium))
            
            Text("Taş - Kağıt - Makas")
                .font(ResponsiveFont.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Turnuva")
                .font(ResponsiveFont.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.9))
        }
    }
    
    // MARK: - Room Info Section
    private var roomInfoSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            HStack {
                Image(systemName: "door.left.hand.open")
                    .font(ResponsiveFont.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: ResponsiveSpacing.tiny) {
                    Text(currentRoom?.roomName ?? "Bilinmeyen Oda")
                        .font(ResponsiveFont.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(isHost ? "Sen host'sun" : "Odaya katıldın")
                        .font(ResponsiveFont.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                if isHost {
                    Image(systemName: "crown.fill")
                        .font(ResponsiveFont.title3)
                        .foregroundColor(.yellow)
                }
            }
            
            // Oda Kodu Gösterimi
            if let room = currentRoom {
                VStack(spacing: ResponsiveSpacing.small) {
                    Text("🔑 Oda Kodu")
                        .font(ResponsiveFont.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                    
                    HStack(spacing: ResponsiveSpacing.small) {
                        Text(room.roomCode)
                            .font(ResponsiveFont.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, ResponsiveSpacing.medium)
                            .padding(.vertical, ResponsiveSpacing.small)
                            .background(
                                RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                                    .fill(Color.white.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                    )
                            )
                        
                        Button(action: {
                            UIPasteboard.general.string = room.roomCode
                            multipeerManager.playHaptic(style: .light)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(ResponsiveFont.title3)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Text("Arkadaşların bu kodu girip odana katılabilir")
                        .font(ResponsiveFont.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, ResponsiveSpacing.small)
            }
        }
        .responsiveCard(backgroundColor: Color.green.opacity(0.2), borderColor: Color.green.opacity(0.4))
    }
    
    // MARK: - No Room Section
    private var noRoomSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            Image(systemName: "person.2.slash")
                .font(ResponsiveFont.emoji(size: .medium))
                .foregroundColor(.white.opacity(0.5))
            
            Text("Henüz hiçbir odaya katılmadın")
                .font(ResponsiveFont.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Yeni bir oda oluştur veya yakındaki odalara otomatik katıl")
                .font(ResponsiveFont.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, ResponsiveSpacing.extraLarge)
        .frame(maxWidth: .infinity)
        .responsiveCard()
    }
    
    // MARK: - Create Room Section
    private var createRoomSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            // Yeni Oda Oluştur
            Button(action: {
                showCreateRoom = true
            }) {
                HStack(spacing: ResponsiveSpacing.medium) {
                    Image(systemName: "plus.circle.fill")
                        .font(ResponsiveFont.title2)
                    
                    Text("Yeni Oda Oluştur")
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
            
            // Odaya Katıl
            Button(action: {
                showJoinRoom = true
            }) {
                HStack(spacing: ResponsiveSpacing.medium) {
                    Image(systemName: "key.fill")
                        .font(ResponsiveFont.title2)
                    
                    Text("Odaya Katıl")
                        .font(ResponsiveFont.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ResponsiveSpacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                        .fill(Color.blue)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
            }
            
            VStack(spacing: ResponsiveSpacing.tiny) {
                Text("Arkadaşlarınla oynamak için bir oda oluştur")
                    .font(ResponsiveFont.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                
                Text("veya oda kodunu girerek katıl")
                    .font(ResponsiveFont.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Players List Section
    private var playersListSection: some View {
        VStack(alignment: .leading, spacing: ResponsiveSpacing.medium) {
            
            // Başlık
            HStack {
                Text("👥 Odadaki Oyuncular")
                    .font(ResponsiveFont.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Oyuncu sayısı badge
                Text("\(multipeerManager.gameState.players.count)")
                    .font(ResponsiveFont.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, ResponsiveSpacing.small)
                    .padding(.vertical, ResponsiveSpacing.tiny)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
            
            // Oyuncular listesi
            if multipeerManager.gameState.players.isEmpty {
                // Boş durum
                emptyPlayersView
            } else {
                // Oyuncular var - GameOverView benzeri tasarım
                playersScrollListView
            }
        }
        .responsiveCard()
    }
    
    // MARK: - Empty Players View
    private var emptyPlayersView: some View {
        VStack(spacing: ResponsiveSpacing.small) {
            Image(systemName: "person.2.slash")
                .font(ResponsiveFont.emoji(size: .small))
                .foregroundColor(.white.opacity(0.5))
            
            Text("Henüz kimse katılmadı")
                .font(ResponsiveFont.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Text("Diğer cihazların katılmasını bekleyin")
                .font(ResponsiveFont.caption)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ResponsiveSpacing.medium)
    }
    
    // MARK: - Players Scroll List View - GameOverView benzeri tasarım
    private var playersScrollListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: ResponsiveSpacing.small) {
                ForEach(Array(multipeerManager.gameState.players.enumerated()), id: \.element.id) { index, player in
                    LobbyPlayerRow(
                        position: index + 1,
                        player: player,
                        isHost: player.deviceID == multipeerManager.gameState.hostDeviceID,
                        isCurrentUser: player.deviceID == multipeerManager.getCurrentUserDeviceID()
                    )
                }
            }
            .padding(.vertical, ResponsiveSpacing.small)
        }
        .frame(maxHeight: 280) // Maksimum yükseklik - yaklaşık 4-5 oyuncu gösterimi
    }
    
    // MARK: - Start Game Section
    private var startGameSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            if isHost {
                if multipeerManager.gameState.players.count >= 2 {
                    // Oyun başlatma butonu (sadece host için)
                    Button(action: {
                        multipeerManager.playHaptic(style: .heavy)
                        multipeerManager.startGame()
                    }) {
                        HStack(spacing: ResponsiveSpacing.medium) {
                            Image(systemName: "play.circle.fill")
                                .font(ResponsiveFont.title2)
                            
                            Text("Turnuvayı Başlat")
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
                    .animation(ResponsiveAnimation.fast, value: multipeerManager.gameState.players.count)
                    
                } else {
                    // Yetersiz oyuncu mesajı (host için)
                    VStack(spacing: ResponsiveSpacing.small) {
                        Text("👑 En az 2 oyuncu gerekli")
                            .font(ResponsiveFont.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Daha fazla oyuncunun katılmasını bekleyin")
                            .font(ResponsiveFont.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.vertical, ResponsiveSpacing.medium)
                    .frame(maxWidth: .infinity)
                    .responsiveCard()
                }
            } else {
                // Host olmayan oyuncular için bekleme mesajı
                VStack(spacing: ResponsiveSpacing.small) {
                    Text("⏳ Host'un turnuvayı başlatmasını bekliyor...")
                        .font(ResponsiveFont.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Text("Hazır olduğunda turnuva başlayacak")
                        .font(ResponsiveFont.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.vertical, ResponsiveSpacing.medium)
                .frame(maxWidth: .infinity)
                .responsiveCard(backgroundColor: Color.orange.opacity(0.2), borderColor: Color.orange.opacity(0.4))
            }
        }
    }
}

// MARK: - Lobby Player Row - GameOverView.PlayerStandingRow benzeri tasarım
struct LobbyPlayerRow: View {
    let position: Int
    let player: Player
    let isHost: Bool
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: ResponsiveSpacing.medium) {
            // Position/Status circle
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.3))
                    .frame(width: ResponsiveSize.avatarSmall * 0.8, height: ResponsiveSize.avatarSmall * 0.8)
                    .overlay(
                        Circle()
                            .stroke(statusColor, lineWidth: 2)
                    )
                
                if isHost {
                    Image(systemName: "crown.fill")
                        .font(ResponsiveFont.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(statusColor)
                } else {
                    Text("\(position)")
                        .font(ResponsiveFont.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(statusColor)
                }
            }
            
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: ResponsiveSize.avatarSmall, height: ResponsiveSize.avatarSmall)
                    .overlay(
                        Circle()
                            .stroke(isCurrentUser ? Color.blue.opacity(0.6) : Color.white.opacity(0.3), lineWidth: isCurrentUser ? 2 : 1)
                    )
                
                Text(player.avatar)
                    .font(.system(size: ResponsiveSize.avatarSmall * 0.7))
            }
            
            // Player info
            VStack(alignment: .leading, spacing: ResponsiveSpacing.tiny) {
                HStack(spacing: ResponsiveSpacing.tiny) {
                    Text(player.displayName)
                        .font(ResponsiveFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if isCurrentUser {
                        Text("(Sen)")
                            .font(ResponsiveFont.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue.opacity(0.8))
                            .padding(.horizontal, ResponsiveSpacing.tiny)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.2))
                            )
                    }
                }
                
                Text(isHost ? "Oda Host'u" : "Hazır")
                    .font(ResponsiveFont.caption)
                    .foregroundColor(isHost ? .yellow.opacity(0.9) : .green.opacity(0.8))
            }
            
            Spacer()
            
            // Status icon
            HStack(spacing: ResponsiveSpacing.small) {
                // Bağlantı durumu
                Image(systemName: "wifi.circle.fill")
                    .font(ResponsiveFont.subheadline)
                    .foregroundColor(.green.opacity(0.8))
                
                // Host crown veya ready checkmark
                if isHost {
                    Text("👑")
                        .font(ResponsiveFont.title3)
                } else {
                    Image(systemName: "checkmark.circle")
                        .font(ResponsiveFont.subheadline)
                        .foregroundColor(.green.opacity(0.8))
                }
            }
        }
        .padding(.vertical, ResponsiveSpacing.small)
        .padding(.horizontal, ResponsiveSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                .fill(backgroundFill)
                .overlay(
                    RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                        .stroke(borderStroke, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helper Properties
    private var statusColor: Color {
        if isHost {
            return .yellow
        } else if isCurrentUser {
            return .blue
        } else {
            return .white.opacity(0.6)
        }
    }
    
    private var backgroundFill: Color {
        if isHost {
            return Color.yellow.opacity(0.15)
        } else if isCurrentUser {
            return Color.blue.opacity(0.15)
        } else {
            return Color.white.opacity(0.05)
        }
    }
    
    private var borderStroke: Color {
        if isHost {
            return Color.yellow.opacity(0.3)
        } else if isCurrentUser {
            return Color.blue.opacity(0.3)
        } else {
            return Color.white.opacity(0.1)
        }
    }
}

// MARK: - Preview
#Preview {
    LobbyView(returnToMainMenu: {})
        .environmentObject(MultipeerManager())
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}
