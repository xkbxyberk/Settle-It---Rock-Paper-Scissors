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
                        
                        // MARK: - Host Settings (only if host)
                        if multipeerManager.isHost {
                            hostSettingsSection
                        }
                        
                        // MARK: - Personal Settings
                        personalSettingsSection
                        
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
            // Navigation bar için hafif şeffaf gradient-uyumlu background ayarla
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            
            // Gradient'e uyumlu hafif şeffaf renk (mor-mavi karışımı)
            let gradientColor = UIColor(red: 0.4, green: 0.5, blue: 0.8, alpha: 0.15)
            appearance.backgroundColor = gradientColor
            
            // Scroll edildiğinde de aynı hafif şeffaf background
            let scrollAppearance = UINavigationBarAppearance()
            scrollAppearance.configureWithOpaqueBackground()
            scrollAppearance.backgroundColor = gradientColor
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = scrollAppearance
            UINavigationBar.appearance().compactAppearance = scrollAppearance
            
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
                
                // Connection Type with Icons
                VStack(alignment: .leading, spacing: 12) {
                    Text("Bağlantı Türü")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        ForEach(ConnectionType.allCases, id: \.self) { type in
                            ConnectionTypeButton(
                                type: type,
                                isSelected: multipeerManager.settings.connectionType == type,
                                multipeerManager: multipeerManager
                            ) {
                                multipeerManager.settings.connectionType = type
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                        }
                    }
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
    
    // MARK: - Host Settings Section (Only for Host)
    private var hostSettingsSection: some View {
        SettingsSection(
            title: "👑 Host Ayarları",
            delay: 0.6,
            isAnimated: animateContent
        ) {
            VStack(spacing: 16) {
                
                // Host Info
                InfoRow(
                    icon: "crown.fill",
                    title: "Sen bu odanın host'usun",
                    subtitle: "Bu ayarlar tüm oyuncular için geçerli olacak",
                    color: .yellow
                )
                
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
            }
        }
    }
    
    // MARK: - Personal Settings Section
    private var personalSettingsSection: some View {
        SettingsSection(
            title: "👤 Kişisel Ayarlar",
            delay: multipeerManager.isHost ? 0.7 : 0.6,
            isAnimated: animateContent
        ) {
            VStack(spacing: 16) {
                
                // Shake Sensitivity (personal setting)
                SettingRow(
                    icon: "iphone.shake",
                    title: "Sallama Hassasiyeti",
                    subtitle: shakeSensitivityText
                ) {
                    Slider(value: $multipeerManager.settings.shakeSensitivity, in: 1.0...3.0, step: 0.5)
                        .tint(.purple)
                }
                
                InfoRow(
                    icon: "info.circle",
                    title: "Sallama hassasiyeti",
                    subtitle: "Bu ayar sadece senin cihazın için geçerli",
                    color: .blue
                )
            }
        }
    }
    
    // MARK: - Experience Settings Section
    private var experienceSettingsSection: some View {
        SettingsSection(
            title: "✨ Deneyim Ayarları",
            delay: multipeerManager.isHost ? 0.8 : 0.7,
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
            delay: multipeerManager.isHost ? 0.9 : 0.8,
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
                    subtitle: "Berk Akbay - Made with ❤️"
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
                        multipeerManager.playHaptic(style: .light)
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

// MARK: - Connection Type Button
struct ConnectionTypeButton: View {
    let type: ConnectionType
    let isSelected: Bool
    let multipeerManager: MultipeerManager
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            multipeerManager.playHaptic(style: .light)
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(typeShortName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .blue)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private var typeShortName: String {
        switch type {
        case .wifiOnly: return "Sadece\nWi-Fi"
        case .bluetoothOnly: return "Sadece\nBluetooth"
        case .both: return "Wi-Fi +\nBluetooth"
        }
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
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
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
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
