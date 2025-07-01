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
    @Published var gameState = GameState() {
        didSet {
            // GameState değiştiğinde motion detection'ı kontrol et
            handleGameStateChange(from: oldValue, to: gameState)
        }
    }
    
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
    
    // MARK: - Room Search Properties (YENİ)
    /// Oda arama için timer ve deneme sayacı
    private var roomSearchTimer: Timer?
    private var roomSearchAttempts = 0
    private var maxSearchAttempts = 15 // 30 saniye (2 saniyede bir)
    private var searchingRoomCode: String?
    
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
        
        // Host succession listesini başlat (kendimiz ilk sırada)
        gameState.hostSuccession = [userProfile.deviceID]
        
        // Başarılı oda oluşturma haptic feedback
        playHaptic(style: .success)
        
        // Servisleri başlat
        if settings.autoConnect {
            startAdvertising()
            startBrowsing()
        }
        
        print("🏠 Oda oluşturuldu: \(name) (Kod: \(room.roomCode), Host: \(userProfile.nickname))")
    }
    
    /// Oda kodunu kullanarak odaya katılmaya çalışır - GELİŞTİRİLMİŞ VERSİYON
    func joinRoom(withCode code: String) {
        print("🔑 Oda kodu ile katılma isteği: \(code)")
        
        // Önceki arama varsa durdur
        stopRoomSearch()
        
        // Arama parametrelerini ayarla
        searchingRoomCode = code
        roomSearchAttempts = 0
        
        // Servisleri başlat
        if settings.autoConnect {
            startAdvertising()
            startBrowsing()
        }
        
        // İlk denemeyi hemen yap
        attemptRoomCodeRequest()
        
        // Periyodik deneme timer'ını başlat (2 saniyede bir)
        roomSearchTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.attemptRoomCodeRequest()
        }
        
        // Maksimum süre sonunda arama iptal et (30 saniye)
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(maxSearchAttempts * 2)) {
            if self.gameState.currentRoom == nil && self.searchingRoomCode == code {
                self.stopRoomSearch()
                self.connectionAlert = ConnectionAlert(
                    title: "Oda Bulunamadı",
                    message: "Bu koda sahip oda bulunamadı. Kodun doğru olduğundan ve cihazların yakın olduğundan emin ol."
                )
            }
        }
    }
    
    /// Oda kodu isteği gönderme denemesi - YENİ FONKSİYON
    private func attemptRoomCodeRequest() {
        guard let code = searchingRoomCode else { return }
        
        roomSearchAttempts += 1
        print("🔍 Oda arama denemesi \(roomSearchAttempts)/\(maxSearchAttempts) - Kod: \(code)")
        
        // Bağlı cihaz varsa mesaj gönder
        if !session.connectedPeers.isEmpty {
            let message = NetworkMessage.roomCodeRequest(code: code)
            send(message: message)
            print("📤 Oda kodu isteği gönderildi (\(session.connectedPeers.count) cihaza)")
        } else {
            print("⚠️ Henüz bağlı cihaz yok, bekleniyor...")
        }
        
        // Maksimum deneme aşılırsa durdur
        if roomSearchAttempts >= maxSearchAttempts {
            stopRoomSearch()
            connectionAlert = ConnectionAlert(
                title: "Bağlantı Sorunu",
                message: "Yakında başka cihaz bulunamadı. Wi-Fi ve Bluetooth'un açık olduğundan emin ol."
            )
        }
    }
    
    /// Oda arama işlemini durdur - YENİ FONKSİYON
    private func stopRoomSearch() {
        roomSearchTimer?.invalidate()
        roomSearchTimer = nil
        searchingRoomCode = nil
        roomSearchAttempts = 0
        print("🛑 Oda arama durduruldu")
    }
    
    /// Odaya katılır
    func joinRoom(_ room: GameRoom) {
        // Aramayı durdur - oda bulundu!
        stopRoomSearch()
        
        gameState.currentRoom = room
        gameState.hostDeviceID = room.hostDeviceID
        
        // Kendi oyuncuyu ekle
        let currentPlayer = getCurrentPlayer()
        if !gameState.players.contains(where: { $0.deviceID == currentPlayer.deviceID }) {
            gameState.players.append(currentPlayer)
            gameState.activePlayers.append(currentPlayer)
        }
        
        // Host succession listesine kendimizi ekle (eğer yoksa)
        if !gameState.hostSuccession.contains(userProfile.deviceID) {
            gameState.hostSuccession.append(userProfile.deviceID)
        }
        
        // Odaya katılım haptic feedback
        playHaptic(style: .success)
        
        print("🚪 Odaya katıldı: \(room.roomName) (Kod: \(room.roomCode))")
    }
    
    // MARK: - Room Management - YENİ FONKSİYONLAR
    
    /// Odadan ayrılır
    func leaveRoom() {
        guard gameState.currentRoom != nil else { return }
        
        let currentDeviceID = userProfile.deviceID
        
        print("🚪 Odadan ayrılıyor: \(userProfile.nickname)")
        
        if isHost {
            // Host ayrılıyorsa - Host transferi yap
            handleHostLeaving()
        } else {
            // Normal oyuncu ayrılıyorsa
            let message = NetworkMessage.leaveRoom(deviceID: currentDeviceID)
            send(message: message)
        }
        
        // Kendi durumunu temizle
        resetToMainMenu()
    }
    
    /// Host ayrıldığında yeni host seçer ve transferi yapar
    private func handleHostLeaving() {
        // Sıradaki host'u bul (kendimiz hariç)
        let remainingSuccession = gameState.hostSuccession.filter { deviceID in
            deviceID != userProfile.deviceID && gameState.players.contains { $0.deviceID == deviceID }
        }
        
        if let newHostDeviceID = remainingSuccession.first {
            // Yeni host var - transferi bildir
            print("👑 Host transferi yapılıyor: \(newHostDeviceID)")
            
            gameState.hostDeviceID = newHostDeviceID
            gameState.hostSuccession = remainingSuccession
            
            let transferMessage = NetworkMessage.hostChanged(newHostDeviceID: newHostDeviceID)
            send(message: transferMessage)
            
            // Kendi ayrılışını da bildir
            let leaveMessage = NetworkMessage.leaveRoom(deviceID: userProfile.deviceID)
            send(message: leaveMessage)
        } else {
            // Başka oyuncu yok - oda kapanıyor
            print("🏠 Oda kapanıyor - başka oyuncu yok")
            
            let leaveMessage = NetworkMessage.leaveRoom(deviceID: userProfile.deviceID)
            send(message: leaveMessage)
        }
    }
    
    /// Ana menüye güvenli dönüş
    private func resetToMainMenu() {
        print("🔄 Ana menüye dönülüyor...")
        
        // Tüm servisleri durdur (hareket algılama ve oda arama dahil)
        stopServices()
        
        // GameState'i tamamen sıfırla
        gameState = GameState()
        
        // Alert'i temizle
        connectionAlert = nil
        
        print("✅ Ana menüye dönüldü")
    }
    
    /// Host değişikliğini işler
    private func handleHostChange(newHostDeviceID: String) {
        gameState.hostDeviceID = newHostDeviceID
        
        print("👑 Yeni host: \(newHostDeviceID)")
        print("👑 Ben host'um: \(isHost)")
        
        if isHost {
            // Yeni host olduysak ayarları gönder
            sendHostSettings()
            print("👑 Yeni host olarak ayarları gönderdim")
        }
        
        // Host değişikliği haptic feedback
        playHaptic(style: .medium)
    }
    
    // MARK: - Play Again System - YENİ FONKSİYONLAR
    
    /// Tekrar oyna isteği başlatır (sadece host)
    func requestPlayAgain() {
        guard isHost else {
            print("⚠️ Sadece host tekrar oyna isteği gönderebilir")
            return
        }
        
        guard gameState.gamePhase == .oyunBitti else {
            print("⚠️ Tekrar oyna sadece oyun bittiğinde kullanılabilir")
            return
        }
        
        print("🔄 Tekrar oyna isteği başlatılıyor...")
        
        // Tekrar oyna sistemini başlat
        gameState.isWaitingForPlayAgainResponses = true
        gameState.playAgainRequests.removeAll()
        
        // Kendi onayımızı ekle
        gameState.playAgainRequests[userProfile.deviceID] = true
        
        // Diğer oyunculara istek gönder
        let message = NetworkMessage.playAgainRequest(deviceID: userProfile.deviceID)
        send(message: message)
        
        // Game state'i senkronize et
        syncGameState()
        
        print("📤 Tekrar oyna isteği gönderildi")
    }
    
    /// Tekrar oyna isteğine yanıt verir
    func respondToPlayAgain(accepted: Bool) {
        guard gameState.isWaitingForPlayAgainResponses else {
            print("⚠️ Aktif bir tekrar oyna isteği yok")
            return
        }
        
        let currentDeviceID = userProfile.deviceID
        
        print("🔄 Tekrar oyna yanıtı: \(accepted ? "Kabul" : "Ret")")
        
        // Kendi yanıtımızı kaydet
        gameState.playAgainRequests[currentDeviceID] = accepted
        
        // Yanıtı diğer oyunculara gönder
        let message = NetworkMessage.playAgainResponse(deviceID: currentDeviceID, accepted: accepted)
        send(message: message)
        
        // Host isek tüm yanıtları kontrol et
        if isHost {
            checkPlayAgainCompletion()
        }
    }
    
    /// Tüm tekrar oyna yanıtlarının gelip gelmediğini kontrol eder (sadece host)
    private func checkPlayAgainCompletion() {
        guard isHost else { return }
        
        let totalPlayers = gameState.players.count
        let responseCount = gameState.playAgainRequests.count
        
        print("🔄 Tekrar oyna yanıtları: \(responseCount)/\(totalPlayers)")
        
        // Tüm yanıtlar geldi mi?
        guard responseCount == totalPlayers else { return }
        
        // Kabul eden ve reddeden oyuncuları ayır
        let acceptingPlayers = gameState.players.filter { player in
            gameState.playAgainRequests[player.deviceID] == true
        }
        
        let rejectingPlayers = gameState.players.filter { player in
            gameState.playAgainRequests[player.deviceID] == false
        }
        
        print("✅ Kabul eden oyuncular (\(acceptingPlayers.count)): \(acceptingPlayers.map { $0.displayName }.joined(separator: ", "))")
        print("❌ Reddeden oyuncular (\(rejectingPlayers.count)): \(rejectingPlayers.map { $0.displayName }.joined(separator: ", "))")
        
        if acceptingPlayers.count >= 2 {
            // En az 2 oyuncu kabul etti - onlarla devam et
            print("🎉 En az 2 oyuncu kabul etti - Reddedenleri çıkarıp yeni turnuva başlatılıyor")
            
            // Reddeden oyuncuları sistemden çıkar
            removeRejectingPlayersAndStartTournament(
                acceptingPlayers: acceptingPlayers,
                rejectingPlayers: rejectingPlayers
            )
            
        } else {
            // 2'den az oyuncu kabul etti - herkesi ana menüye gönder
            print("❌ Yetersiz oyuncu kabul etti (\(acceptingPlayers.count)) - Ana menüye dönülecek")
            
            // Tekrar oyna sistemini temizle
            gameState.isWaitingForPlayAgainResponses = false
            gameState.playAgainRequests.removeAll()
            
            // Ana menüye dönüş haptic feedback
            playHaptic(style: .warning)
            
            // Game state'i senkronize et
            syncGameState()
            
            // 3 saniye sonra ana menüye dön
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.resetToMainMenu()
            }
        }
    }
    
    /// Reddeden oyuncuları çıkarır ve kabul edenlerle yeni turnuva başlatır
    private func removeRejectingPlayersAndStartTournament(acceptingPlayers: [Player], rejectingPlayers: [Player]) {
        // Reddeden oyuncuları bilgilendir (ana menüye döneceklerini)
        for rejectingPlayer in rejectingPlayers {
            let message = NetworkMessage.playerLeft(deviceID: rejectingPlayer.deviceID)
            send(message: message)
        }
        
        // Host succession'ı güncelle - sadece kabul edenler kalacak
        let newHostSuccession = gameState.hostSuccession.filter { deviceID in
            acceptingPlayers.contains { $0.deviceID == deviceID }
        }
        
        // Eğer mevcut host reddettiyse yeni host seç
        if !acceptingPlayers.contains(where: { $0.deviceID == gameState.hostDeviceID }) {
            if let newHostDeviceID = newHostSuccession.first {
                gameState.hostDeviceID = newHostDeviceID
                print("👑 Host reddetti, yeni host: \(newHostDeviceID)")
                
                // Host değişikliğini bildir
                let hostChangeMessage = NetworkMessage.hostChanged(newHostDeviceID: newHostDeviceID)
                send(message: hostChangeMessage)
            }
        }
        
        // Oyuncu listelerini güncelle - sadece kabul edenler kalsın
        gameState.players = acceptingPlayers
        gameState.activePlayers = acceptingPlayers
        gameState.hostSuccession = newHostSuccession
        
        // Aynı oyuncularla yeni turnuva başlat
        restartTournamentWithAcceptingPlayers()
    }
    
    /// Kabul eden oyuncularla yeni turnuva başlatır
    private func restartTournamentWithAcceptingPlayers() {
        print("🔄 Kabul eden oyuncularla yeni turnuva başlatılıyor...")
        
        // Tekrar oyna sistemini temizle
        gameState.isWaitingForPlayAgainResponses = false
        gameState.playAgainRequests.removeAll()
        
        // Oyun verilerini sıfırla ama oyuncuları koru
        let currentPlayers = gameState.players
        let currentRoom = gameState.currentRoom
        let currentHostDeviceID = gameState.hostDeviceID
        let currentHostSuccession = gameState.hostSuccession
        
        // GameState'i temizle
        gameState = GameState()
        
        // Gerekli verileri geri yükle
        gameState.players = currentPlayers
        gameState.activePlayers = currentPlayers // Tüm oyuncular yeniden aktif
        gameState.currentRoom = currentRoom
        gameState.hostDeviceID = currentHostDeviceID
        gameState.hostSuccession = currentHostSuccession
        gameState.gamePhase = .lobi
        
        // Yeniden başlatma mesajını gönder
        let message = NetworkMessage.restartTournament
        send(message: message)
        
        // Game state'i senkronize et
        syncGameState()
        
        // Başarılı yeniden başlatma haptic feedback
        playHaptic(style: .success)
        
        print("✅ Yeni turnuva başlatıldı - Lobi aşamasına dönüldü (\(currentPlayers.count) oyuncu)")
    }
    
    /// Aynı oyuncularla yeni turnuva başlatır (Eski fonksiyon - artık kullanılmıyor)
    private func restartTournament() {
        // Bu fonksiyon artık restartTournamentWithAcceptingPlayers() ile değiştirildi
        restartTournamentWithAcceptingPlayers()
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
        stopRoomSearch() // Oda aramayı da durdur - YENİ
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
            case .vote(let deviceID, let mode):
                print("📤 Oy gönderildi: \(mode.rawValue) (DeviceID: \(deviceID))")
            case .choice(let deviceID, let selection):
                print("📤 Seçim gönderildi: \(selection.rawValue) (DeviceID: \(deviceID))")
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
            case .leaveRoom(let deviceID):
                print("📤 Oda ayrılma mesajı gönderildi: \(deviceID)")
            case .hostChanged(let newHostDeviceID):
                print("📤 Host değişikliği bildirimi gönderildi: \(newHostDeviceID)")
            case .playAgainRequest(let deviceID):
                print("📤 Tekrar oyna isteği gönderildi: \(deviceID)")
            case .playAgainResponse(let deviceID, let accepted):
                print("📤 Tekrar oyna yanıtı gönderildi: \(deviceID) - \(accepted)")
            case .restartTournament:
                print("📤 Turnuva yeniden başlatma komutu gönderildi")
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
    
    /// Oy verme fonksiyonu - GÜNCELLENDİ
    func castVote(mode: GameMode) {
        let currentDeviceID = userProfile.deviceID
        
        // Daha önce oy verilmiş mi kontrol et
        guard gameState.votes[currentDeviceID] == nil else {
            print("⚠️ \(userProfile.nickname) zaten oy vermiş")
            playHaptic(style: .warning)
            return
        }
        
        print("🗳️ \(userProfile.nickname) oyunu: \(mode.rawValue) (DeviceID: \(currentDeviceID))")
        
        // Başarılı oy haptic feedback
        playHaptic(style: .success)
        
        // Kendi oyunu yerel olarak ekle
        gameState.votes[currentDeviceID] = mode
        
        // Ağ üzerinden diğer cihazlara gönder - DeviceID eklendi
        let voteMessage = NetworkMessage.vote(deviceID: currentDeviceID, mode: mode)
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
    }
    
    /// Seçim yapma fonksiyonu - GÜNCELLENDİ
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
        
        print("✂️ \(userProfile.nickname) seçimi: \(choice.rawValue) (DeviceID: \(currentDeviceID))")
        
        // Başarılı seçim haptic feedback
        playHaptic(style: .success)
        
        // Kendi seçimini yerel olarak ekle
        gameState.choices[currentDeviceID] = choice
        
        // Ağ üzerinden diğer cihazlara gönder - DeviceID eklendi
        let choiceMessage = NetworkMessage.choice(deviceID: currentDeviceID, selection: choice)
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
    
    /// Oyunu sıfırlar ve ana menüye döner (Public method)
    func resetGame() {
        print("🔄 Oyun sıfırlanıyor (Public resetGame çağrısı)")
        resetToMainMenu()
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
    /// GameState değişikliklerini izler ve motion detection'ı yönetir
    private func handleGameStateChange(from oldState: GameState, to newState: GameState) {
        // Sadece tur oynama aşamasında ve sallama modunda motion detection aktif olmalı
        let shouldHaveMotionDetection = (newState.gamePhase == .turOynaniyor && newState.gameMode == .sallama)
        let currentlyHasMotionDetection = motionManager.isAccelerometerActive
        
        // Motion detection başlatılmalı
        if shouldHaveMotionDetection && !currentlyHasMotionDetection {
            print("🎯 Motion detection başlatılıyor (GameState değişikliği)")
            startMotionDetection()
        }
        
        // Motion detection durdurulmalı
        if !shouldHaveMotionDetection && currentlyHasMotionDetection {
            print("🛑 Motion detection durduruluyor (GameState değişikliği)")
            stopMotionDetection()
        }
    }
    
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
    
    // MARK: - Message Handlers - YENİ FONKSİYONLAR
    
    /// Host'un bağlantısının kopması durumunu işler
    private func handleHostDisconnection(disconnectedDeviceID: String) {
        print("👑 Host bağlantısı koptu, host transferi yapılıyor...")
        
        // Eski host'u sistemden kaldır
        gameState.players.removeAll { $0.deviceID == disconnectedDeviceID }
        gameState.activePlayers.removeAll { $0.deviceID == disconnectedDeviceID }
        gameState.hostSuccession.removeAll { $0 == disconnectedDeviceID }
        gameState.votes.removeValue(forKey: disconnectedDeviceID)
        gameState.choices.removeValue(forKey: disconnectedDeviceID)
        gameState.playAgainRequests.removeValue(forKey: disconnectedDeviceID)
        
        // Yeni host seç (succession listesindeki ilk kişi)
        if let newHostDeviceID = gameState.hostSuccession.first {
            gameState.hostDeviceID = newHostDeviceID
            
            print("👑 Yeni host belirlendi: \(newHostDeviceID)")
            print("👑 Ben yeni host'um: \(isHost)")
            
            if isHost {
                // Yeni host olduysak bilgilendir
                print("👑 Yeni host olarak görevimi üstleniyorum")
                
                // Host değişikliğini diğerlerine bildir
                let message = NetworkMessage.hostChanged(newHostDeviceID: newHostDeviceID)
                send(message: message)
                
                // Game state'i senkronize et
                syncGameState()
                
                // Host ayarlarını gönder
                sendHostSettings()
                
                // Host transfer haptic feedback
                playHaptic(style: .heavy)
                
                // Oyun durumunu kontrol et
                handlePlayerDisconnection()
            }
        } else {
            // Başka oyuncu yok - ana menüye dön
            print("⚠️ Başka oyuncu kalmadı - Ana menüye dönülecek")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.resetToMainMenu()
            }
        }
    }
    
    /// Oyuncu ayrılması mesajını işler
    private func handlePlayerLeave(deviceID: String) {
        // Eğer ayrılan oyuncu biziz ve tekrar oyna sürecindeyse ana menüye dön
        if deviceID == userProfile.deviceID && gameState.isWaitingForPlayAgainResponses {
            print("🚪 Tekrar oyna reddettiğimiz için ana menüye dönülüyor")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.resetToMainMenu()
            }
            return
        }
        
        // Oyuncuyu kaldır
        gameState.players.removeAll { $0.deviceID == deviceID }
        gameState.activePlayers.removeAll { $0.deviceID == deviceID }
        
        // Host succession'dan kaldır
        gameState.hostSuccession.removeAll { $0 == deviceID }
        
        // Votes ve choices'lardan kaldır
        gameState.votes.removeValue(forKey: deviceID)
        gameState.choices.removeValue(forKey: deviceID)
        gameState.playAgainRequests.removeValue(forKey: deviceID)
        
        // Oyuncu ayrılma haptic feedback
        playHaptic(style: .light)
        
        // Eğer çok az oyuncu kaldıysa ana menüye dön
        if gameState.players.count < 2 {
            print("⚠️ Yetersiz oyuncu kaldı - Ana menüye dönülüyor")
            playHaptic(style: .warning)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.resetToMainMenu()
            }
        }
        
        // Host isek oyun durumunu kontrol et
        if isHost {
            handlePlayerDisconnection()
        }
    }
    
    /// Tekrar oyna isteği mesajını işler
    private func handlePlayAgainRequest(from deviceID: String) {
        guard gameState.gamePhase == .oyunBitti else { return }
        
        // İsteği kaydet
        gameState.isWaitingForPlayAgainResponses = true
        gameState.playAgainRequests[deviceID] = true // İstek gönderen otomatik olarak kabul ediyor
        
        // Tekrar oyna isteği haptic feedback
        playHaptic(style: .medium)
        
        print("🔄 Tekrar oyna sistemi aktif edildi")
    }
    
    /// Tekrar oyna yanıtı mesajını işler
    private func handlePlayAgainResponse(from deviceID: String, accepted: Bool) {
        guard gameState.isWaitingForPlayAgainResponses else { return }
        
        // Yanıtı kaydet
        gameState.playAgainRequests[deviceID] = accepted
        
        print("📝 Tekrar oyna yanıtı kaydedildi: \(deviceID) = \(accepted)")
        
        // Host isek tamamlanma kontrolü yap
        if isHost {
            checkPlayAgainCompletion()
        }
    }
    
    /// Turnuva yeniden başlatma mesajını işler
    private func handleTournamentRestart() {
        // Tekrar oyna sistemini temizle
        gameState.isWaitingForPlayAgainResponses = false
        gameState.playAgainRequests.removeAll()
        
        // Tüm oyuncuları yeniden aktif yap
        gameState.activePlayers = gameState.players
        
        // Oyun verilerini sıfırla
        gameState.gamePhase = .lobi
        gameState.gameMode = nil
        gameState.currentRound = 0
        gameState.votes.removeAll()
        gameState.choices.removeAll()
        
        // Turnuva yeniden başlatma haptic feedback
        playHaptic(style: .success)
        
        print("✅ Turnuva yeniden başlatıldı - Lobi aşamasına dönüldü")
    }
}

