import SwiftUI

struct MenuView: View {
    
    // MARK: - Properties
    @Binding var showMenu: Bool
    @Binding var showProfileSetup: Bool
    @Binding var userProfile: UserProfile
    @EnvironmentObject var multipeerManager: MultipeerManager
    @State private var showHowToPlay = false
    @State private var showSettings = false
    @State private var animateButtons = false
    
    // MARK: - Body
    var body: some View {
        ResponsiveContainer {
            VStack(spacing: ResponsiveSpacing.huge) {
                
                // MARK: - Header Section
                headerSection
                
                // MARK: - User Profile Section
                userProfileSection
                
                // MARK: - Menu Buttons
                menuButtonsSection
                
                // MARK: - Footer
                footerSection
                
                Spacer()
            }
        }
        .onAppear {
            let animationDelay = multipeerManager.settings.animations ? 0.2 : 0.05
            
            withAnimation(ResponsiveAnimation.default.delay(animationDelay)) {
                animateButtons = true
            }
        }
        .sheet(isPresented: $showHowToPlay) {
            HowToPlayView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            // App Icon - Sadece Dart emojisi, çember yok
            Text("🎯")
                .font(ResponsiveFont.emoji(size: .large))
                .scaleEffect(animateButtons ? 1.0 : 0.5)
                .animation(ResponsiveAnimation.default.delay(0.1), value: animateButtons)
            
            VStack(spacing: ResponsiveSpacing.small) {
                Text("Taş Kağıt Makas")
                    .font(ResponsiveFont.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(animateButtons ? 1.0 : 0.0)
                    .offset(y: animateButtons ? 0 : 20)
                    .animation(ResponsiveAnimation.default.delay(0.3), value: animateButtons)
                
                Text("Turnuva")
                    .font(ResponsiveFont.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(animateButtons ? 1.0 : 0.0)
                    .offset(y: animateButtons ? 0 : 20)
                    .animation(ResponsiveAnimation.default.delay(0.4), value: animateButtons)
                
                Text("Arkadaşlarınla multiplayer turnuva yap!")
                    .font(ResponsiveFont.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .opacity(animateButtons ? 1.0 : 0.0)
                    .offset(y: animateButtons ? 0 : 20)
                    .animation(ResponsiveAnimation.default.delay(0.5), value: animateButtons)
            }
        }
    }
    
    // MARK: - User Profile Section
    private var userProfileSection: some View {
        HStack(spacing: ResponsiveSpacing.medium) {
            // Avatar with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.white.opacity(0.3), .white.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: ResponsiveSize.avatarLarge, height: ResponsiveSize.avatarLarge)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 2)
                    )
                
                Text(userProfile.avatar)
                    .font(ResponsiveFont.emoji(size: .small))
                    .scaleEffect(animateButtons ? 1.0 : 0.8)
                    .animation(ResponsiveAnimation.default.delay(0.6), value: animateButtons)
            }
            
            // User Info
            VStack(alignment: .leading, spacing: ResponsiveSpacing.tiny) {
                Text("Hoşgeldin! 👋")
                    .font(ResponsiveFont.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(userProfile.nickname)
                    .font(ResponsiveFont.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("Hazırsın!")
                    .font(ResponsiveFont.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            // Edit Profile Button
            Button(action: {
                multipeerManager.playHaptic(style: .light)
                showProfileSetup = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: ResponsiveSize.avatarSmall, height: ResponsiveSize.avatarSmall)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: "pencil")
                        .font(ResponsiveFont.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .responsiveCard()
        .opacity(animateButtons ? 1.0 : 0.0)
        .offset(y: animateButtons ? 0 : 30)
        .animation(ResponsiveAnimation.default.delay(0.6), value: animateButtons)
    }
    
    // MARK: - Menu Buttons Section
    private var menuButtonsSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            
            // Start Game Button
            MenuButton(
                icon: "play.circle.fill",
                title: "Turnuva Başlat & Katıl",
                subtitle: "Yeni oda oluştur veya mevcut odaya katıl",
                color: .green,
                delay: 0.7,
                isAnimated: animateButtons,
                multipeerManager: multipeerManager
            ) {
                multipeerManager.playHaptic(style: .heavy)
                withAnimation(ResponsiveAnimation.fast) {
                    showMenu = false
                }
            }
            
            // How to Play Button
            MenuButton(
                icon: "questionmark.circle.fill",
                title: "Nasıl Oynanır?",
                subtitle: "Oyun kurallarını öğren",
                color: .blue,
                delay: 0.8,
                isAnimated: animateButtons,
                multipeerManager: multipeerManager
            ) {
                multipeerManager.playHaptic(style: .light)
                showHowToPlay = true
            }
            
            // Settings Button
            MenuButton(
                icon: "gearshape.fill",
                title: "Ayarlar",
                subtitle: "Oyun tercihlerini düzenle",
                color: .orange,
                delay: 0.9,
                isAnimated: animateButtons,
                multipeerManager: multipeerManager
            ) {
                multipeerManager.playHaptic(style: .light)
                showSettings = true
            }
        }
    }
    
    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: ResponsiveSpacing.small) {
            HStack(spacing: ResponsiveSpacing.medium) {
                Image(systemName: "wifi")
                    .foregroundColor(.white.opacity(0.6))
                
                Text("Yakındaki cihazları otomatik keşfet ve bağlan")
                    .font(ResponsiveFont.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.white.opacity(0.6))
            }
            .opacity(animateButtons ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.8).delay(1.0), value: animateButtons)
            
            Text("v1.0.0 • Made with ❤️")
                .font(ResponsiveFont.caption)
                .foregroundColor(.white.opacity(0.4))
                .opacity(animateButtons ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.8).delay(1.2), value: animateButtons)
        }
    }
}

// MARK: - Menu Button Component
struct MenuButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let delay: Double
    let isAnimated: Bool
    let multipeerManager: MultipeerManager
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            multipeerManager.playHaptic(style: .medium)
            
            // Action
            action()
        }) {
            HStack(spacing: ResponsiveSpacing.medium) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: ResponsiveSize.avatarSmall, height: ResponsiveSize.avatarSmall)
                    
                    Image(systemName: icon)
                        .font(ResponsiveFont.title2)
                        .foregroundColor(color)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: ResponsiveSpacing.tiny) {
                    Text(title)
                        .font(ResponsiveFont.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(ResponsiveFont.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(ResponsiveFont.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .responsiveCard()
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(ResponsiveAnimation.fast, value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .opacity(isAnimated ? 1.0 : 0.0)
        .offset(y: isAnimated ? 0 : 30)
        .animation(ResponsiveAnimation.default.delay(delay), value: isAnimated)
    }
}

// MARK: - Preview
#Preview {
    MenuView(
        showMenu: .constant(true),
        showProfileSetup: .constant(false),
        userProfile: .constant(UserProfile.load())
    )
    .environmentObject(MultipeerManager())
}
