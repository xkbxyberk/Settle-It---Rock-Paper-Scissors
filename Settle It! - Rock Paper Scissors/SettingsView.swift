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
                    VStack(spacing: ResponsiveSpacing.large) {
                        
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
                        
                        Spacer(minLength: ResponsiveSpacing.extraLarge)
                    }
                    .padding(.horizontal, ResponsivePadding.horizontal)
                    .padding(.top, ResponsivePadding.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                    .font(ResponsiveFont.callout)
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sıfırla") {
                        multipeerManager.resetSettings()
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .font(ResponsiveFont.subheadline)
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
            
            withAnimation(ResponsiveAnimation.default.delay(0.2)) {
                animateContent = true
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            Text("⚙️")
                .font(ResponsiveFont.emoji(size: .medium))
                .scaleEffect(animateContent ? 1.0 : 0.5)
                .animation(ResponsiveAnimation.default.delay(0.1), value: animateContent)
            
            Text("Ayarlar")
                .font(ResponsiveFont.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                .animation(ResponsiveAnimation.default.delay(0.3), value: animateContent)
            
            Text("Oyun tercihlerinizi düzenleyin")
                .font(ResponsiveFont.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                .animation(ResponsiveAnimation.default.delay(0.4), value: animateContent)
        }
    }
    
    // MARK: - Connection Settings Section
    private var connectionSettingsSection: some View {
        SettingsSection(
            title: "📡 Bağlantı Ayarları",
            delay: 0.5,
            isAnimated: animateContent
        ) {
            VStack(spacing: ResponsiveSpacing.medium) {
                
                // Connection Type with Icons
                VStack(alignment: .leading, spacing: ResponsiveSpacing.medium) {
                    Text("Bağlantı Türü")
                        .font(ResponsiveFont.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: DeviceType.current == .phone ? 1 : 3), spacing: ResponsiveSpacing.medium) {
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
            VStack(spacing: ResponsiveSpacing.medium) {
                
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
            VStack(spacing: ResponsiveSpacing.medium) {
                
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
                    title: "Sallama hassasiyeti açıklaması",
                    subtitle: "Cihazınızı ne kadar güçlü sallamanız gerektiğini belirler. Bu ayar sadece sizin cihazınız için geçerlidir.",
                    color: .blue
                )
                
                // Sallama modu açıklaması
                VStack(alignment: .leading, spacing: ResponsiveSpacing.small) {
                    Text("📱 Sallama Modu Nasıl Çalışır?")
                        .font(ResponsiveFont.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: ResponsiveSpacing.tiny) {
                        HStack(alignment: .top, spacing: ResponsiveSpacing.small) {
                            Text("•")
                                .foregroundColor(.white.opacity(0.7))
                            Text("Cihazınızı herhangi bir yöne sallayın")
                                .font(ResponsiveFont.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        HStack(alignment: .top, spacing: ResponsiveSpacing.small) {
                            Text("•")
                                .foregroundColor(.white.opacity(0.7))
                            Text("Hareket algılandığında rastgele seçim yapılır")
                                .font(ResponsiveFont.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        HStack(alignment: .top, spacing: ResponsiveSpacing.small) {
                            Text("•")
                                .foregroundColor(.white.opacity(0.7))
                            Text("Hassasiyet arttıkça daha güçlü sallama gerekir")
                                .font(ResponsiveFont.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .responsiveCard(backgroundColor: Color.purple.opacity(0.15), borderColor: Color.purple.opacity(0.3))
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
            VStack(spacing: ResponsiveSpacing.medium) {
                
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
            VStack(spacing: ResponsiveSpacing.medium) {
                
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
                            .font(ResponsiveFont.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Properties - Düzeltilmiş Kademelendirme
    private var shakeSensitivityText: String {
        let sensitivity = multipeerManager.settings.shakeSensitivity
        
        // Tam değer eşleştirmesi kullanarak çakışmayı önlüyoruz
        switch sensitivity {
        case 1.0: return "Çok Düşük" // En hassas - çok hafif hareket yeterli
        case 1.5: return "Düşük"     // Hafif hareket yeterli
        case 2.0: return "Normal"    // Orta seviye hareket
        case 2.5: return "Yüksek"    // Güçlü hareket gerekli
        case 3.0: return "Çok Yüksek" // En az hassas - çok güçlü sallama
        default: return "Normal"     // Beklenmeyen değer için fallback
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
            HStack(spacing: ResponsiveSpacing.small) {
                Image(systemName: type.icon)
                    .font(ResponsiveFont.title3)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(typeShortName)
                    .font(ResponsiveFont.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .blue)
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, ResponsiveSpacing.medium)
            .padding(.horizontal, ResponsiveSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                    .fill(isSelected ? Color.blue : Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(ResponsiveAnimation.fast, value: isSelected)
    }
    
    private var typeShortName: String {
        switch type {
        case .wifiOnly: return "Sadece Wi-Fi"
        case .bluetoothOnly: return "Sadece Bluetooth"
        case .both: return "Wi-Fi + Bluetooth"
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
        HStack(spacing: ResponsiveSpacing.medium) {
            Image(systemName: icon)
                .font(ResponsiveFont.title3)
                .foregroundColor(color)
                .frame(width: ResponsiveSize.iconMedium, height: ResponsiveSize.iconMedium)
            
            VStack(alignment: .leading, spacing: ResponsiveSpacing.tiny) {
                Text(title)
                    .font(ResponsiveFont.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(ResponsiveFont.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .responsiveCard(backgroundColor: color.opacity(0.15), borderColor: color.opacity(0.3))
    }
}

// MARK: - Settings Section Component
struct SettingsSection<Content: View>: View {
    let title: String
    let delay: Double
    let isAnimated: Bool
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: ResponsiveSpacing.medium) {
            Text(title)
                .font(ResponsiveFont.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: ResponsiveSpacing.medium) {
                content()
            }
        }
        .responsiveCard()
        .opacity(isAnimated ? 1.0 : 0.0)
        .offset(y: isAnimated ? 0 : 30)
        .animation(ResponsiveAnimation.default.delay(delay), value: isAnimated)
    }
}

// MARK: - Setting Row Component
struct SettingRow<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let content: () -> Content
    
    var body: some View {
        HStack(spacing: ResponsiveSpacing.medium) {
            // Icon
            Image(systemName: icon)
                .font(ResponsiveFont.title3)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: ResponsiveSize.iconMedium, height: ResponsiveSize.iconMedium)
            
            // Text content
            VStack(alignment: .leading, spacing: ResponsiveSpacing.tiny) {
                Text(title)
                    .font(ResponsiveFont.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(ResponsiveFont.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Control
            content()
        }
        .padding(.vertical, ResponsiveSpacing.tiny)
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(MultipeerManager())
}
