import Foundation
import UIKit

// MARK: - Player Model
/// Oyundaki bir oyuncuyu temsil eden yapı
struct Player: Identifiable, Hashable, Codable, Equatable {
    let id: UUID = UUID() // Her oyuncu için eşsiz bir kimlik
    let displayName: String // Kullanıcının seçtiği nickname
    let avatar: String // Kullanıcının seçtiği avatar emoji
    let deviceID: String // Cihazın benzersiz kimliği (MultipeerConnectivity için)
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case displayName, avatar, deviceID
    }
    
    /// Custom initializer for decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        displayName = try container.decode(String.self, forKey: .displayName)
        avatar = try container.decode(String.self, forKey: .avatar)
        deviceID = try container.decode(String.self, forKey: .deviceID)
        // id otomatik olarak UUID() ile oluşturulur
    }
    
    /// Manual initializer
    init(displayName: String, avatar: String, deviceID: String) {
        self.displayName = displayName
        self.avatar = avatar
        self.deviceID = deviceID
        // id otomatik olarak UUID() ile oluşturulur
    }
}

// MARK: - Room Model
/// Oyun odasını temsil eden yapı
struct GameRoom: Codable, Equatable {
    let roomID: String
    let hostDeviceID: String
    var roomName: String
    let roomCode: String // 4 haneli rastgele kod
    var maxPlayers: Int = 8
    var isPrivate: Bool = false
    var password: String? = nil
    
    init(hostDeviceID: String, roomName: String) {
        self.roomID = UUID().uuidString
        self.hostDeviceID = hostDeviceID
        self.roomName = roomName
        self.roomCode = GameRoom.generateRoomCode()
    }
    
    // 4 haneli rastgele kod oluştur
    static func generateRoomCode() -> String {
        let digits = Array(0...9)
        var code = ""
        for _ in 0..<4 {
            code += String(digits.randomElement()!)
        }
        return code
    }
}

// MARK: - Game State
/// Oyunun anlık durumunu tutan ana yapı
/// Bu yapı her cihazda senkronize olarak tutulur
struct GameState: Codable, Equatable {
    var players: [Player] = [] // Lobiye katılmış tüm oyuncular
    var activePlayers: [Player] = [] // O turda hala elenmemiş oyuncular
    
    var gamePhase: GamePhase = .lobi // Oyunun hangi aşamada olduğunu tutar
    var gameMode: GameMode? // Oylama sonucu belirlenen oyun modu
    
    // Oda bilgileri
    var currentRoom: GameRoom? // Mevcut oda
    var hostDeviceID: String? // Host'un cihaz ID'si
    var hostSuccession: [String] = [] // Host değişim sırası (deviceID listesi) - YENİ
    
    // Tur bazlı veriler
    var currentRound: Int = 0
    var votes: [String: GameMode] = [:] // Kimin hangi moda oy verdiği (Player.deviceID: GameMode)
    var choices: [String: Choice] = [:] // Kimin hangi seçimi yaptığı (Player.deviceID: Choice)
    
    // Tekrar oyna sistemi - YENİ
    var playAgainRequests: [String: Bool] = [:] // DeviceID: Response (true/false)
    var isWaitingForPlayAgainResponses: Bool = false
}

// MARK: - Game Phase
/// Oyunun hangi aşamada olduğunu belirten enum
enum GamePhase: Codable, Equatable {
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
enum Choice: String, Codable, Equatable {
    case tas = "Taş"
    case kagit = "Kağıt"
    case makas = "Makas"
}

// MARK: - Connection Type
/// Bağlantı türlerini tanımlayan enum
enum ConnectionType: String, CaseIterable, Codable, Equatable {
    case wifiOnly = "Sadece Wi-Fi"
    case bluetoothOnly = "Sadece Bluetooth"
    case both = "Wi-Fi + Bluetooth"
    
    var icon: String {
        switch self {
        case .wifiOnly: return "wifi"
        case .bluetoothOnly: return "antenna.radiowaves.left.and.right"
        case .both: return "wifi.circle"
        }
    }
}

// MARK: - Avatar Options
/// Seçilebilir avatar emojileri
struct AvatarOptions {
    // Kategori bazında düzenlenmiş emojiler
    static let characters = [
        "🦸‍♂️", "🦸‍♀️", "🧙‍♂️", "🧙‍♀️", "🧛‍♂️", "🧛‍♀️", "🧚‍♂️", "🧚‍♀️",
        "👨‍💻", "👩‍💻", "👨‍🎨", "👩‍🎨", "👨‍🚀", "👩‍🚀", "👨‍🎤", "👩‍🎤",
        "🤴", "👸", "🥷", "👻", "🤖", "👽", "🤠", "🧑‍🦯"
    ]
    