// MARK: - MCSessionDelegate
extension MultipeerManager: MCSessionDelegate {
    
    /// Peer bağlantı durumu değiştiğinde çağrılır - GELİŞTİRİLMİŞ VERSİYON
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("✅ Cihaz bağlandı: \(peerID.displayName)")
                
                // Eğer oda arıyorsak hemen deneme yap - YENİ
                if let searchCode = self.searchingRoomCode {
                    print("🔄 Yeni bağlantıda oda kodu deneniyor: \(searchCode)")
                    let message = NetworkMessage.roomCodeRequest(code: searchCode)
                    self.send(message: message)
                }
                
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
                
                // Host'un bağlantısı mı koptu kontrol et
                let disconnectedDeviceID = peerID.displayName
                if self.gameState.hostDeviceID == disconnectedDeviceID {
                    print("👑 Host'un bağlantısı koptu - Host transferi yapılıyor")
                    self.handleHostDisconnection(disconnectedDeviceID: disconnectedDeviceID)
                } else {
                    // Normal oyuncu koptu
                    self.handlePlayerLeave(deviceID: disconnectedDeviceID)
                }
                
                // Oyuncu kaldırma işlemi handlePlayerLeave veya handleHostDisconnection'da yapıldı
                
                // Oyunun kilitlenmesini önlemek için kontroller (sadece host ise)
                if self.isHost {
                    self.handlePlayerDisconnection()
                }
                
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
        
