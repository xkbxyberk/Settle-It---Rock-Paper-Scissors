import SwiftUI

struct SettingsView: View {
    
    // MARK: - Properties
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var multipeerManager: MultipeerManager
    @State private var animateContent = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        
                        // MARK: - Header
                        headerSection
                        
                        // MARK: - Connection Settings
                        connectionSettingsSection
                        
                        // MARK: - Game Settings
                        gameSettingsSection
                        
                        // MARK: - Experience Settings
                        experienceSettingsSection
                        
                        // MARK: - About Section
                        aboutSection
                        
                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sıfırla") {
                        multipeerManager.resetSettings()
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .font(.subheadline)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animateContent = true
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("⚙️")
                .font(.system(size: 50))
                .scaleEffect(animateContent ? 1.0 : 0.5)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateContent)
            
            Text("Ayarlar")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3), value: animateContent)
            
            Text("Oyun tercihlerinizi düzenleyin")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4), value: animateContent)
        }
    }
    
    // MARK: - Connection Settings Section
    private var connectionSettingsSection: some View {
        SettingsSection(
            title: "📡 Bağlantı Ayarları",
            delay: 0.5,
            isAnimated: animateContent
        ) {
            VStack(spacing: 16) {
                
                // Connection Type Picker
                SettingRow(
                    icon: "antenna.radiowaves.left.and.right",
                    title: "Bağlantı Türü",
                    subtitle: multipeerManager.settings.connectionType.rawValue
                ) {
                    Picker("Bağlantı Türü", selection: $multipeerManager.settings.connectionType) {
                        ForEach(ConnectionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .colorScheme(.dark)
                }
                
                // Auto Connect Toggle
                SettingRow(
                    icon: "wifi.circle",
                    title: "Otomatik Bağlan",
                    subtitle: "Yakındaki cihazları otomatik bul"
                ) {
                    Toggle("", isOn: $multipeerManager.settings.autoConnect)
                        .tint(.blue)
                }
            }
        }
    }
    
    // MARK: - Game Settings Section
    private var gameSettingsSection: some View {
        SettingsSection(
            title: "🎮 Oyun Ayarları",
            delay: 0.6,
            isAnimated: animateContent
        ) {
            VStack(spacing: 16) {
                
                // Countdown Duration
                SettingRow(
                    icon: "timer",
                    title: "Geri Sayım Süresi",
                    subtitle: "\(multipeerManager.settings.countdownDuration) saniye"
                ) {
                    Stepper("", value: $multipeerManager.settings.countdownDuration, in: 1...5)
                        .labelsHidden()
                }
                
                // Preferred Game Mode
                SettingRow(
                    icon: "gamecontroller",
                    title: "Tercih Edilen Mod",
                    subtitle: multipeerManager.settings.preferredGameMode?.rawValue ?? "Oylama"
                ) {
                    Picker("Oyun Modu", selection: $multipeerManager.settings.preferredGameMode) {
                        Text("Oylama").tag(nil as GameMode?)
                        ForEach([GameMode.dokunma, .sallama], id: \.self) { mode in
                            Text(mode.rawValue).tag(mode as GameMode?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .foregroundColor(.blue)
                }
                
                // Shake Sensitivity (only for shake mode)
                SettingRow(
                    icon: "iphone.shake",
                    title: "Sallama Hassasiyeti",
                    subtitle: shakeSensitivityText
                ) {
                    Slider(value: $multipeerManager.settings.shakeSensitivity, in: 1.0...3.0, step: 0.5)
                        .tint(.purple)
                }
            }
        }
    }
    
    // MARK: - Experience Settings Section
    private var experienceSettingsSection: some View {
        SettingsSection(
            title: "✨ Deneyim Ayarları",
            delay: 0.7,
            isAnimated: animateContent
        ) {
            VStack(spacing: 16) {
                
                // Sound Effects
                SettingRow(
                    icon: "speaker.wave.2",
                    title: "Ses Efektleri",
                    subtitle: "Oyun seslerini aç/kapat"
                ) {
                    Toggle("", isOn: $multipeerManager.settings.soundEffects)
                        .tint(.green)
                }
                
                // Haptic Feedback
                SettingRow(
                    icon: "iphone.radiowaves.left.and.right",
                    title: "Dokunsal Geri Bildirim",
                    subtitle: "Titreşim efektlerini aç/kapat"
                ) {
                    Toggle("", isOn: $multipeerManager.settings.hapticFeedback)
                        .tint(.orange)
                }
                
                // Animations
                SettingRow(
                    icon: "sparkles",
                    title: "Animasyonlar",
                    subtitle: "Geçiş efektlerini aç/kapat"
                ) {
                    Toggle("", isOn: $multipeerManager.settings.animations)
                        .tint(.purple)
                }
            }
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        SettingsSection(
            title: "ℹ️ Hakkında",
            delay: 0.8,
            isAnimated: animateContent
        ) {
            VStack(spacing: 16) {
                
                SettingRow(
                    icon: "info.circle",
                    title: "Versiyon",
                    subtitle: "1.0.0"
                ) {
                    EmptyView()
                }
                
                SettingRow(
                    icon: "heart",
                    title: "Geliştirici",
                    subtitle: "Made with ❤️"
                ) {
                    EmptyView()
                }
                
                SettingRow(
                    icon: "star",
                    title: "Değerlendir",
                    subtitle: "App Store'da puan ver"
                ) {
                    Button(action: {
                        // TODO: App Store rating
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    private var shakeSensitivityText: String {
        switch multipeerManager.settings.shakeSensitivity {
        case 1.0...1.5: return "Düşük"
        case 1.5...2.0: return "Normal"
        case 2.0...2.5: return "Yüksek"
        default: return "Çok Yüksek"
        }
    }
}

// MARK: - Settings Section Component
struct SettingsSection<Content: View>: View {
    let title: String
    let delay: Double
    let isAnimated: Bool
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                content()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .opacity(isAnimated ? 1.0 : 0.0)
        .offset(y: isAnimated ? 0 : 30)
        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(delay), value: isAnimated)
    }
}

// MARK: - Setting Row Component
struct SettingRow<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let content: () -> Content
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 24, height: 24)
            
            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Control
            content()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(MultipeerManager())
}
