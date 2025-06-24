import SwiftUI

struct MenuView: View {
    
    // MARK: - Properties
    @Binding var showMenu: Bool
    @EnvironmentObject var multipeerManager: MultipeerManager
    @State private var showHowToPlay = false
    @State private var showSettings = false
    @State private var animateButtons = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                
                // MARK: - Header Section
                headerSection
                
                // MARK: - Menu Buttons
                menuButtonsSection
                
                // MARK: - Footer
                footerSection
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
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
        VStack(spacing: 20) {
            // App Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.white.opacity(0.3), .white.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 2)
                    )
                
                Text("🎯")
                    .font(.system(size: 60))
                    .scaleEffect(animateButtons ? 1.0 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateButtons)
            }
            
            VStack(spacing: 12) {
                Text("Taş Kağıt Makas")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(animateButtons ? 1.0 : 0.0)
                    .offset(y: animateButtons ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3), value: animateButtons)
                
                Text("Turnuva")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(animateButtons ? 1.0 : 0.0)
                    .offset(y: animateButtons ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4), value: animateButtons)
                
                Text("Arkadaşlarınla multiplayer turnuva yap!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .opacity(animateButtons ? 1.0 : 0.0)
                    .offset(y: animateButtons ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5), value: animateButtons)
            }
        }
    }
    
    // MARK: - Menu Buttons Section
    private var menuButtonsSection: some View {
        VStack(spacing: 20) {
            
            // Start Game Button
            MenuButton(
                icon: "play.circle.fill",
                title: "Turnuva Başlat",
                subtitle: "Yakındaki oyuncularla bağlan",
                color: .green,
                delay: 0.6,
                isAnimated: animateButtons
            ) {
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showMenu = false
                }
            }
            
            // How to Play Button
            MenuButton(
                icon: "questionmark.circle.fill",
                title: "Nasıl Oynanır?",
                subtitle: "Oyun kurallarını öğren",
                color: .blue,
                delay: 0.7,
                isAnimated: animateButtons
            ) {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                showHowToPlay = true
            }
            
            // Settings Button
            MenuButton(
                icon: "gearshape.fill",
                title: "Ayarlar",
                subtitle: "Oyun tercihlerini düzenle",
                color: .orange,
                delay: 0.8,
                isAnimated: animateButtons
            ) {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                showSettings = true
            }
        }
    }
    
    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: "wifi")
                    .foregroundColor(.white.opacity(0.6))
                
                Text("Wi-Fi veya Bluetooth ile otomatik bağlanır")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.white.opacity(0.6))
            }
            .opacity(animateButtons ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.8).delay(1.0), value: animateButtons)
            
            Text("v1.0.0 • Made with ❤️")
                .font(.caption2)
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
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Action
            action()
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(isPressed ? 0.3 : 0.15),
                                Color.white.opacity(isPressed ? 0.1 : 0.05)
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
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .opacity(isAnimated ? 1.0 : 0.0)
        .offset(y: isAnimated ? 0 : 30)
        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(delay), value: isAnimated)
    }
}

// MARK: - Preview
#Preview {
    MenuView(showMenu: .constant(true))
        .environmentObject(MultipeerManager())
}