        // Eğer tekrar oyna aşamasındaysak ve tüm kalan oyuncular yanıt verdiyse
        if gameState.isWaitingForPlayAgainResponses && gameState.playAgainRequests.count == gameState.players.count {
            print("🔄 Oyuncu kopmasına rağmen tekrar oyna yanıtları tamamlandı")
            checkPlayAgainCompletion()
        }
        
        // Eğer çok az oyuncu kaldıysa oyunu bitir
        if gameState.players.count < 2 {
            print("⚠️ Yetersiz oyuncu kaldı - Ana menüye dönülecek")
            playHaptic(style: .error)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.resetToMainMenu()
            }
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
    
    /// Alınan mesajı işler - GÜNCELLENDİ
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
                
                // Host succession listesine ekle (eğer yoksa)
                if !gameState.hostSuccession.contains(player.deviceID) {
                    gameState.hostSuccession.append(player.deviceID)
                    print("👑 Host succession güncellendi: \(gameState.hostSuccession)")
                }
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
                // Oda bulundu! Aramayı durdur - GELİŞTİRİLMİŞ
                stopRoomSearch()
                
                // Oda katıl
                joinRoom(foundRoom)
                
                // Başarılı katılım haptic feedback
                playHaptic(style: .success)
                
                // Kendi bilgilerini host'a gönder
                let currentPlayer = getCurrentPlayer()
                let joinMessage = NetworkMessage.playerJoined(player: currentPlayer)
                send(message: joinMessage)
            }
            // Başarısız ise devam et - timer otomatik deneyecek
            
        case .requestRoomInfo:
            print("📋 Oda bilgisi istendi")
            
            // Eğer host isek oda bilgimizi paylaş
            if isHost, let currentRoom = gameState.currentRoom {
                let response = NetworkMessage.roomCreated(room: currentRoom)
                send(message: response)
            }
            
        case .vote(let deviceID, let mode):
            print("🗳️ Oy alındı: \(mode.rawValue) (DeviceID: \(deviceID))")
            
            guard gameState.votes[deviceID] == nil else {
                print("⚠️ \(deviceID) zaten oy vermiş")
                return
            }
            
            gameState.votes[deviceID] = mode
            
            // Host ise oylama kontrolü yap
            if isHost {
                checkVotingCompletion()
            }
            
        case .choice(let deviceID, let selection):
            print("✂️ Seçim alındı: \(selection.rawValue) (DeviceID: \(deviceID))")
            
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
            
        // YENİ MESAJ TÜRÜ HANDLİNG'LERİ
        case .leaveRoom(let deviceID):
            print("🚪 Oyuncu odadan ayrıldı: \(deviceID)")
            handlePlayerLeave(deviceID: deviceID)
            
        case .hostChanged(let newHostDeviceID):
            print("👑 Host değişikliği bildirimi alındı: \(newHostDeviceID)")
            handleHostChange(newHostDeviceID: newHostDeviceID)
            
        case .playAgainRequest(let deviceID):
            print("🔄 Tekrar oyna isteği alındı: \(deviceID)")
            handlePlayAgainRequest(from: deviceID)
            
        case .playAgainResponse(let deviceID, let accepted):
            print("🔄 Tekrar oyna yanıtı alındı: \(deviceID) - \(accepted ? "Kabul" : "Ret")")
            handlePlayAgainResponse(from: deviceID, accepted: accepted)
            
        case .restartTournament:
            print("🔄 Turnuva yeniden başlatma komutu alındı")
            handleTournamentRestart()
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
