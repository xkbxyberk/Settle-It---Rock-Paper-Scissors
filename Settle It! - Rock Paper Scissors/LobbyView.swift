import SwiftUI
import UIKit

struct LobbyView: View {
    
    // MARK: - Properties
    /// MultipeerManager'dan geçirilen environment object
    @EnvironmentObject var multipeerManager: MultipeerManager
    
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
        VStack(spacing: 30) {
            
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
        .padding(.horizontal, 20)
        .padding(.top, 20)
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
        }
    }
    
    // MARK: - Room Info Section
    private var roomInfoSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "door.left.hand.open")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentRoom?.roomName ?? "Bilinmeyen Oda")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(isHost ? "Sen host'sun" : "Odaya katıldın")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                if isHost {
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundColor(.yellow)
                }
            }
            
            // Oda Kodu Gösterimi
            if let room = currentRoom {
                VStack(spacing: 8) {
                    Text("🔑 Oda Kodu")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                    
                    HStack(spacing: 8) {
                        Text(room.roomCode)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                    )
                            )
                        
                        Button(action: {
                            UIPasteboard.general.string = room.roomCode
                            multipeerManager.playHaptic(style: .light)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Text("Arkadaşların bu kodu girip odana katılabilir")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.4), lineWidth: 1)
                )
        )
    }
    
    // MARK: - No Room Section
    private var noRoomSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.5))
            
            Text("Henüz hiçbir odaya katılmadın")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Yeni bir oda oluştur veya yakındaki odalara otomatik katıl")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 30)
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
    
    // MARK: - Create Room Section
    private var createRoomSection: some View {
        VStack(spacing: 16) {
            // Yeni Oda Oluştur
            Button(action: {
                showCreateRoom = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    
                    Text("Yeni Oda Oluştur")
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
            
            // Odaya Katıl
            Button(action: {
                showJoinRoom = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.title2)
                    
                    Text("Odaya Katıl")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
            }
            
            VStack(spacing: 4) {
                Text("Arkadaşlarınla oynamak için bir oda oluştur")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                
                Text("veya oda kodunu girerek katıl")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Players List Section
    private var playersListSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            
            // Başlık
            HStack {
                Text("👥 Odadaki Oyuncular")
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
            
            Text("Diğer cihazların katılmasını bekleyin")
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
                PlayerRowView(
                    player: player,
                    isHost: player.deviceID == multipeerManager.gameState.hostDeviceID,
                    isCurrentUser: player.deviceID == multipeerManager.getCurrentUserDeviceID()
                )
            }
        }
    }
    
    // MARK: - Start Game Section
    private var startGameSection: some View {
        VStack(spacing: 15) {
            if isHost {
                if multipeerManager.gameState.players.count >= 2 {
                    // Oyun başlatma butonu (sadece host için)
                    Button(action: {
                        multipeerManager.playHaptic(style: .heavy)
                        multipeerManager.startGame()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                            
                            Text("Turnuvayı Başlat")
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
                    // Yetersiz oyuncu mesajı (host için)
                    VStack(spacing: 8) {
                        Text("👑 En az 2 oyuncu gerekli")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Daha fazla oyuncunun katılmasını bekleyin")
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
            } else {
                // Host olmayan oyuncular için bekleme mesajı
                VStack(spacing: 8) {
                    Text("⏳ Host'un turnuvayı başlatmasını bekliyor...")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Text("Hazır olduğunda turnuva başlayacak")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                        )
                )
            }
        }
    }
}

// MARK: - Player Row View
struct PlayerRowView: View {
    let player: Player
    let isHost: Bool
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Oyuncu avatarı
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                isCurrentUser ? Color.blue.opacity(0.4) : Color.white.opacity(0.3),
                                isCurrentUser ? Color.blue.opacity(0.2) : Color.white.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 55, height: 55)
                    .overlay(
                        Circle()
                            .stroke(isCurrentUser ? Color.blue : Color.white.opacity(0.5), lineWidth: 2)
                    )
                
                Text(player.avatar)
                    .font(.system(size: 28))
                
                // Host crown
                if isHost {
                    Text("👑")
                        .font(.system(size: 16))
                        .offset(x: 16, y: -16)
                }
            }
            
            // Oyuncu bilgileri
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(player.displayName)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if isCurrentUser {
                        Text("(Sen)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue.opacity(0.8))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.2))
                            )
                    }
                }
                
                HStack(spacing: 6) {
                    Image(systemName: isHost ? "crown.fill" : "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(isHost ? .yellow : .green.opacity(0.8))
                    
                    Text(isHost ? "Oda Host'u" : "Hazır")
                        .font(.caption)
                        .foregroundColor(isHost ? .yellow.opacity(0.9) : .green.opacity(0.8))
                }
            }
            
            Spacer()
            
            // Bağlantı durumu
            Image(systemName: "wifi.circle.fill")
                .font(.title3)
                .foregroundColor(.green.opacity(0.8))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            isCurrentUser ? Color.blue.opacity(0.2) : Color.white.opacity(0.1),
                            isCurrentUser ? Color.blue.opacity(0.1) : Color.white.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isCurrentUser ? Color.blue.opacity(0.3) : Color.white.opacity(0.2),
                            lineWidth: 1
                        )
                )
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
