import SwiftUI

struct GamePlayView: View {
    
    // MARK: - Properties
    /// MultipeerManager'dan geçirilen environment object
    @EnvironmentObject var multipeerManager: MultipeerManager
    
    /// Geri sayım sayacı - ayarlardan alınır
    @State private var countdown = 3
    
    /// Timer referansı
    @State private var countdownTimer: Timer?
    
    /// Kullanıcının seçim yapıp yapmadığını kontrol eder
    private var hasUserMadeChoice: Bool {
        let currentDeviceID = multipeerManager.getCurrentUserDeviceID()
        return multipeerManager.gameState.choices.keys.contains(currentDeviceID)
    }
    
    /// Kullanıcının yaptığı seçim
    private var userChoice: Choice? {
        let currentDeviceID = multipeerManager.getCurrentUserDeviceID()
        return multipeerManager.gameState.choices[currentDeviceID]
    }
    
    /// Tur tamamlanma oranı
    private var roundProgress: Double {
        let totalPlayers = multipeerManager.gameState.activePlayers.count
        let totalChoices = multipeerManager.gameState.choices.count
        return totalPlayers > 0 ? Double(totalChoices) / Double(totalPlayers) : 0.0
    }
    
    // MARK: - Body
    var body: some View {
        ResponsiveContainer {
            VStack(spacing: ResponsiveSpacing.extraLarge) {
                
                // MARK: - Round Info
                roundInfoSection
                
                // MARK: - Main Content
                mainContentSection
                
                Spacer()
            }
        }
        .onAppear {
            setupCountdownTimer()
        }
        .onDisappear {
            stopCountdownTimer()
        }
    }
    
