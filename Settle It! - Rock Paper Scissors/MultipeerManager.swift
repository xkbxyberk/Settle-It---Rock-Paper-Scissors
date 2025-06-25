import Foundation
import MultipeerConnectivity
import CoreMotion
import CoreHaptics

// MARK: - MultipeerManager
/// Ağ iletişimini yöneten ana sınıf
/// Peer-to-peer mimaride tüm cihazlar arası iletişimi koordine eder
class MultipeerManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    /// Oyunun merkezi durumu - UI değişiklikleri için reaktif
    @Published var gameState = GameState()
    
    /// Bağlantı kopması bildirimi için
    @Published var connectionAlert: ConnectionAlert?
    
    /// Oyun ayarları
    @Published var settings = GameSettings.load() {
        didSet {
            settings.save()
            // Host ise ayarları diğer oyunculara gönder
            if isHost {
                sendHostSettings()
            }
            print("⚙️ Ayarlar güncellendi")
        }
    }
    
    // MARK: - Private Properties
    /// Kullanıcı profili
    private var userProfile = UserProfile.load()
    
    /// Bu cihazın host olup olmadığını belirler
    var isHost: Bool {
        return gameState.hostDeviceID == userProfile.deviceID
    }
    
    // MARK: - MultipeerConnectivity Properties
    /// Bu cihazın benzersiz kimliği
    private let peerID: MCPeerID
    
    /// Cihazlar arası iletişim oturumu
    private let session: MCSession
    
    /// Yakındaki cihazlara kendini duyuran servis
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    
    /// Yakındaki cihazları arayan servis
    private let serviceBrowser: MCNearbyServiceBrowser
    
    /// Servis türü - tüm cihazlarda aynı olmalı
    private let serviceType = "rps-tournament"
    
    // MARK: - Core Motion Properties
    /// Hareket algılama yöneticisi
    private let motionManager = CMMotionManager()
    
    // MARK: - CoreHaptics Properties
    /// Haptic feedback engine
    private var hapticEngine: CHHapticEngine?
    
    // MARK: - Initialization
    override init() {
        // Cihaz adını kullanarak peer ID oluştur
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        
        // Session'ı güvenlik ayarları ile başlat
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        
        // Advertiser'ı başlat (kendini duyur)
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        
        // Browser'ı başlat (diğerlerini ara)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        
        super.init()
        
        // Delegate'leri ayarla
        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self
        
        // Haptic engine'i başlat
        setupHapticEngine()
        
        // Ayarları uygula
        applySettings()
        
        print("✅ MultipeerManager başlatıldı: \(userProfile.nickname) (\(userProfile.deviceID))")
    }
    
    // MARK: - User Profile Management
    /// Kullanıcı profilini günceller
    func updateUserProfile(_ profile: UserProfile) {
        userProfile = profile
        userProfile.save()
        
        // Eğer oyunda varsa, oyuncu bilgilerini güncelle
        updatePlayerInGameState()
        
        print("👤 Kullanıcı profili güncellendi: \(profile.nickname)")
    }
    
    /// Mevcut kullanıcının Player nesnesini döndürür
    func getCurrentPlayer() -> Player {
        return userProfile.toPlayer()
    }
    
    /// Mevcut kullanıcının cihaz ID'sini döndürür
    func getCurrentUserDeviceID() -> String {
        return userProfile.deviceID
    }
    
    /// GameState'deki oyuncu bilgilerini günceller
    private func updatePlayerInGameState() {
        let currentPlayer = getCurrentPlayer()
        
        // Players listesinde güncelle
        if let index = gameState.players.firstIndex(where: { $0.deviceID == userProfile.deviceID }) {
            gameState.players[index] = currentPlayer
        }
        
        // Active players listesinde güncelle
        if let index = gameState.activePlayers.firstIndex(where: { $0.deviceID == userProfile.deviceID }) {
            gameState.activePlayers[index] = currentPlayer
        }
        
        // Diğer oyunculara bildir
        let message = NetworkMessage.playerJoined(player: currentPlayer)
        send(message: message)
    }
    
    // MARK: - Room Management
    /// Yeni oda oluşturur ve host olur
    func createRoom(name: String) {
        let room = GameRoom(hostDeviceID: userProfile.deviceID, roomName: name)
        
        gameState.currentRoom = room
        gameState.hostDeviceID = userProfile.deviceID
        
        // Kendi oyuncuyu ekle
        let currentPlayer = getCurrentPlayer()
        gameState.players = [currentPlayer]
        gameState.activePlayers = [currentPlayer]
        
        // Başarılı oda oluşturma haptic feedback
        playHaptic(style: .success)
        
        // Servisleri başlat
        if settings.autoConnect {
            startAdvertising()
            startBrowsing()
        }
        
        print("🏠 Oda oluşturuldu: \(name) (Kod: \(room.roomCode), Host: \(userProfile.nickname))")
    }
    
    /// Oda kodunu kullanarak odaya katılmaya çalışır
    func joinRoom(withCode code: String) {
        print("🔑 Oda kodu ile katılma isteği: \(code)")
        
        // Servisleri başlat (oda arama için)
        if settings.autoConnect {
            startAdvertising()
            startBrowsing()
        }
        
        // Tüm bağlı cihazlara oda kodu gönder
        let message = NetworkMessage.roomCodeRequest(code: code)
        send(message: message)
        
        // Eğer hiç bağlı cihaz yoksa hata göster
        if session.connectedPeers.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if self.gameState.currentRoom == nil {
                    self.connectionAlert = ConnectionAlert(
                        title: "Oda Bulunamadı",
                        message: "Bu koda sahip oda bulunamadı. Kodun doğru olduğundan emin ol."
                    )
                }
            }
        }
    }
    
    /// Odaya katılır
    func joinRoom(_ room: GameRoom) {
        gameState.currentRoom = room
        gameState.hostDeviceID = room.hostDeviceID
        
        // Kendi oyuncuyu ekle
        let currentPlayer = getCurrentPlayer()
        if !gameState.players.contains(where: { $0.deviceID == currentPlayer.deviceID }) {
            gameState.players.append(currentPlayer)
            gameState.activePlayers.append(currentPlayer)
        }
        
        // Odaya katılım haptic feedback
        playHaptic(style: .success)
        
        print("🚪 Odaya katıldı: \(room.roomName) (Kod: \(room.roomCode))")
    }
    
    // MARK: - Settings Management
    /// Ayarları uygular
    private func applySettings() {
        print("⚙️ Ayarlar uygulanıyor...")
        print("✅ Ayarlar uygulandı")
    }
    
    /// Ayarları varsayılana sıfırlar
    func resetSettings() {
        print("🔄 Ayarlar sıfırlanıyor...")
        settings.reset()
        settings = GameSettings.load()
        print("✅ Ayarlar sıfırlandı")
    }
    
    /// Host ayarlarını diğer oyunculara gönderir
    private func sendHostSettings() {
        guard isHost else { return }
        
        let hostSettings = HostGameSettings(from: settings)
        let message = NetworkMessage.gameSettings(settings: hostSettings)
        send(message: message)
        
        print("👑 Host ayarları gönderildi")
    }
    
    /// Haptic feedback çalar (ayarlarda açıksa)
    func playHaptic(style: HapticStyle = .medium) {
        guard settings.hapticFeedback else { return }
        
        // CoreHaptics kullan
        if hapticEngine != nil {
            playAdvancedHaptic(style: style)
        } else {
            // Fallback: UIImpactFeedbackGenerator
            let intensity: UIImpactFeedbackGenerator.FeedbackStyle
            switch style {
            case .light: intensity = .light
            case .medium: intensity = .medium
            case .heavy: intensity = .heavy
            case .success: intensity = .medium
            case .warning: intensity = .heavy
            case .error: intensity = .heavy
            }
            
            let impactFeedback = UIImpactFeedbackGenerator(style: intensity)
            impactFeedback.impactOccurred()
        }
    }
    
    /// CoreHaptics ile gelişmiş haptic feedback
    private func playAdvancedHaptic(style: HapticStyle) {
        guard let hapticEngine = hapticEngine else { return }
        
        var events: [CHHapticEvent] = []
        
        switch style {
        case .light:
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            ], relativeTime: 0)
            events.append(event)
            
        case .medium:
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ], relativeTime: 0)
            events.append(event)
            
        case .heavy:
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            ], relativeTime: 0)
            events.append(event)
            
        case .success:
            // Çifte titreşim (başarı için)
            let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            ], relativeTime: 0)
            
            let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ], relativeTime: 0.1)
            
            events.append(contentsOf: [event1, event2])
            
        case .warning:
            // Uzun titreşim (uyarı için)
            let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
            ], relativeTime: 0, duration: 0.3)
            events.append(event)
            
        case .error:
            // Üçlü sert titreşim (hata için)
            for i in 0..<3 {
                let event = CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                ], relativeTime: Double(i) * 0.1)
                events.append(event)
            }
        }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try hapticEngine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("❌ Haptic feedback hatası: \(error.localizedDescription)")
        }
    }
    
    /// Haptic engine'i kurar
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("⚠️ Bu cihaz haptic feedback desteklemiyor")
            return
        }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            print("✅ Haptic engine başlatıldı")
        } catch {
            print("❌ Haptic engine başlatılamadı: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Service Management
    /// Advertiser servisini başlatır (kendini duyurur)
    private func startAdvertising() {
        serviceAdvertiser.startAdvertisingPeer()
        print("🔊 Advertiser başlatıldı: \(userProfile.nickname)")
    }
    
    /// Browser servisini başlatır (diğerlerini arar)
    private func startBrowsing() {
        serviceBrowser.startBrowsingForPeers()
        print("🔍 Browser başlatıldı: \(userProfile.nickname)")
    }
    
    /// Tüm servisleri durdurur
    func stopServices() {
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
        session.disconnect()
        stopMotionDetection() // Hareket algılamayı da durdur
        print("⏹️ Tüm servisler durduruldu")
    }
    
    // MARK: - Message Sending
    /// NetworkMessage'ı tüm bağlı cihazlara gönderir
    func send(message: NetworkMessage) {
        guard !session.connectedPeers.isEmpty else {
            print("⚠️ Gönderilecek bağlı cihaz yok")
            return
        }
        
        do {
            // Mesajı Data formatına çevir
            let data = try JSONEncoder().encode(message)
            
            // Tüm bağlı cihazlara gönder
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            
            // Debug output için message türünü kontrol et
            switch message {
            case .vote(let mode):
                print("📤 Oy gönderildi: \(mode.rawValue)")
            case .choice(let selection):
                print("📤 Seçim gönderildi: \(selection.rawValue)")
            case .playerJoined(let player):
                print("📤 Oyuncu katıldı mesajı: \(player.displayName)")
            case .playerLeft(let deviceID):
                print("📤 Oyuncu ayrıldı mesajı: \(deviceID)")
            case .roomCreated(let room):
                print("📤 Oda oluşturuldu mesajı: \(room.roomName)")
            case .gameSettings(_):
                print("📤 Host ayarları gönderildi")
            case .startGame:
                print("📤 Oyun başlatma komutu gönderildi")
            case .syncGameState(_):
                print("📤 Oyun durumu senkronize edildi")
            case .roomCodeRequest(let code):
                print("📤 Oda kodu isteği gönderildi: \(code)")
            case .roomCodeResponse(_, let success):
                print("📤 Oda kodu yanıtı gönderildi: \(success)")
            case .requestRoomInfo:
                print("📤 Oda bilgisi istendi")
            }
        } catch {
            print("❌ Mesaj gönderme hatası: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Game Control Methods
    /// Oyunu başlatır ve oylama aşamasına geçer (Sadece host çağırabilir)
    func startGame() {
        guard isHost else {
            print("⚠️ Sadece host oyunu başlatabilir")
            playHaptic(style: .error)
            return
        }
        
        guard gameState.players.count >= 2 else {
            print("⚠️ Oyun başlatılamadı: Yetersiz oyuncu sayısı (\(gameState.players.count))")
            playHaptic(style: .warning)
            return
        }
        
        print("🎮 Oyun başlatılıyor (Host: \(userProfile.nickname))")
        
        // Başarılı oyun başlatma haptic feedback
        playHaptic(style: .success)
        
        // Eğer tercih edilen mod varsa, doğrudan geri sayıma geç
        if let preferredMode = settings.preferredGameMode {
            print("🎯 Tercih edilen mod kullanılıyor: \(preferredMode.rawValue)")
            gameState.gameMode = preferredMode
            gameState.gamePhase = .geriSayim
        } else {
            print("🗳️ Oylama aşamasına geçiliyor")
            gameState.gamePhase = .oylama
        }
        
        // Active players listesini players listesi ile senkronize et
        gameState.activePlayers = gameState.players
        
        // Votes ve choices'ları temizle (önceki oyundan kalmış olabilir)
        gameState.votes.removeAll()
        gameState.choices.removeAll()
        
        // Round sayısını sıfırla
        gameState.currentRound = 0
        
        // Diğer oyunculara oyun başlatma mesajı gönder
        let message = NetworkMessage.startGame
        send(message: message)
        
        // Game state'i senkronize et
        syncGameState()
    }
    
    /// Oyun durumunu tüm oyunculara gönderir
    private func syncGameState() {
        let message = NetworkMessage.syncGameState(state: gameState)
        send(message: message)
    }
    
    /// Oy verme fonksiyonu
    func castVote(mode: GameMode) {
        let currentDeviceID = userProfile.deviceID
        
        // Daha önce oy verilmiş mi kontrol et
        guard gameState.votes[currentDeviceID] == nil else {
            print("⚠️ \(userProfile.nickname) zaten oy vermiş")
            playHaptic(style: .warning)
            return
        }
        
        print("🗳️ \(userProfile.nickname) oyunu: \(mode.rawValue)")
        
        // Başarılı oy haptic feedback
        playHaptic(style: .success)
        
        // Kendi oyunu yerel olarak ekle
        gameState.votes[currentDeviceID] = mode
        
        // Ağ üzerinden diğer cihazlara gönder
        let voteMessage = NetworkMessage.vote(mode: mode)
        send(message: voteMessage)
        
        // Oylama tamamlandı mı kontrol et
        if isHost {
            checkVotingCompletion()
        }
    }
    
    /// Oylamanın tamamlanıp tamamlanmadığını kontrol eder (Sadece host)
    private func checkVotingCompletion() {
        guard isHost else { return }
        
        guard gameState.votes.count == gameState.players.count else {
            print("🗳️ Oylama devam ediyor: \(gameState.votes.count)/\(gameState.players.count)")
            return
        }
        
        print("✅ Oylama tamamlandı - Oylar sayılıyor")
        calculateVotes()
    }
    
    /// Oyları sayma algoritması - Teknik analizde belirtilen mantık
    private func calculateVotes() {
        let votes = Array(gameState.votes.values)
        
        // Her modun kaç oy aldığını say
        let dokunmaVotes = votes.filter { $0 == .dokunma }.count
        let sallamaVotes = votes.filter { $0 == .sallama }.count
        
        print("📊 Oy dağılımı - Dokunma: \(dokunmaVotes), Sallama: \(sallamaVotes)")
        
        // Kazanan modu belirle
        let winningMode: GameMode
        
        if dokunmaVotes > sallamaVotes {
            winningMode = .dokunma
        } else if sallamaVotes > dokunmaVotes {
            winningMode = .sallama
        } else {
            // Beraberlik durumunda rastgele seçim
            winningMode = [GameMode.dokunma, .sallama].randomElement()!
            print("⚖️ Beraberlik! Rastgele seçilen mod: \(winningMode.rawValue)")
        }
        
        // Sonuçları uygula
        gameState.gameMode = winningMode
        gameState.gamePhase = .geriSayim
        
        // Oylama tamamlanma haptic feedback
        playHaptic(style: .success)
        
        print("🏆 Kazanan mod: \(winningMode.rawValue)")
        print("⏰ Geri sayım aşamasına geçildi")
        
        // Game state'i senkronize et
        syncGameState()
    }
    
    /// Turu başlatır - gamePhase'i .turOynaniyor olarak değiştirir
    func startRound() {
        guard isHost else { return }
        
        print("🎯 Tur başlatılıyor - Oyuncular seçim yapabilir")
        
        // Tur başlama haptic feedback
        playHaptic(style: .medium)
        
        // Tur sayısını artır
        gameState.currentRound += 1
        
        // Oyun aşamasını tur oynama olarak değiştir
        gameState.gamePhase = .turOynaniyor
        
        // Choices'ları temizle (yeni tur için)
        gameState.choices.removeAll()
        
        // Game state'i senkronize et
        syncGameState()
        
        // Eğer sallama modu aktifse, hareket algılamayı başlat
        if gameState.gameMode == .sallama {
            startMotionDetection()
        }
    }
    
    /// Seçim yapma fonksiyonu
    func makeChoice(choice: Choice) {
        let currentDeviceID = userProfile.deviceID
        
        // Daha önce seçim yapılmış mı kontrol et
        guard gameState.choices[currentDeviceID] == nil else {
            print("⚠️ \(userProfile.nickname) zaten seçim yapmış")
            playHaptic(style: .warning)
            return
        }
        
        // Oyuncunun active players listesinde olup olmadığını kontrol et
        guard gameState.activePlayers.contains(where: { $0.deviceID == currentDeviceID }) else {
            print("⚠️ \(userProfile.nickname) aktif oyuncu değil")
            playHaptic(style: .error)
            return
        }
        
        print("✂️ \(userProfile.nickname) seçimi: \(choice.rawValue)")
        
        // Başarılı seçim haptic feedback
        playHaptic(style: .success)
        
        // Kendi seçimini yerel olarak ekle
        gameState.choices[currentDeviceID] = choice
        
        // Ağ üzerinden diğer cihazlara gönder
        let choiceMessage = NetworkMessage.choice(selection: choice)
        send(message: choiceMessage)
        
        // Tur tamamlandı mı kontrol et (sadece host)
        if isHost {
            checkRoundCompletion()
        }
    }
    
    /// Turun tamamlanıp tamamlanmadığını kontrol eder (Sadece host)
    private func checkRoundCompletion() {
        guard isHost else { return }
        
        guard gameState.choices.count == gameState.activePlayers.count else {
            print("✂️ Tur devam ediyor: \(gameState.choices.count)/\(gameState.activePlayers.count)")
            return
        }
        
        print("✅ Tur tamamlandı - Sonuçlar hesaplanıyor")
        
        // Hareket algılamayı durdur (pil tasarrufu için)
        stopMotionDetection()
        
        // Tur sonuçlarını işle ve elemeleri hesapla
        processRoundResults()
    }
    
    /// Tur sonuçlarını işler ve eleme algoritmasını çalıştırır (Sadece host)
    private func processRoundResults() {
        guard isHost else { return }
        
        print("🧮 Eleme algoritması çalıştırılıyor...")
        
        // Sadece aktif oyuncuların seçimlerini al
        let activePlayerChoices = gameState.choices.filter { choice in
            gameState.activePlayers.contains { $0.deviceID == choice.key }
        }
        
        // Teknik analizde belirtilen eleme algoritması
        let eliminationResult = calculateEliminations(choices: activePlayerChoices)
        
        // Sonuçları uygula
        let eliminatedPlayers = eliminationResult.eliminated
        let continuingPlayers = eliminationResult.continuing
        
        // Güncellemeleri uygula
        gameState.activePlayers = continuingPlayers
        
        // Debug bilgileri
        print("📊 Tur \(gameState.currentRound) Sonuçları:")
        print("   Toplam aktif oyuncu: \(activePlayerChoices.count)")
        print("   Elenen oyuncu sayısı: \(eliminatedPlayers.count)")
        print("   Devam eden oyuncu sayısı: \(continuingPlayers.count)")
        
        if !eliminatedPlayers.isEmpty {
            print("   Elenenler: \(eliminatedPlayers.map { $0.displayName }.joined(separator: ", "))")
        }
        
        // Oyun sonuç aşamasına geç
        gameState.gamePhase = .sonucGosteriliyor
        
        // Tur sonucu haptic feedback
        if eliminatedPlayers.isEmpty {
            playHaptic(style: .light) // Kimse elenmedi
        } else {
            playHaptic(style: .warning) // Eliminasyon var
        }
        
        // Game state'i senkronize et
        syncGameState()
        
        // 3 saniye sonra sonraki adıma geç
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.proceedToNextPhase()
        }
    }
    
    /// Sonraki aşamaya geçer (yeni tur veya oyun sonu) (Sadece host)
    private func proceedToNextPhase() {
        guard isHost else { return }
        
        print("🔄 Sonraki aşamaya geçiliyor...")
        
        if gameState.activePlayers.count > 1 {
            // Oyun devam ediyor - yeni tur başlat
            print("🎯 Yeni tur başlatılıyor (Tur \(gameState.currentRound + 1))")
            
            // Tur verilerini temizle
            gameState.choices.removeAll()
            gameState.votes.removeAll()
            
            // Yeni tura geç
            gameState.gamePhase = .geriSayim
            
        } else {
            // Oyun bitti
            print("🏆 Oyun tamamlandı!")
            gameState.gamePhase = .oyunBitti
            
            // Oyun bitişi haptic feedback
            playHaptic(style: .success)
            
            if let winner = gameState.activePlayers.first {
                print("🥇 Kazanan: \(winner.displayName)")
            } else {
                print("🤷‍♂️ Kazanan yok")
            }
        }
        
        // Game state'i senkronize et
        syncGameState()
    }
    
    /// Oyunu sıfırlar ve ana menüye döner
    func resetGame() {
        print("🔄 Oyun sıfırlanıyor ve ana menüye dönülüyor...")
        
        // Hareket algılamayı durdur
        stopMotionDetection()
        
        // Tüm servisleri durdur
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
        session.disconnect()
        
        // GameState'i tamamen sıfırla
        gameState = GameState()
        
        // Alert'i temizle
        connectionAlert = nil
        
        print("✅ Oyun sıfırlandı - Ana menüye dönüldü")
    }
    
    /// Oyunu yeniden başlatır (ana menüden geri gelirken)
    func restartServices() {
        print("🔄 Servisler yeniden başlatılıyor...")
        
        // Servisleri yeniden başlat
        if settings.autoConnect {
            startAdvertising()
            startBrowsing()
        }
        
        print("✅ Servisler aktif, lobi hazır")
    }
    
    /// Teknik analizde belirtilen eleme algoritması
    private func calculateEliminations(choices: [String: Choice]) -> (eliminated: [Player], continuing: [Player]) {
        
        // 1. Farklı seçimleri bul
        let uniqueChoices = Set(choices.values)
        let uniqueChoiceCount = uniqueChoices.count
        
        print("🎯 Farklı seçim sayısı: \(uniqueChoiceCount)")
        print("🎯 Seçimler: \(uniqueChoices.map { $0.rawValue }.joined(separator: ", "))")
        
        // 2. Eleme kurallarını uygula
        switch uniqueChoiceCount {
        case 1:
            // Herkes aynı seçimi yapmış - kimse elenmez
            print("🤝 Herkes aynı seçimi yapmış - kimse elenmez")
            return (eliminated: [], continuing: gameState.activePlayers)
            
        case 3:
            // Üç farklı seçim var - kimse elenmez
            print("🎲 Üç farklı seçim var - kimse elenmez")
            return (eliminated: [], continuing: gameState.activePlayers)
            
        case 2:
            // İki farklı seçim var - kazanan ve kaybedenler belirlenir
            let choicesArray = Array(uniqueChoices)
            let choice1 = choicesArray[0]
            let choice2 = choicesArray[1]
            
            let winningChoice = determineWinner(choice1: choice1, choice2: choice2)
            let losingChoice = winningChoice == choice1 ? choice2 : choice1
            
            print("🏆 Kazanan seçim: \(winningChoice.rawValue)")
            print("❌ Kaybeden seçim: \(losingChoice.rawValue)")
            
            // Oyuncuları kazanan ve kaybeden gruplara ayır
            var eliminatedPlayers: [Player] = []
            var continuingPlayers: [Player] = []
            
            for player in gameState.activePlayers {
                if let playerChoice = choices[player.deviceID] {
                    if playerChoice == losingChoice {
                        eliminatedPlayers.append(player)
                    } else {
                        continuingPlayers.append(player)
                    }
                } else {
                    // Seçim yapmamış oyuncu (teorik olarak olmayacak ama güvenlik için)
                    continuingPlayers.append(player)
                }
            }
            
            return (eliminated: eliminatedPlayers, continuing: continuingPlayers)
            
        default:
            // Teorik olarak buraya gelmeyecek
            print("⚠️ Beklenmeyen seçim sayısı: \(uniqueChoiceCount)")
            return (eliminated: [], continuing: gameState.activePlayers)
        }
    }
    
    /// İki seçim arasında kazananı belirler (Taş-Kağıt-Makas kuralları)
    private func determineWinner(choice1: Choice, choice2: Choice) -> Choice {
        switch (choice1, choice2) {
        case (.tas, .makas):
            return .tas // Taş makası yener
        case (.makas, .tas):
            return .tas // Taş makası yener
            
        case (.makas, .kagit):
            return .makas // Makas kağıdı yener
        case (.kagit, .makas):
            return .makas // Makas kağıdı yener
            
        case (.kagit, .tas):
            return .kagit // Kağıt taşı yener
        case (.tas, .kagit):
            return .kagit // Kağıt taşı yener
            
        default:
            // Aynı seçimler (teorik olarak buraya gelmeyecek çünkü unique choices kontrolü var)
            return choice1
        }
    }
    
    // MARK: - Motion Detection Methods
    /// Hareket algılamayı başlatır (sallama modu için)
    func startMotionDetection() {
        // Accelerometer mevcut mu kontrol et
        guard motionManager.isAccelerometerAvailable else {
            print("⚠️ Accelerometer bu cihazda mevcut değil")
            return
        }
        
        print("📱 Sallama algılama başlatıldı")
        
        // Update interval'ını ayarla (0.2 saniye = 5 Hz)
        motionManager.accelerometerUpdateInterval = 0.2
        
        // Accelerometer güncellemelerini başlat
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                print("❌ Accelerometer hatası: \(error?.localizedDescription ?? "Bilinmeyen hata")")
                return
            }
            
            // Sallama tespiti - kullanıcının hassasiyet ayarını kullan
            let acceleration = data.acceleration
            let threshold = self.settings.shakeSensitivity
            let isShaking = abs(acceleration.x) > threshold ||
                           abs(acceleration.y) > threshold ||
                           abs(acceleration.z) > threshold
            
            if isShaking {
                print("🔄 Sallama tespit edildi! (threshold: \(threshold))")
                
                // Sallama haptic feedback
                self.playHaptic(style: .medium)
                
                // Tekrar algılamayı önlemek için hemen durdur
                self.stopMotionDetection()
                
                // Rastgele seçim yap
                let randomChoice = [Choice.tas, .kagit, .makas].randomElement()!
                print("🎲 Rastgele seçim: \(randomChoice.rawValue)")
                
                // Seçimi oyuna kaydet ve ağa gönder
                self.makeChoice(choice: randomChoice)
            }
        }
    }
    
    /// Hareket algılamayı durdurur
    func stopMotionDetection() {
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
            print("⏹️ Sallama algılama durduruldu")
        }
    }
    
    // MARK: - Helper Methods
    /// PeerID'den Player nesnesi bulur
    private func findPlayer(by peerID: MCPeerID) -> Player? {
        return gameState.players.first { $0.deviceID == peerID.displayName }
    }
    
    /// Oyuncuyu gameState'den güvenli şekilde kaldırır
    private func removePlayer(by peerID: MCPeerID) {
        let deviceID = peerID.displayName
        
        // Players listesinden kaldır
        gameState.players.removeAll { $0.deviceID == deviceID }
        
        // Active players listesinden kaldır
        gameState.activePlayers.removeAll { $0.deviceID == deviceID }
        
        // Votes ve choices'lardan kaldır
        gameState.votes.removeValue(forKey: deviceID)
        gameState.choices.removeValue(forKey: deviceID)
        
        print("🚫 Oyuncu kaldırıldı: \(deviceID)")
    }
}

