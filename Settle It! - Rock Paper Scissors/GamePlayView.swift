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
        VStack(spacing: 30) {
            
            // MARK: - Round Info
            roundInfoSection
            
            // MARK: - Main Content
            mainContentSection
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .onAppear {
            setupCountdownTimer()
        }
        .onDisappear {
            stopCountdownTimer()
        }
    }
    
    // MARK: - Round Info Section
    private var roundInfoSection: some View {
        VStack(spacing: 8) {
            Text("🏆 Tur \(multipeerManager.gameState.currentRound + 1)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.9))
            
            if let gameMode = multipeerManager.gameState.gameMode {
                Text("Mod: \(gameMode.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text("\(multipeerManager.gameState.activePlayers.count) oyuncu yarışıyor")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
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
        VStack(spacing: 30) {
            
            Text("⏰ Hazır Olun!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Countdown circle
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 8)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .trim(from: 0, to: CGFloat(countdown) / CGFloat(multipeerManager.settings.countdownDuration))
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: countdown)
                
                Text("\(countdown)")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .scaleEffect(countdown == 0 ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: countdown)
            }
            
            VStack(spacing: 8) {
                if let gameMode = multipeerManager.gameState.gameMode {
                    Text("Mod: \(gameMode.rawValue)")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Text("Seçiminizi yapmaya hazırlanın!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    // MARK: - Gameplay Section
    private var gameplaySection: some View {
        VStack(spacing: 25) {
            
            // Header
            VStack(spacing: 12) {
                Text("✂️ Seçiminizi Yapın!")
                    .font(.largeTitle)
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
        VStack(spacing: 8) {
            ProgressView(value: roundProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .background(Color.white.opacity(0.3))
                .cornerRadius(4)
            
            HStack {
                Text("Seçim yapan: \(multipeerManager.gameState.choices.count)/\(multipeerManager.gameState.activePlayers.count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                // Seçim yapan oyuncuların avatarları
                if !multipeerManager.gameState.choices.isEmpty {
                    playersWhoMadeChoicesView
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Players Who Made Choices View
    private var playersWhoMadeChoicesView: some View {
        HStack(spacing: -6) {
            ForEach(Array(multipeerManager.gameState.choices.keys.prefix(4)), id: \.self) { deviceID in
                if let player = multipeerManager.gameState.activePlayers.first(where: { $0.deviceID == deviceID }) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.3))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .stroke(Color.green, lineWidth: 2)
                            )
                        
                        Text(player.avatar)
                            .font(.system(size: 12))
                    }
                }
            }
            
            // Eğer 4'ten fazla oyuncu varsa +X göster
            if multipeerManager.gameState.choices.count > 4 {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.4))
                        .frame(width: 28, height: 28)
                    
                    Text("+\(multipeerManager.gameState.choices.count - 4)")
                        .font(.caption2)
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
        }
    }
    
    // MARK: - Touch Mode View
    private var touchModeView: some View {
        VStack(spacing: 16) {
            
            Text("👆 Bir seçenek üzerine dokunun")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
                .padding(.bottom, 8)
            
            // Choice buttons
            VStack(spacing: 12) {
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
        VStack(spacing: 20) {
            
            Text("📱 Cihazı Sallayın!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                Image(systemName: "iphone.shake")
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.8))
                    .symbolEffect(.bounce, options: .repeating)
                
                Text("Seçim yapmak için")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
                
                Text("cihazınızı sallayın!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Rastgele Taş, Kağıt veya Makas seçilecek")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                // Hassasiyet göstergesi
                HStack(spacing: 8) {
                    Image(systemName: "gauge")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Hassasiyet: \(shakeSensitivityText)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 30)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
            )
        }
    }
    
    // MARK: - Status Section
    private var statusSection: some View {
        VStack(spacing: 12) {
            
            if hasUserMadeChoice {
                // Kullanıcı seçim yapmış
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("Seçiminiz alındı!")
                            .fontWeight(.semibold)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    
                    if let choice = userChoice {
                        Text("Seçiminiz: \(choice.rawValue) \(getChoiceIcon(choice))")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text("Diğer oyuncular bekleniyor...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.4), lineWidth: 1)
                        )
                )
                
            } else {
                // Kullanıcı henüz seçim yapmamış
                VStack(spacing: 8) {
                    Text("⏳ Lütfen seçiminizi yapın")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    Text("Turun ilerlemesi için seçim yapmanız gerekiyor")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
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
    
    private var shakeSensitivityText: String {
        switch multipeerManager.settings.shakeSensitivity {
        case 1.0...1.5: return "Düşük"
        case 1.5...2.0: return "Normal"
        case 2.0...2.5: return "Yüksek"
        default: return "Çok Yüksek"
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
            HStack(spacing: 16) {
                Text(icon)
                    .font(.system(size: 40))
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue : Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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