    // MARK: - Round Info Section
    private var roundInfoSection: some View {
        VStack(spacing: ResponsiveSpacing.small) {
            Text("🏆 Tur \(multipeerManager.gameState.currentRound + 1)")
                .font(ResponsiveFont.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.9))
            
            if let gameMode = multipeerManager.gameState.gameMode {
                Text("Mod: \(gameMode.rawValue)")
                    .font(ResponsiveFont.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text("\(multipeerManager.gameState.activePlayers.count) oyuncu yarışıyor")
                .font(ResponsiveFont.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, ResponsiveSpacing.medium)
        .frame(maxWidth: .infinity)
        .responsiveCard()
    }
    
    // MARK: - Main Content Section
    @ViewBuilder
    private var mainContentSection: some View {
        switch multipeerManager.gameState.gamePhase {
        case .geriSayim:
            countdownSection
            
        case .turOynaniyor:
            gameplaySection
            
        default:
            EmptyView()
        }
    }
    
    // MARK: - Countdown Section
    private var countdownSection: some View {
        VStack(spacing: ResponsiveSpacing.extraLarge) {
            
            Text("⏰ Hazır Olun!")
                .font(ResponsiveFont.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Countdown circle
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 8)
                    .frame(width: ResponsiveSize.countdownCircle, height: ResponsiveSize.countdownCircle)
                
                Circle()
                    .trim(from: 0, to: CGFloat(countdown) / CGFloat(multipeerManager.settings.countdownDuration))
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: ResponsiveSize.countdownCircle, height: ResponsiveSize.countdownCircle)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: countdown)
                
                Text("\(countdown)")
                    .font(.system(size: ResponsiveSize.countdownCircle * 0.3, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .scaleEffect(countdown == 0 ? 1.2 : 1.0)
                    .animation(ResponsiveAnimation.fast, value: countdown)
            }
            
            VStack(spacing: ResponsiveSpacing.small) {
                if let gameMode = multipeerManager.gameState.gameMode {
                    Text("Mod: \(gameMode.rawValue)")
                        .font(ResponsiveFont.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Text("Seçiminizi yapmaya hazırlanın!")
                    .font(ResponsiveFont.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    // MARK: - Gameplay Section
    private var gameplaySection: some View {
        VStack(spacing: ResponsiveSpacing.large) {
            
            // Header
            VStack(spacing: ResponsiveSpacing.medium) {
                Text("✂️ Seçiminizi Yapın!")
                    .font(ResponsiveFont.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Progress
                if !multipeerManager.gameState.activePlayers.isEmpty {
                    progressSection
                }
            }
            
            // Game Mode Specific Content
            if let gameMode = multipeerManager.gameState.gameMode {
                gameModeContentView(for: gameMode)
            }
            
            // Status
            statusSection
        }
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: ResponsiveSpacing.small) {
            ProgressView(value: roundProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .background(Color.white.opacity(0.3))
                .cornerRadius(4)
            
            HStack {
                Text("Seçim yapan: \(multipeerManager.gameState.choices.count)/\(multipeerManager.gameState.activePlayers.count)")
                    .font(ResponsiveFont.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                // Seçim yapan oyuncuların avatarları
                if !multipeerManager.gameState.choices.isEmpty {
                    playersWhoMadeChoicesView
                }
            }
        }
    }
    
    // MARK: - Players Who Made Choices View
    private var playersWhoMadeChoicesView: some View {
        HStack(spacing: -ResponsiveSpacing.tiny) {
            ForEach(Array(multipeerManager.gameState.choices.keys.prefix(4)), id: \.self) { deviceID in
                if let player = multipeerManager.gameState.activePlayers.first(where: { $0.deviceID == deviceID }) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.3))
                            .frame(width: ResponsiveSize.avatarSmall * 0.7, height: ResponsiveSize.avatarSmall * 0.7)
                            .overlay(
                                Circle()
                                    .stroke(Color.green, lineWidth: 2)
                            )
                        
                        Text(player.avatar)
                            .font(.system(size: ResponsiveSize.avatarSmall * 0.3))
                    }
                }
            }
            
            // Eğer 4'ten fazla oyuncu varsa +X göster
            if multipeerManager.gameState.choices.count > 4 {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.4))
                        .frame(width: ResponsiveSize.avatarSmall * 0.7, height: ResponsiveSize.avatarSmall * 0.7)
                    
                    Text("+\(multipeerManager.gameState.choices.count - 4)")
                        .font(ResponsiveFont.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Game Mode Content View
    @ViewBuilder
    private func gameModeContentView(for gameMode: GameMode) -> some View {
        switch gameMode {
        case .dokunma:
            touchModeView
            
        case .sallama:
            shakeModeView
            
        case .asamaliTurnuva:
            // Aşamalı turnuvada da alt mod belirlenmesi gerekiyor
            // Şimdilik varsayılan olarak dokunma modunu göster
            // Gerçek implementasyonda host ayarlarından veya ikinci oylamadan gelecek
            touchModeView
        }
    }
    
    // MARK: - Touch Mode View
    private var touchModeView: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            
            Text("👆 Bir seçenek üzerine dokunun")
                .font(ResponsiveFont.headline)
                .foregroundColor(.white.opacity(0.9))
                .padding(.bottom, ResponsiveSpacing.small)
            
            // Choice buttons
            VStack(spacing: ResponsiveSpacing.medium) {
                ChoiceButton(
                    choice: .tas,
                    icon: "🪨",
                    title: "TAŞ",
                    isSelected: hasUserMadeChoice && userChoice == .tas,
                    isDisabled: hasUserMadeChoice,
                    multipeerManager: multipeerManager
                ) {
                    multipeerManager.makeChoice(choice: .tas)
                }
                
                ChoiceButton(
                    choice: .kagit,
                    icon: "📄",
                    title: "KAĞIT",
                    isSelected: hasUserMadeChoice && userChoice == .kagit,
                    isDisabled: hasUserMadeChoice,
                    multipeerManager: multipeerManager
                ) {
                    multipeerManager.makeChoice(choice: .kagit)
                }
                
                ChoiceButton(
                    choice: .makas,
                    icon: "✂️",
                    title: "MAKAS",
                    isSelected: hasUserMadeChoice && userChoice == .makas,
                    isDisabled: hasUserMadeChoice,
                    multipeerManager: multipeerManager
                ) {
                    multipeerManager.makeChoice(choice: .makas)
                }
            }
        }
    }
    
    // MARK: - Shake Mode View
    private var shakeModeView: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            
            Text("📱 Cihazı Sallayın!")
                .font(ResponsiveFont.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: ResponsiveSpacing.medium) {
                Image(systemName: "iphone.shake")
                    .font(.system(size: ResponsiveSize.countdownCircle * 0.4))
                    .foregroundColor(.white.opacity(0.8))
                    .symbolEffect(.bounce, options: .repeating)
                
                Text("Seçim yapmak için")
                    .font(ResponsiveFont.title2)
                    .foregroundColor(.white.opacity(0.9))
                
                Text("cihazınızı sallayın!")
                    .font(ResponsiveFont.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Rastgele Taş, Kağıt veya Makas seçilecek")
                    .font(ResponsiveFont.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                // Hassasiyet ve açıklama
                VStack(spacing: ResponsiveSpacing.small) {
                    HStack(spacing: ResponsiveSpacing.small) {
                        Image(systemName: "gauge")
                            .font(ResponsiveFont.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("Hassasiyet: \(shakeSensitivityText)")
                            .font(ResponsiveFont.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text(shakeSensitivityDescription)
                        .font(ResponsiveFont.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .italic()
                }
                .padding(.top, ResponsiveSpacing.small)
            }
            .padding(.vertical, ResponsiveSpacing.extraLarge)
            .frame(maxWidth: .infinity)
            .responsiveCard()
        }
    }
    
    // MARK: - Status Section
    private var statusSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            
            if hasUserMadeChoice {
                // Kullanıcı seçim yapmış
                VStack(spacing: ResponsiveSpacing.small) {
                    HStack(spacing: ResponsiveSpacing.small) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("Seçiminiz alındı!")
                            .fontWeight(.semibold)
                    }
                    .font(ResponsiveFont.headline)
                    .foregroundColor(.white)
                    
                    if let choice = userChoice {
                        Text("Seçiminiz: \(choice.rawValue) \(getChoiceIcon(choice))")
                            .font(ResponsiveFont.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text("Diğer oyuncular bekleniyor...")
                        .font(ResponsiveFont.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.vertical, ResponsiveSpacing.medium)
                .frame(maxWidth: .infinity)
                .responsiveCard(backgroundColor: Color.green.opacity(0.2), borderColor: Color.green.opacity(0.4))
                
            } else {
                // Kullanıcı henüz seçim yapmamış
                VStack(spacing: ResponsiveSpacing.small) {
                    Text("⏳ Lütfen seçiminizi yapın")
                        .font(ResponsiveFont.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    Text("Turun ilerlemesi için seçim yapmanız gerekiyor")
                        .font(ResponsiveFont.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, ResponsiveSpacing.medium)
                .frame(maxWidth: .infinity)
                .responsiveCard(backgroundColor: Color.orange.opacity(0.2), borderColor: Color.orange.opacity(0.4))
            }
        }
    }
    
    // MARK: - Timer Methods
    private func setupCountdownTimer() {
        guard multipeerManager.gameState.gamePhase == .geriSayim else { return }
        
        // Ayarlardan geri sayım süresini al
        countdown = multipeerManager.settings.countdownDuration
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown > 0 {
                countdown -= 1
                
                // Haptic feedback (son 3 saniyede)
                if countdown <= 3 {
                    multipeerManager.playHaptic(style: .light)
                }
            } else {
                stopCountdownTimer()
                // Sadece host tur başlatabilir
                if multipeerManager.isHost {
                    multipeerManager.startRound()
                }
            }
        }
    }
    
    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    // MARK: - Helper Methods
    private func getChoiceIcon(_ choice: Choice) -> String {
        switch choice {
        case .tas: return "🪨"
        case .kagit: return "📄"
        case .makas: return "✂️"
        }
    }
    
    // MARK: - Shake Sensitivity Helper - Düzeltilmiş Kademelendirme
    private var shakeSensitivityText: String {
        let sensitivity = multipeerManager.settings.shakeSensitivity
        
        // Tam değer eşleştirmesi kullanarak çakışmayı önlüyoruz
        switch sensitivity {
        case 1.0: return "Çok Düşük"
        case 1.5: return "Düşük"
        case 2.0: return "Normal"
        case 2.5: return "Yüksek"
        case 3.0: return "Çok Yüksek"
        default: return "Normal"
        }
    }
    
    private var shakeSensitivityDescription: String {
        let sensitivity = multipeerManager.settings.shakeSensitivity
        
        switch sensitivity {
        case 1.0: return "Cihazı hafifçe eğmeniz bile yeterli"
        case 1.5: return "Hafif bir hareket yeterli"
        case 2.0: return "Orta seviye sallama gerekli"
        case 2.5: return "Güçlü sallama yapmanız gerekli"
        case 3.0: return "Çok güçlü sallama yapmanız gerekli"
        default: return "Orta seviye sallama gerekli"
        }
    }
}

// MARK: - Choice Button
struct ChoiceButton: View {
    let choice: Choice
    let icon: String
    let title: String
    let isSelected: Bool
    let isDisabled: Bool
    let multipeerManager: MultipeerManager
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if !isDisabled {
                multipeerManager.playHaptic(style: .medium)
            }
            action()
        }) {
            HStack(spacing: ResponsiveSpacing.medium) {
                Text(icon)
                    .font(ResponsiveFont.emoji(size: .small))
                
                Text(title)
                    .font(ResponsiveFont.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(ResponsiveFont.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, ResponsiveSpacing.medium)
            .padding(.horizontal, ResponsiveSpacing.large)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadiusLarge)
                    .fill(isSelected ? Color.blue : Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(ResponsiveAnimation.fast, value: isSelected)
        }
        .disabled(isDisabled)
        .opacity(isDisabled && !isSelected ? 0.6 : 1.0)
    }
}

// MARK: - Preview
#Preview {
    GamePlayView()
        .environmentObject(MultipeerManager())
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}
