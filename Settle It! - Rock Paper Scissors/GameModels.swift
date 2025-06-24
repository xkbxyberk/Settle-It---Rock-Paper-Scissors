import Foundation

// MARK: - Player Model
/// Oyundaki bir oyuncuyu temsil eden yapı
struct Player: Identifiable, Hashable, Codable {
    let id: UUID = UUID() // Her oyuncu için eşsiz bir kimlik
    let displayName: String // Cihazın adı veya kullanıcının girdiği isim
}

// MARK: - Game State
/// Oyunun anlık durumunu tutan ana yapı
/// Bu yapı her cihazda senkronize olarak tutulur
struct GameState {
    var players: [Player] = [] // Lobiye katılmış tüm oyuncular
    var activePlayers: [Player] = [] // O turda hala elenmemiş oyuncular
    
    var gamePhase: GamePhase = .lobi // Oyunun hangi aşamada olduğunu tutar
    var gameMode: GameMode? // Oylama sonucu belirlenen oyun modu
    
    // Tur bazlı veriler
    var currentRound: Int = 0
    var votes: [String: GameMode] = [:] // Kimin hangi moda oy verdiği (Player.displayName: GameMode)
    var choices: [String: Choice] = [:] // Kimin hangi seçimi yaptığı (Player.displayName: Choice)
}

// MARK: - Game Phase
/// Oyunun hangi aşamada olduğunu belirten enum
enum GamePhase {
    case lobi // Oyuncuların katılım beklediği aşama
    case oylama // Oyun modunun oylandığı aşama
    case geriSayim // Tur başlamadan önceki hazırlık aşaması
    case turOynaniyor // Oyuncuların seçim yaptığı aşama
    case sonucGosteriliyor // Tur sonuçlarının gösterildiği aşama
    case oyunBitti // Oyun tamamlandığında
}

// MARK: - Game Mode
/// Oynanış modlarını tanımlayan enum
enum GameMode: String, Codable {
    case dokunma = "Dokunarak Seç" // Ekrana dokunarak seçim yapma modu
    case sallama = "Sallayarak Oyna" // Cihazı sallayarak seçim yapma modu
}

// MARK: - Choice
/// Oyuncu seçimlerini tanımlayan enum (Taş, Kağıt, Makas)
enum Choice: String, Codable {
    case tas = "Taş"
    case kagit = "Kağıt"
    case makas = "Makas"
}
