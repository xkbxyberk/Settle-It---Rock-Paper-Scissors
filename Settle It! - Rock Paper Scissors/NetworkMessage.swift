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
    case leaveRoom(deviceID: String) // Oyuncunun odadan ayrılması
    case hostChanged(newHostDeviceID: String) // Host değişikliği bildirimi
    case playAgainRequest(deviceID: String) // Tekrar oyna isteği
    case playAgainResponse(deviceID: String, accepted: Bool) // Tekrar oyna yanıtı
    case restartTournament // Yeni turnuva başlatma (aynı oyuncularla)
    case startTournamentStage(stage: TournamentPhase) // Turnuva aşaması başlat
    case updateTournamentScores(scores: [String: Int]) // Turnuva skorlarını güncelle
    case spectatorAction(deviceID: String, action: SpectatorAction) // İzleyici aksiyonu
    case tournamentWinner(winner: Player) // Turnuva kazananı açıkla
    case duelRoundWin(deviceID: String) // Düello turunu kazanma
}

// MARK: - Host Game Settings
/// Host'un belirleyeceği oyun ayarları (sadece host'un ayarları geçerli)
struct HostGameSettings: Codable, Equatable {
    var countdownDuration: Int = 3
    var preferredGameMode: GameMode? = nil
    var maxPlayers: Int = 8
    var eliminationRoundsCount: Int = 3
    var finalRoundsCount: Int = 3
    var duelWinCount: Int = 3
    
    init(from gameSettings: GameSettings) {
        self.countdownDuration = gameSettings.countdownDuration
        self.preferredGameMode = gameSettings.preferredGameMode
        self.eliminationRoundsCount = gameSettings.eliminationRoundsCount
        self.finalRoundsCount = gameSettings.finalRoundsCount
        self.duelWinCount = gameSettings.duelWinCount
    }
}
