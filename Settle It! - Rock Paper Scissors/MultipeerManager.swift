import Foundation
import MultipeerConnectivity
import CoreMotion

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
            // applySettings() burada çağrılmayacak çünkü sonsuz döngüye sebep olur
            print("⚙️ Ayarlar güncellendi")
        }
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
        
        // Ayarları uygula
        applySettings()
        
        // Servisleri başlat (eğer ayarlarda autoConnect açıksa)
        if settings.autoConnect {
            startAdvertising()
            startBrowsing()
            
            // Kendi oyuncuyu gameState'e ekle
            let currentPlayer = Player(displayName: peerID.displayName)
            gameState.players.append(currentPlayer)
            gameState.activePlayers.append(currentPlayer)
        }
    }
    
    // MARK: - Settings Management
    /// Ayarları uygular
    private func applySettings() {
        print("⚙️ Ayarlar uygulanıyor...")
        
        // Bağlantı ayarları henüz tam desteklenmiyor
        // Gelecekte Wi-Fi only veya Bluetooth only modu eklenebilir
        
        print("✅ Ayarlar uygulandı")
    }
    
    /// Ayarları varsayılana sıfırlar
    func resetSettings() {
        print("🔄 Ayarlar sıfırlanıyor...")
        settings.reset()
        settings = GameSettings.load()
        print("✅ Ayarlar sıfırlandı")
    }
    
    /// Haptic feedback çalar (ayarlarda açıksa)
    func playHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard settings.hapticFeedback else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Service Management
    /// Advertiser servisini başlatır (kendini duyurur)
    private func startAdvertising() {
        serviceAdvertiser.startAdvertisingPeer()
        print("🔊 Advertiser başlatıldı: \(peerID.displayName)")
    }
    
    /// Browser servisini başlatır (diğerlerini arar)
    private func startBrowsing() {
        serviceBrowser.startBrowsingForPeers()
        print("🔍 Browser başlatıldı: \(peerID.displayName)")
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
            
            print("📤 Mesaj gönderildi: \(message)")
        } catch {
            print("❌ Mesaj gönderme hatası: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Game Control Methods
    /// Oyunu başlatır ve oylama aşamasına geçer
    func startGame() {
        guard gameState.players.count >= 2 else {
            print("⚠️ Oyun başlatılamadı: Yetersiz oyuncu sayısı (\(gameState.players.count))")
            return
        }
        
        print("🎮 Oyun başlatılıyor")
        
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
    }
    
    /// Oy verme fonksiyonu
    func castVote(mode: GameMode) {
        let currentPlayerName = getCurrentPlayerName()
        
        // Daha önce oy verilmiş mi kontrol et
        guard gameState.votes[currentPlayerName] == nil else {
            print("⚠️ \(currentPlayerName) zaten oy vermiş")
            return
        }
        
        print("🗳️ \(currentPlayerName) oyunu: \(mode.rawValue)")
        
        // Kendi oyunu yerel olarak ekle
        gameState.votes[currentPlayerName] = mode
        
        // Ağ üzerinden diğer cihazlara gönder
        let voteMessage = NetworkMessage.vote(mode: mode)
        send(message: voteMessage)
        
        // Oylama tamamlandı mı kontrol et
        checkVotingCompletion()
    }
    
    /// Oylamanın tamamlanıp tamamlanmadığını kontrol eder
    private func checkVotingCompletion() {
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
        
        print("🏆 Kazanan mod: \(winningMode.rawValue)")
        print("⏰ Geri sayım aşamasına geçildi")
    }
    
    /// Turu başlatır - gamePhase'i .turOynaniyor olarak değiştirir
    func startRound() {
        print("🎯 Tur başlatılıyor - Oyuncular seçim yapabilir")
        
        // Tur sayısını artır
        gameState.currentRound += 1
        
        // Oyun aşamasını tur oynama olarak değiştir
        gameState.gamePhase = .turOynaniyor
        
        // Choices'ları temizle (yeni tur için)
        gameState.choices.removeAll()
        
        // Eğer sallama modu aktifse, hareket algılamayı başlat
        if gameState.gameMode == .sallama {
            startMotionDetection()
        }
    }
    
    /// Seçim yapma fonksiyonu
    func makeChoice(choice: Choice) {
        let currentPlayerName = getCurrentPlayerName()
        
        // Daha önce seçim yapılmış mı kontrol et
        guard gameState.choices[currentPlayerName] == nil else {
            print("⚠️ \(currentPlayerName) zaten seçim yapmış")
            return
        }
        
        // Oyuncunun active players listesinde olup olmadığını kontrol et
        guard gameState.activePlayers.contains(where: { $0.displayName == currentPlayerName }) else {
            print("⚠️ \(currentPlayerName) aktif oyuncu değil")
            return
        }
        
        print("✂️ \(currentPlayerName) seçimi: \(choice.rawValue)")
        
        // Kendi seçimini yerel olarak ekle
        gameState.choices[currentPlayerName] = choice
        
        // Ağ üzerinden diğer cihazlara gönder
        let choiceMessage = NetworkMessage.choice(selection: choice)
        send(message: choiceMessage)
        
        // Tur tamamlandı mı kontrol et
        checkRoundCompletion()
    }
    
    /// Turun tamamlanıp tamamlanmadığını kontrol eder
    private func checkRoundCompletion() {
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
    
    /// Tur sonuçlarını işler ve eleme algoritmasını çalıştırır
    private func processRoundResults() {
        print("🧮 Eleme algoritması çalıştırılıyor...")
        
        // Sadece aktif oyuncuların seçimlerini al
        let activePlayerChoices = gameState.choices.filter { choice in
            gameState.activePlayers.contains { $0.displayName == choice.key }
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
        
        // 3 saniye sonra sonraki adıma geç
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.proceedToNextPhase()
        }
    }
    
    /// Sonraki aşamaya geçer (yeni tur veya oyun sonu)
    private func proceedToNextPhase() {
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
            
            if let winner = gameState.activePlayers.first {
                print("🥇 Kazanan: \(winner.displayName)")
            } else {
                print("🤷‍♂️ Kazanan yok")
            }
        }
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
        startAdvertising()
        startBrowsing()
        
        // Kendi oyuncuyu gameState'e ekle
        let currentPlayer = Player(displayName: peerID.displayName)
        gameState.players.append(currentPlayer)
        gameState.activePlayers.append(currentPlayer)
        
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
                if let playerChoice = choices[player.displayName] {
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
    
    /// Oyunun bitip bitmediğini kontrol eder
    private func checkGameCompletion() {
        if gameState.activePlayers.count <= 1 {
            // Oyun bitti
            gameState.gamePhase = .oyunBitti
            print("🏆 Oyun bitti!")
            if let winner = gameState.activePlayers.first {
                print("🥇 Kazanan: \(winner.displayName)")
            }
        } else {
            // Yeni tur başlat
            print("🔄 Yeni tur başlatılıyor...")
            gameState.gamePhase = .geriSayim
            gameState.choices.removeAll() // Choices'ları temizle
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
            
            // Sallama tespiti - herhangi bir eksende 1.5g'den fazla ivme
            let acceleration = data.acceleration
            let isShaking = abs(acceleration.x) > 1.5 ||
                           abs(acceleration.y) > 1.5 ||
                           abs(acceleration.z) > 1.5
            
            if isShaking {
                print("🔄 Sallama tespit edildi! (x: \(acceleration.x), y: \(acceleration.y), z: \(acceleration.z))")
                
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
    
    /// Mevcut oyuncunun adını döndürür
    func getCurrentPlayerName() -> String {
        return peerID.displayName
    }
    
    // MARK: - Helper Methods
    /// PeerID'den Player nesnesi bulur
    private func findPlayer(by peerID: MCPeerID) -> Player? {
        return gameState.players.first { $0.displayName == peerID.displayName }
    }
    
    /// Oyuncuyu gameState'den güvenli şekilde kaldırır
    private func removePlayer(by peerID: MCPeerID) {
        let displayName = peerID.displayName
        
        // Players listesinden kaldır
        gameState.players.removeAll { $0.displayName == displayName }
        
        // Active players listesinden kaldır
        gameState.activePlayers.removeAll { $0.displayName == displayName }
        
        // Votes ve choices'lardan kaldır
        gameState.votes.removeValue(forKey: displayName)
        gameState.choices.removeValue(forKey: displayName)
        
        print("🚫 Oyuncu kaldırıldı: \(displayName)")
    }
}

// MARK: - MCSessionDelegate
extension MultipeerManager: MCSessionDelegate {
    
    /// Peer bağlantı durumu değiştiğinde çağrılır
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("✅ Oyuncu bağlandı: \(peerID.displayName)")
                
                // Yeni oyuncuyu ekle (eğer zaten yoksa)
                if !self.gameState.players.contains(where: { $0.displayName == peerID.displayName }) {
                    let newPlayer = Player(displayName: peerID.displayName)
                    self.gameState.players.append(newPlayer)
                    self.gameState.activePlayers.append(newPlayer)
                }
                
            case .notConnected:
                print("❌ Oyuncu bağlantısı koptu: \(peerID.displayName)")
                
                // Kullanıcıya bildirim göster
                self.connectionAlert = ConnectionAlert(
                    title: "Bağlantı Koptu",
                    message: "\(peerID.displayName) oyundan ayrıldı ve elendi."
                )
                
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
            gameState.gamePhase = .oyunBitti
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
        let displayName = peerID.displayName
        
        switch message {
        case .vote(let mode):
            print("🗳️ \(displayName) oyunu: \(mode.rawValue)")
            
            // Daha önce oy verilmiş mi kontrol et
            guard gameState.votes[displayName] == nil else {
                print("⚠️ \(displayName) zaten oy vermiş, tekrar oy sayılmayacak")
                return
            }
            
            gameState.votes[displayName] = mode
            
            // Oylama tamamlandı mı kontrol et
            checkVotingCompletion()
            
        case .choice(let selection):
            print("✂️ \(displayName) seçimi: \(selection.rawValue)")
            
            // Daha önce seçim yapılmış mı kontrol et
            guard gameState.choices[displayName] == nil else {
                print("⚠️ \(displayName) zaten seçim yapmış, tekrar sayılmayacak")
                return
            }
            
            // Oyuncunun active players listesinde olup olmadığını kontrol et
            guard gameState.activePlayers.contains(where: { $0.displayName == displayName }) else {
                print("⚠️ \(displayName) aktif oyuncu değil")
                return
            }
            
            gameState.choices[displayName] = selection
            
            // Tur tamamlandı mı kontrol et
            checkRoundCompletion()
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
