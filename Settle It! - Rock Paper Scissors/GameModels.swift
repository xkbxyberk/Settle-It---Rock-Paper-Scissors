import Foundation

// MARK: - Player Model
/// Oyundaki bir oyuncuyu temsil eden yapı
struct Player: Identifiable, Hashable, Codable {
    let id: UUID = UUID() // Her oyuncu için eşsiz bir kimlik
    let displayName: String // Cihazın adı veya kullanıcının girdiği isim
    
    // MARK: - Codable Implementation
    /// Sadece displayName'i encode/decode et, id her cihazda unique olarak oluşturulsun
    enum CodingKeys: String, CodingKey {
        case displayName
    }
    
    /// Custom initializer for decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        displayName = try container.decode(String.self, forKey: .displayName)
        // id otomatik olarak UUID() ile oluşturulur
    }
    
    /// Manual initializer
    init(displayName: String) {
        self.displayName = displayName
        // id otomatik olarak UUID() ile oluşturulur
    }
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

// MARK: - Connection Type
/// Bağlantı türlerini tanımlayan enum
enum ConnectionType: String, CaseIterable, Codable {
    case wifiOnly = "Sadece Wi-Fi"
    case bluetoothOnly = "Sadece Bluetooth"
    case both = "Wi-Fi + Bluetooth"
}

// MARK: - Game Settings
/// Oyun ayarlarını tutan yapı
struct GameSettings: Codable {
    var connectionType: ConnectionType = .both
    var autoConnect: Bool = true
    var countdownDuration: Int = 3
    var preferredGameMode: GameMode? = nil
    var shakeSensitivity: Double = 1.5
    var soundEffects: Bool = true
    var hapticFeedback: Bool = true
    var animations: Bool = true
    
    // UserDefaults keys
    private enum Keys {
        static let connectionType = "connectionType"
        static let autoConnect = "autoConnect"
        static let countdownDuration = "countdownDuration"
        static let preferredGameMode = "preferredGameMode"
        static let shakeSensitivity = "shakeSensitivity"
        static let soundEffects = "soundEffects"
        static let hapticFeedback = "hapticFeedback"
        static let animations = "animations"
    }
    
    // Load from UserDefaults
    static func load() -> GameSettings {
        var settings = GameSettings()
        
        if let connectionTypeData = UserDefaults.standard.data(forKey: Keys.connectionType),
           let connectionType = try? JSONDecoder().decode(ConnectionType.self, from: connectionTypeData) {
            settings.connectionType = connectionType
        }
        
        if UserDefaults.standard.object(forKey: Keys.autoConnect) != nil {
            settings.autoConnect = UserDefaults.standard.bool(forKey: Keys.autoConnect)
        }
        
        if UserDefaults.standard.object(forKey: Keys.countdownDuration) != nil {
            settings.countdownDuration = UserDefaults.standard.integer(forKey: Keys.countdownDuration)
        }
        
        if let gameModeData = UserDefaults.standard.data(forKey: Keys.preferredGameMode),
           let gameMode = try? JSONDecoder().decode(GameMode.self, from: gameModeData) {
            settings.preferredGameMode = gameMode
        }
        
        if UserDefaults.standard.object(forKey: Keys.shakeSensitivity) != nil {
            settings.shakeSensitivity = UserDefaults.standard.double(forKey: Keys.shakeSensitivity)
        }
        
        if UserDefaults.standard.object(forKey: Keys.soundEffects) != nil {
            settings.soundEffects = UserDefaults.standard.bool(forKey: Keys.soundEffects)
        }
        
        if UserDefaults.standard.object(forKey: Keys.hapticFeedback) != nil {
            settings.hapticFeedback = UserDefaults.standard.bool(forKey: Keys.hapticFeedback)
        }
        
        if UserDefaults.standard.object(forKey: Keys.animations) != nil {
            settings.animations = UserDefaults.standard.bool(forKey: Keys.animations)
        }
        
        return settings
    }
    
    // Save to UserDefaults
    func save() {
        if let connectionTypeData = try? JSONEncoder().encode(connectionType) {
            UserDefaults.standard.set(connectionTypeData, forKey: Keys.connectionType)
        }
        
        UserDefaults.standard.set(autoConnect, forKey: Keys.autoConnect)
        UserDefaults.standard.set(countdownDuration, forKey: Keys.countdownDuration)
        
        if let preferredGameMode = preferredGameMode,
           let gameModeData = try? JSONEncoder().encode(preferredGameMode) {
            UserDefaults.standard.set(gameModeData, forKey: Keys.preferredGameMode)
        } else {
            UserDefaults.standard.removeObject(forKey: Keys.preferredGameMode)
        }
        
        UserDefaults.standard.set(shakeSensitivity, forKey: Keys.shakeSensitivity)
        UserDefaults.standard.set(soundEffects, forKey: Keys.soundEffects)
        UserDefaults.standard.set(hapticFeedback, forKey: Keys.hapticFeedback)
        UserDefaults.standard.set(animations, forKey: Keys.animations)
    }
    
    // Reset to defaults
    mutating func reset() {
        self = GameSettings()
        save()
    }
}