// MARK: - MCSessionDelegate
extension MultipeerManager: MCSessionDelegate {
    
    /// Peer bağlantı durumu değiştiğinde çağrılır
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("✅ Cihaz bağlandı: \(peerID.displayName)")
                
                // Eğer host ise, mevcut oyun durumunu yeni oyuncuya gönder
                if self.isHost && self.gameState.currentRoom != nil {
                    self.syncGameState()
                    self.sendHostSettings()
                }
                
            case .notConnected:
                print("❌ Cihaz bağlantısı koptu: \(peerID.displayName)")
                
                // Bağlantı kopma haptic feedback
                self.playHaptic(style: .error)
                
                // Kullanıcıya bildirim göster
                if let player = self.findPlayer(by: peerID) {
                    self.connectionAlert = ConnectionAlert(
                        title: "Bağlantı Koptu",
                        message: "\(player.displayName) oyundan ayrıldı ve elendi."
                    )
                }
                
                // Oyuncuyu kaldır
                self.removePlayer(by: peerID)
                
                // Oyunun kilitlenmesini önlemek için kontroller
                self.handlePlayerDisconnection()
                
            case .connecting:
                print("🔄 Bağlanıyor: \(peerID.displayName)")
                
            @unknown default:
                print("⚠️ Bilinmeyen bağlantı durumu: \(peerID.displayName)")
            }
        }
    }
    
    /// Oyuncu bağlantısı koptuğunda oyunun devamını sağlar
    private func handlePlayerDisconnection() {
        // Host checks
        guard isHost else { return }
        
        // Eğer oylama aşamasındaysak ve tüm kalan oyuncular oy verdiyse
        if gameState.gamePhase == .oylama && gameState.votes.count == gameState.players.count {
            print("🗳️ Oyuncu kopmasına rağmen oylama tamamlandı")
            calculateVotes()
        }
        
        // Eğer tur oynama aşamasındaysak ve tüm kalan aktif oyuncular seçim yaptıysa
        if gameState.gamePhase == .turOynaniyor && gameState.choices.count == gameState.activePlayers.count {
            print("✂️ Oyuncu kopmasına rağmen tur tamamlandı")
            checkRoundCompletion()
        }
        
        // Eğer çok az oyuncu kaldıysa oyunu bitir
        if gameState.players.count < 2 {
            print("⚠️ Yetersiz oyuncu kaldı - Oyun sonlandırılıyor")
            playHaptic(style: .error)
            gameState.gamePhase = .oyunBitti
            syncGameState()
        }
    }
    
    /// Veri alındığında çağrılır
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            // Gelen veriyi NetworkMessage'a decode et
            let message = try JSONDecoder().decode(NetworkMessage.self, from: data)
            
            DispatchQueue.main.async {
                self.handleReceivedMessage(message, from: peerID)
            }
        } catch {
            print("❌ Veri decode hatası: \(error.localizedDescription)")
        }
    }
    
    /// Alınan mesajı işler
    private func handleReceivedMessage(_ message: NetworkMessage, from peerID: MCPeerID) {
        switch message {
        case .playerJoined(let player):
            print("👤 Oyuncu katıldı: \(player.displayName)")
            
            // Yeni oyuncu katılma haptic feedback
            playHaptic(style: .light)
            
            // Oyuncu zaten listede mi kontrol et
            if !gameState.players.contains(where: { $0.deviceID == player.deviceID }) {
                gameState.players.append(player)
                gameState.activePlayers.append(player)
            } else {
                // Oyuncu bilgilerini güncelle
                if let index = gameState.players.firstIndex(where: { $0.deviceID == player.deviceID }) {
                    gameState.players[index] = player
                }
                if let index = gameState.activePlayers.firstIndex(where: { $0.deviceID == player.deviceID }) {
                    gameState.activePlayers[index] = player
                }
            }
            
        case .playerLeft(let deviceID):
            print("👋 Oyuncu ayrıldı: \(deviceID)")
            gameState.players.removeAll { $0.deviceID == deviceID }
            gameState.activePlayers.removeAll { $0.deviceID == deviceID }
            
        case .roomCreated(let room):
            print("🏠 Oda bilgisi alındı: \(room.roomName)")
            joinRoom(room)
            
        case .gameSettings(let hostSettings):
            print("👑 Host ayarları alındı")
            // Sadece host'a ait ayarları uygula
            settings.countdownDuration = hostSettings.countdownDuration
            settings.preferredGameMode = hostSettings.preferredGameMode
            
        case .startGame:
            print("🎮 Oyun başlatma komutu alındı")
            // Host değilse game state'i bekle
            
        case .syncGameState(let state):
            print("🔄 Oyun durumu senkronize edildi")
            gameState = state
            
        case .roomCodeRequest(let code):
            print("🔑 Oda kodu isteği alındı: \(code)")
            
            // Eğer host isek ve oda kodumuz eşleşiyorsa odamızı paylaş
            if isHost, let currentRoom = gameState.currentRoom, currentRoom.roomCode == code {
                print("✅ Oda kodu eşleşti, oda bilgisi gönderiliyor")
                let response = NetworkMessage.roomCodeResponse(room: currentRoom, success: true)
                send(message: response)
            } else {
                print("❌ Oda kodu eşleşmedi")
                let response = NetworkMessage.roomCodeResponse(room: nil, success: false)
                send(message: response)
            }
            
        case .roomCodeResponse(let room, let success):
            print("🔍 Oda kodu yanıtı: \(success)")
            
            if success, let foundRoom = room {
                // Oda bulundu, katıl
                joinRoom(foundRoom)
                
                // Başarılı katılım haptic feedback
                playHaptic(style: .success)
                
                // Kendi bilgilerini host'a gönder
                let currentPlayer = getCurrentPlayer()
                let joinMessage = NetworkMessage.playerJoined(player: currentPlayer)
                send(message: joinMessage)
            } else {
                // Oda bulunamadı
                playHaptic(style: .error)
                connectionAlert = ConnectionAlert(
                    title: "Oda Bulunamadı",
                    message: "Bu koda sahip oda bulunamadı. Kodun doğru olduğundan emin ol."
                )
            }
            
        case .requestRoomInfo:
            print("📋 Oda bilgisi istendi")
            
            // Eğer host isek oda bilgimizi paylaş
            if isHost, let currentRoom = gameState.currentRoom {
                let response = NetworkMessage.roomCreated(room: currentRoom)
                send(message: response)
            }
            
        case .vote(let mode):
            print("🗳️ Oy alındı: \(mode.rawValue)")
            let deviceID = peerID.displayName
            
            guard gameState.votes[deviceID] == nil else {
                print("⚠️ \(deviceID) zaten oy vermiş")
                return
            }
            
            gameState.votes[deviceID] = mode
            
            // Host ise oylama kontrolü yap
            if isHost {
                checkVotingCompletion()
            }
            
        case .choice(let selection):
            print("✂️ Seçim alındı: \(selection.rawValue)")
            let deviceID = peerID.displayName
            
            guard gameState.choices[deviceID] == nil else {
                print("⚠️ \(deviceID) zaten seçim yapmış")
                return
            }
            
            // Oyuncunun active players listesinde olup olmadığını kontrol et
            guard gameState.activePlayers.contains(where: { $0.deviceID == deviceID }) else {
                print("⚠️ \(deviceID) aktif oyuncu değil")
                return
            }
            
            gameState.choices[deviceID] = selection
            
            // Host ise tur kontrolü yap
            if isHost {
                checkRoundCompletion()
            }
        }
    }
    
    /// Dosya alma başladığında çağrılır (kullanmıyoruz)
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Bu projede stream kullanmıyoruz
    }
    
    /// Dosya alma başladığında çağrılır (kullanmıyoruz)
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Bu projede resource transfer kullanmıyoruz
    }
    
    /// Dosya alma tamamlandığında çağrılır (kullanmıyoruz)
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Bu projede resource transfer kullanmıyoruz
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    
    /// Davet alındığında çağrılır
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("📨 Davet alındı: \(peerID.displayName)")
        
        // Otomatik olarak daveti kabul et
        invitationHandler(true, session)
        
        // Kısa bir gecikme ile bilgi paylaşımı yap
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Eğer host isek oda bilgimizi paylaş
            if self.isHost, let currentRoom = self.gameState.currentRoom {
                let roomMessage = NetworkMessage.roomCreated(room: currentRoom)
                self.send(message: roomMessage)
            }
            
            // Kendi oyuncu bilgilerini gönder
            let currentPlayer = self.getCurrentPlayer()
            let playerMessage = NetworkMessage.playerJoined(player: currentPlayer)
            self.send(message: playerMessage)
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    
    /// Peer bulunduğunda çağrılır
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("🔍 Peer bulundu: \(peerID.displayName)")
        
        // Otomatik olarak davet gönder
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    /// Peer kaybolduğunda çağrılır
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("👻 Peer kaybedildi: \(peerID.displayName)")
    }
}

// MARK: - Connection Alert
/// Bağlantı uyarı mesajı
struct ConnectionAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

// MARK: - Haptic Style
/// Haptic feedback türleri
enum HapticStyle {
    case light    // Hafif dokunuş
    case medium   // Orta dokunuş
    case heavy    // Sert dokunuş
    case success  // Başarı (çifte)
    case warning  // Uyarı (uzun)
    case error    // Hata (üçlü)
}
