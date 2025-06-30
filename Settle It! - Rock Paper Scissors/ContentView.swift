import SwiftUI

struct ContentView: View {
    
    // MARK: - Properties
    /// Menünün gösterilip gösterilmediğini kontrol eder
    @State private var showMenu = true
    
    /// Profil setup ekranının gösterilip gösterilmediğini kontrol eder
    @State private var showProfileSetup = false
    
    /// Uygulamanın ana ağ yöneticisi - lazy initialization
    @StateObject private var multipeerManager = MultipeerManager()
    
    /// Kullanıcı profili
    @State private var userProfile = UserProfile.load()
    
    // MARK: - Animation States
    @State private var menuAnimationOffset: CGFloat = 0
    @State private var gameAnimationOffset: CGFloat = 0
    @State private var menuScale: CGFloat = 1.0
    @State private var gameScale: CGFloat = 1.0
    @State private var menuRotation: Double = 0
    @State private var gameRotation: Double = 0
    @State private var toolbarOpacity: Double = 0
    @State private var toolbarScale: CGFloat = 0.8
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Ana gradient background - her zaman görünür
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if showMenu {
                // Ana menü
                MenuView(
                    showMenu: $showMenu,
                    showProfileSetup: $showProfileSetup,
                    userProfile: $userProfile
                )
                .environmentObject(multipeerManager)
                .offset(y: menuAnimationOffset)
                .scaleEffect(menuScale)
                .rotation3DEffect(
                    .degrees(menuRotation),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.8
                )
                .opacity(showMenu ? 1.0 : 0.0)
                
            } else {
                // Oyun ekranları
                NavigationView {
                    ZStack {
                        // Gradient arkaplan
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()
                        
                        // Ana içerik - oyun aşamasına göre değişir
                        gamePhaseView
                            .offset(y: gameAnimationOffset)
                            .scaleEffect(gameScale)
                            .rotation3DEffect(
                                .degrees(gameRotation),
                                axis: (x: 1, y: 0, z: 0),
                                perspective: 0.8
                            )
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Ana Menü") {
                                returnToMainMenu()
                            }
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                            .opacity(toolbarOpacity)
                            .scaleEffect(toolbarScale)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8).delay(0.2),
                                value: toolbarOpacity
                            )
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            // Game phase indicator
                            gamePhaseIndicator
                                .opacity(toolbarOpacity)
                                .scaleEffect(toolbarScale)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.8).delay(0.3),
                                    value: toolbarOpacity
                                )
                        }
                    }
                }
                .environmentObject(multipeerManager)
                .opacity(showMenu ? 0.0 : 1.0)
                .alert(item: $multipeerManager.connectionAlert) { (alert: ConnectionAlert) in
                    Alert(
                        title: Text(alert.title),
                        message: Text(alert.message),
                        dismissButton: .default(Text("Tamam"))
                    )
                }
            }
        }
        .sheet(isPresented: $showProfileSetup) {
            ProfileSetupView(userProfile: $userProfile)
                .environmentObject(multipeerManager)
        }
        .onAppear {
            // Kullanıcı profili yüklendikten sonra multipeerManager'a aktar
            multipeerManager.updateUserProfile(userProfile)
            setupInitialAnimationStates()
        }
        .onChange(of: userProfile) { _, newProfile in
            // Profil değiştiğinde multipeerManager'ı güncelle
            multipeerManager.updateUserProfile(newProfile)
        }
        .onChange(of: showMenu) { _, isShowingMenu in
            handleMenuTransition(isShowingMenu: isShowingMenu)
        }
    }
    
    // MARK: - Game Phase View
    /// Oyunun mevcut aşamasına göre uygun view'u döndürür
    @ViewBuilder
    private var gamePhaseView: some View {
        switch multipeerManager.gameState.gamePhase {
        case .lobi:
            LobbyView()
            
        case .oylama:
            VotingView()
            
        case .geriSayim, .turOynaniyor:
            GamePlayView()
            
        case .sonucGosteriliyor:
            ResultsView()
            
        case .oyunBitti:
            GameOverView()
        }
    }
    
    // MARK: - Game Phase Indicator
    @ViewBuilder
    private var gamePhaseIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(getPhaseColor())
                .frame(width: 8, height: 8)
                .animation(.easeInOut(duration: 0.3), value: multipeerManager.gameState.gamePhase)
            
            Text(getPhaseText())
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Animation Methods
    private func setupInitialAnimationStates() {
        if showMenu {
            // Ana menü başlangıç durumu
            menuAnimationOffset = 0
            menuScale = 1.0
            menuRotation = 0
            toolbarOpacity = 0
            toolbarScale = 0.8
            
            // Oyun ekranını sağda gizli konumda hazırla
            gameAnimationOffset = UIScreen.main.bounds.width
            gameScale = 0.9
            gameRotation = 5
        } else {
            // Oyun ekranı açık durumu
            gameAnimationOffset = 0
            gameScale = 1.0
            gameRotation = 0
            toolbarOpacity = 1.0
            toolbarScale = 1.0
            
            // Ana menüyü solda gizli konumda hazırla
            menuAnimationOffset = -UIScreen.main.bounds.width
            menuScale = 0.95
            menuRotation = 0
        }
    }
    
    private func handleMenuTransition(isShowingMenu: Bool) {
        let shouldAnimate = multipeerManager.settings.animations
        let animationDuration: Double = shouldAnimate ? 0.8 : 0.1
        let springResponse: Double = shouldAnimate ? 0.7 : 0.2
        let springDamping: Double = shouldAnimate ? 0.8 : 1.0
        
        if isShowingMenu {
            // Ana menüye dönüş animasyonu
            animateToMenu(duration: animationDuration, response: springResponse, damping: springDamping)
        } else {
            // Oyun ekranına geçiş animasyonu
            animateToGame(duration: animationDuration, response: springResponse, damping: springDamping)
        }
    }
    
    private func animateToGame(duration: Double, response: Double, damping: Double) {
        // Haptic feedback
        multipeerManager.playHaptic(style: .heavy)
        
        // Ana menü çıkış animasyonu (yukarıya doğru slide + scale down + rotate)
        withAnimation(.spring(response: response, dampingFraction: damping)) {
            menuAnimationOffset = -150
            menuScale = 0.7
            menuRotation = 20
        }
        
        // Oyun ekranını sağdan merkeze getir (aşağıdan yukarı yerine)
        gameAnimationOffset = UIScreen.main.bounds.width
        gameScale = 0.9
        gameRotation = 5
        
        DispatchQueue.main.asyncAfter(deadline: .now() + (duration * 0.2)) {
            withAnimation(.spring(response: response, dampingFraction: damping).delay(0.1)) {
                gameAnimationOffset = 0
                gameScale = 1.0
                gameRotation = 0
            }
            
            // Toolbar elementlerini sırayla göster
            withAnimation(.spring(response: response, dampingFraction: damping).delay(0.3)) {
                toolbarOpacity = 1.0
                toolbarScale = 1.0
            }
        }
    }
    
    private func animateToMenu(duration: Double, response: Double, damping: Double) {
        // Haptic feedback
        multipeerManager.playHaptic(style: .medium)
        
        // Toolbar elementlerini hızlıca gizle
        withAnimation(.easeOut(duration: 0.2)) {
            toolbarOpacity = 0
            toolbarScale = 0.9
        }
        
        // Ana menüyü hemen hazır konuma getir (soldan gelecek gibi)
        menuAnimationOffset = -UIScreen.main.bounds.width
        menuScale = 0.95
        menuRotation = 0
        
        // Oyun ekranı sağa doğru slide out + ana menü soldan slide in (eşzamanlı)
        withAnimation(.spring(response: response * 0.8, dampingFraction: damping + 0.1)) {
            // Oyun ekranı sağa kaydır
            gameAnimationOffset = UIScreen.main.bounds.width
            gameScale = 0.9
            gameRotation = 5
            
            // Ana menü soldan merkeze gel
            menuAnimationOffset = 0
            menuScale = 1.0
            menuRotation = 0
        }
    }
    
    private func returnToMainMenu() {
        multipeerManager.resetGame()
        showMenu = true
    }
    
    // MARK: - Helper Methods
    private func getPhaseColor() -> Color {
        switch multipeerManager.gameState.gamePhase {
        case .lobi: return .blue
        case .oylama: return .orange
        case .geriSayim: return .yellow
        case .turOynaniyor: return .green
        case .sonucGosteriliyor: return .purple
        case .oyunBitti: return .red
        }
    }
    
    private func getPhaseText() -> String {
        switch multipeerManager.gameState.gamePhase {
        case .lobi: return "Lobi"
        case .oylama: return "Oylama"
        case .geriSayim: return "Hazırlık"
        case .turOynaniyor: return "Oyun"
        case .sonucGosteriliyor: return "Sonuç"
        case .oyunBitti: return "Bitti"
        }
    }
}

