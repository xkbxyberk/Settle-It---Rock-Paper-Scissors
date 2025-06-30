import Foundation

// MARK: - Network Message
/// Cihazlar arasında gönderilecek mesajları tanımlayan ana enum
/// MultipeerConnectivity framework'ü ile Data formatına çevrilerek gönderilir
enum NetworkMessage: Codable {
    case vote(deviceID: String, mode: GameMode) // Bir oyuncunun oyun modu için oyunu - deviceID eklendi
    case choice(deviceID: String, selection: Choice) // Bir oyuncunun tur içindeki seçimi - deviceID eklendi
    case playerJoined(player: Player) // Yeni oyuncu katıldı
    case playerLeft(deviceID: String) // Oyuncu ayrıldı
    case roomCreated(room: GameRoom) // Oda oluşturuldu
    case gameSettings(settings: HostGameSettings) // Host'un oyun ayarları
    case startGame // Oyunu başlat komutu (sadece host gönderebilir)
    case syncGameState(state: GameState) // Oyun durumunu senkronize et
    case roomCodeRequest(code: String) // Oda kodu ile katılma isteği
    case roomCodeResponse(room: GameRoom?, success: Bool) // Oda bulma yanıtı
    case requestRoomInfo // Oda bilgisi isteme
}

// MARK: - Host Game Settings
/// Host'un belirleyeceği oyun ayarları (sadece host'un ayarları geçerli)
struct HostGameSettings: Codable, Equatable {
    var countdownDuration: Int = 3
    var preferredGameMode: GameMode? = nil
    var maxPlayers: Int = 8
    
    init(from gameSettings: GameSettings) {
        self.countdownDuration = gameSettings.countdownDuration
        self.preferredGameMode = gameSettings.preferredGameMode
    }
}
