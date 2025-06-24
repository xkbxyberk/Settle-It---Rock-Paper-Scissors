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
        let currentUserName = multipeerManager.getCurrentPlayerName()
        return multipeerManager.gameState.choices.keys.contains(currentUserName)
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
            
            if let gameMode = multipeerManager.gameState.gameMode {
                Text("Mod: \(gameMode.rawValue)")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
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
            
            Text("\(multipeerManager.gameState.choices.count) / \(multipeerManager.gameState.activePlayers.count) seçim tamamlandı")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 20)
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
                    isSelected: hasUserMadeChoice && multipeerManager.gameState.choices[multipeerManager.getCurrentPlayerName()] == .tas,
                    isDisabled: hasUserMadeChoice
                ) {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    multipeerManager.makeChoice(choice: .tas)
                }
                
                ChoiceButton(
                    choice: .kagit,
                    icon: "📄",
                    title: "KAĞIT",
                    isSelected: hasUserMadeChoice && multipeerManager.gameState.choices[multipeerManager.getCurrentPlayerName()] == .kagit,
                    isDisabled: hasUserMadeChoice
                ) {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    multipeerManager.makeChoice(choice: .kagit)
                }
                
                ChoiceButton(
                    choice: .makas,
                    icon: "✂️",
                    title: "MAKAS",
                    isSelected: hasUserMadeChoice && multipeerManager.gameState.choices[multipeerManager.getCurrentPlayerName()] == .makas,
                    isDisabled: hasUserMadeChoice
                ) {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
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
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
            } else {
                stopCountdownTimer()
                multipeerManager.startRound()
            }
        }
    }
    
    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
}

// MARK: - Choice Button
struct ChoiceButton: View {
    let choice: Choice
    let icon: String
    let title: String
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