// MARK: - Profile Setup View
struct ProfileSetupView: View {
    @Binding var userProfile: UserProfile
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var multipeerManager: MultipeerManager
    @State private var tempNickname: String = ""
    @State private var tempAvatar: String = ""
    @State private var animateContent = false
    @State private var selectedCategory = 0
    
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
                
                VStack(spacing: 25) {
                    
                    // MARK: - Header
                    VStack(spacing: 16) {
                        Text("👤")
                            .font(.system(size: 50))
                            .scaleEffect(animateContent ? 1.0 : 0.5)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateContent)
                        
                        Text("Profil Ayarla")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3), value: animateContent)
                        
                        Text("Oyunda görünecek ismin ve avatarın")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4), value: animateContent)
                    }
                    
                    // MARK: - Profile Preview
                    VStack(spacing: 20) {
                        // Avatar Display
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                )
                            
                            Text(tempAvatar)
                                .font(.system(size: 50))
                        }
                        .scaleEffect(animateContent ? 1.0 : 0.3)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5), value: animateContent)
                        
                        // Nickname Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Kullanıcı Adı")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            TextField("Kullanıcı adını gir", text: $tempNickname)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                                .autocapitalization(.words)
                                .disableAutocorrection(true)
                        }
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 30)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.6), value: animateContent)
                    }
                    
                    // MARK: - Avatar Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Avatar Seç")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        // Category Tabs
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(AvatarOptions.categories.enumerated()), id: \.offset) { index, category in
                                    CategoryTabButton(
                                        icon: category.icon,
                                        title: category.name,
                                        isSelected: selectedCategory == index,
                                        multipeerManager: multipeerManager
                                    ) {
                                        selectedCategory = index
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        
                        // Avatar Grid for Selected Category
                        ScrollView {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                ForEach(AvatarOptions.categories[selectedCategory].emojis, id: \.self) { avatar in
                                    Button(action: {
                                        tempAvatar = avatar
                                        multipeerManager.playHaptic(style: .light)
                                    }) {
                                        Text(avatar)
                                            .font(.system(size: 30))
                                            .frame(width: 50, height: 50)
                                            .background(
                                                Circle()
                                                    .fill(tempAvatar == avatar ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
                                                    .overlay(
                                                        Circle()
                                                            .stroke(tempAvatar == avatar ? Color.white : Color.white.opacity(0.3), lineWidth: 2)
                                                    )
                                            )
                                            .scaleEffect(tempAvatar == avatar ? 1.1 : 1.0)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: tempAvatar)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .frame(maxHeight: 300)
                    }
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 30)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.7), value: animateContent)
                    
                    Spacer()
                    
                    // MARK: - Action Buttons
                    HStack(spacing: 16) {
                        Button("İptal") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.2))
                        )
                        
                        Button("Kaydet") {
                            // Profili güncelle ve kaydet
                            userProfile.nickname = tempNickname.isEmpty ? "Oyuncu" : tempNickname
                            userProfile.avatar = tempAvatar
                            userProfile.save()
                            
                            multipeerManager.playHaptic(style: .success)
                            
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        )
                        .disabled(tempNickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(tempNickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                    }
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.8), value: animateContent)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            tempNickname = userProfile.nickname
            tempAvatar = userProfile.avatar
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Category Tab Button
struct CategoryTabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let multipeerManager: MultipeerManager
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            multipeerManager.playHaptic(style: .light)
            action()
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.7))
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.clear : Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