    static let animals = [
        "🦁", "🐯", "🐻", "🐼", "🐨", "🐸", "🐵", "🦊", "🐺", "🐱",
        "🐶", "🐰", "🐹", "🐭", "🦄", "🐉", "🦕", "🦖", "🐙", "🦈",
        "🐧", "🦅", "🦉", "🐦", "🦜", "🐢", "🐍", "🦎", "🦀", "🦞"
    ]
    
    static let emotions = [
        "😎", "🤯", "🥳", "🤩", "😍", "🥰", "😄", "😆", "😂", "🤣",
        "😊", "😇", "🙃", "😜", "🤪", "😋", "🤓", "🧐", "🤭", "🤫",
        "😤", "😈", "👹", "👺", "🤡", "💀", "☠️", "👻", "👽", "🤖"
    ]
    
    static let objects = [
        "⚡️", "🔥", "💎", "👑", "🎯", "🎮", "🚀", "🌟", "💫", "⭐️",
        "🌙", "☀️", "🌈", "❄️", "⛄️", "🌪️", "🌊", "🏆", "🥇", "🏅",
        "💰", "💸", "🎪", "🎭", "🎨", "🎵", "🎶", "🎸", "🥁", "🎺"
    ]
    
    static let food = [
        "🍎", "🍌", "🍓", "🍒", "🥥", "🥝", "🍑", "🥭", "🍍", "🥑",
        "🍕", "🍔", "🌭", "🌮", "🌯", "🥙", "🧆", "🥗", "🍿", "🧊",
        "🍰", "🎂", "🧁", "🍪", "🍩", "🍫", "🍬", "🍭", "🍮", "🍯"
    ]
    
    static let sports = [
        "⚽️", "🏀", "🏈", "⚾️", "🥎", "🎾", "🏐", "🏉", "🥏", "🎱",
        "🏓", "🏸", "🏒", "🏑", "🥍", "🏏", "🥅", "⛳️", "🏹", "🎣",
        "🤿", "🥊", "🥋", "🎽", "🛹", "🛷", "⛸️", "🥌", "🎿", "⛷️"
    ]
    
    // Tüm emojileri birleştiren ana array
    static let availableAvatars = characters + animals + emotions + objects + food + sports
    
    // Kategoriler
    static let categories: [(name: String, emojis: [String], icon: String)] = [
        ("Karakterler", characters, "person.2"),
        ("Hayvanlar", animals, "pawprint"),
        ("İfadeler", emotions, "face.smiling"),
        ("Objeler", objects, "star"),
        ("Yiyecek", food, "fork.knife"),
        ("Spor", sports, "sportscourt")
    ]
    
    static func randomAvatar() -> String {
        return availableAvatars.randomElement() ?? "🎯"
    }
}

// MARK: - User Profile
/// Kullanıcı profil bilgileri
struct UserProfile: Codable, Equatable {
    var nickname: String
    var avatar: String
    var deviceID: String
    
    // UserDefaults keys
    private enum Keys {
        static let nickname = "userNickname"
        static let avatar = "userAvatar"
        static let deviceID = "userDeviceID"
    }
    
    // Load from UserDefaults
    static func load() -> UserProfile {
        let nickname = UserDefaults.standard.string(forKey: Keys.nickname) ?? "Oyuncu"
        let avatar = UserDefaults.standard.string(forKey: Keys.avatar) ?? AvatarOptions.randomAvatar()
        let deviceID = UserDefaults.standard.string(forKey: Keys.deviceID) ?? UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        
        return UserProfile(nickname: nickname, avatar: avatar, deviceID: deviceID)
    }
    
    // Save to UserDefaults
    func save() {
        UserDefaults.standard.set(nickname, forKey: Keys.nickname)
        UserDefaults.standard.set(avatar, forKey: Keys.avatar)
        UserDefaults.standard.set(deviceID, forKey: Keys.deviceID)
    }
    
    // Create Player from profile
    func toPlayer() -> Player {
        return Player(displayName: nickname, avatar: avatar, deviceID: deviceID)
    }
}

// MARK: - Game Settings
/// Oyun ayarlarını tutan yapı
struct GameSettings: Codable, Equatable {
    var connectionType: ConnectionType = .both
    var autoConnect: Bool = true
    var countdownDuration: Int = 3 // Sadece host için
    var preferredGameMode: GameMode? = nil // Sadece host için
    var shakeSensitivity: Double = 1.5 // Her kullanıcının kendi tercihi
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
