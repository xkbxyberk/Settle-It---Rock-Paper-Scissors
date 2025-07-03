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
                                            .font(ResponsiveFont.callout)
                                            .fontWeight(.semibold)
                                            .opacity(toolbarOpacity)
                                            .scaleEffect(toolbarScale)
                                            .animation(
                                                ResponsiveAnimation.default.delay(0.2),
                                                value: toolbarOpacity
                                            )
                                        }
                                        
                                        ToolbarItem(placement: .navigationBarTrailing) {
                                            // Game phase indicator
                                            gamePhaseIndicator
                                                .opacity(toolbarOpacity)
                                                .scaleEffect(toolbarScale)
                                                .animation(
                                                    ResponsiveAnimation.default.delay(0.3),
                                                    value: toolbarOpacity
                                                )
                                        }
                                    }
                                    .onAppear {
                                        // Navigation Bar konfigürasyonunu uygula
                                        NavigationBarConfigurator.configureNavigationBar()
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
        // GameState değişikliklerini izle ve otomatik olarak ana menüye dön
        .onChange(of: multipeerManager.gameState) { _, newGameState in
            // Eğer GameState tamamen temizlenmişse (resetToMainMenu çağrıldıysa) ana menüye dön
            if newGameState.currentRoom == nil &&
               newGameState.players.isEmpty &&
               !showMenu {
                print("🔄 GameState temizlendi - Ana menüye dönülüyor")
                DispatchQueue.main.async {
                    showMenu = true
                }
            }
        }
        // MultipeerManager'dan ana menü isteği dinle
        .onChange(of: multipeerManager.shouldReturnToMainMenu) { _, shouldReturn in
            if shouldReturn && !showMenu {
                print("🔄 Ana menü isteği alındı - Ana menüye dönülüyor")
                DispatchQueue.main.async {
                    showMenu = true
                    multipeerManager.shouldReturnToMainMenu = false // Reset flag
                }
            }
        }
    }
    
    // MARK: - Game Phase View
    /// Oyunun mevcut aşamasına göre uygun view'u döndürür
    @ViewBuilder
    private var gamePhaseView: some View {
        switch multipeerManager.gameState.gamePhase {
        case .lobi:
            LobbyView(returnToMainMenu: returnToMainMenu) // Closure geç
            
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
        HStack(spacing: ResponsiveSpacing.small) {
            Circle()
                .fill(getPhaseColor())
                .frame(width: ResponsiveSize.iconSmall * 0.4, height: ResponsiveSize.iconSmall * 0.4)
                .animation(.easeInOut(duration: 0.3), value: multipeerManager.gameState.gamePhase)
            
            Text(getPhaseText())
                .font(ResponsiveFont.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, ResponsiveSpacing.medium)
        .padding(.vertical, ResponsiveSpacing.small)
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
            gameAnimationOffset = ScreenSize.width
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
            menuAnimationOffset = -ScreenSize.width
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
        gameAnimationOffset = ScreenSize.width
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
        menuAnimationOffset = -ScreenSize.width
        menuScale = 0.95
        menuRotation = 0
        
        // Oyun ekranı sağa doğru slide out + ana menü soldan slide in (eşzamanlı)
        withAnimation(.spring(response: response * 0.8, dampingFraction: damping + 0.1)) {
            // Oyun ekranı sağa kaydır
            gameAnimationOffset = ScreenSize.width
            gameScale = 0.9
            gameRotation = 5
            
            // Ana menü soldan merkeze gel
            menuAnimationOffset = 0
            menuScale = 1.0
            menuRotation = 0
        }
    }
    
    // Ana menüye dönüş fonksiyonu - güncellendi
    private func returnToMainMenu() {
        print("🔄 Ana menüye dönüş isteği - UI seviyesinde")
        
        // Önce MultipeerManager'ı temizle
        multipeerManager.resetGame()
        
        // Sonra UI'yi ana menüye çevir
        DispatchQueue.main.async {
            showMenu = true
        }
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
                
                ScrollView {
                    VStack(spacing: ResponsiveSpacing.large) {
                        
                        // MARK: - Header
                        VStack(spacing: ResponsiveSpacing.medium) {
                            Text("👤")
                                .font(ResponsiveFont.emoji(size: .medium))
                                .scaleEffect(animateContent ? 1.0 : 0.5)
                                .animation(ResponsiveAnimation.default.delay(0.1), value: animateContent)
                            
                            Text("Profil Ayarla")
                                .font(ResponsiveFont.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(y: animateContent ? 0 : 20)
                                .animation(ResponsiveAnimation.default.delay(0.3), value: animateContent)
                            
                            Text("Oyunda görünecek ismin ve avatarın")
                                .font(ResponsiveFont.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(y: animateContent ? 0 : 20)
                                .animation(ResponsiveAnimation.default.delay(0.4), value: animateContent)
                        }
                        
                        // MARK: - Profile Preview
                        VStack(spacing: ResponsiveSpacing.medium) {
                            // Avatar Display
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: ResponsiveSize.avatarExtraLarge, height: ResponsiveSize.avatarExtraLarge)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                    )
                                
                                Text(tempAvatar)
                                    .font(ResponsiveFont.emoji(size: .medium))
                            }
                            .scaleEffect(animateContent ? 1.0 : 0.3)
                            .animation(ResponsiveAnimation.default.delay(0.5), value: animateContent)
                            
                            // Nickname Input
                            VStack(alignment: .leading, spacing: ResponsiveSpacing.small) {
                                Text("Kullanıcı Adı")
                                    .font(ResponsiveFont.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                TextField("Kullanıcı adını gir", text: $tempNickname)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(ResponsiveFont.body)
                                    .autocapitalization(.words)
                                    .disableAutocorrection(true)
                            }
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 30)
                            .animation(ResponsiveAnimation.default.delay(0.6), value: animateContent)
                        }
                        
                        // MARK: - Avatar Selection
                        VStack(alignment: .leading, spacing: ResponsiveSpacing.medium) {
                            Text("Avatar Seç")
                                .font(ResponsiveFont.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            // Category Tabs
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: ResponsiveSpacing.medium) {
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
                                .padding(.horizontal, ResponsiveSpacing.tiny)
                            }
                            
                            // Avatar Grid for Selected Category
                            ScrollView {
                                LazyVGrid(columns: ResponsiveGrid.avatarColumns, spacing: ResponsiveSpacing.medium) {
                                    ForEach(AvatarOptions.categories[selectedCategory].emojis, id: \.self) { avatar in
                                        Button(action: {
                                            tempAvatar = avatar
                                            multipeerManager.playHaptic(style: .light)
                                        }) {
                                            Text(avatar)
                                                .font(ResponsiveFont.emoji(size: .small))
                                                .frame(width: ResponsiveSize.avatarSmall, height: ResponsiveSize.avatarSmall)
                                                .background(
                                                    Circle()
                                                        .fill(tempAvatar == avatar ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
                                                        .overlay(
                                                            Circle()
                                                                .stroke(tempAvatar == avatar ? Color.white : Color.white.opacity(0.3), lineWidth: 2)
                                                        )
                                                )
                                                .scaleEffect(tempAvatar == avatar ? 1.1 : 1.0)
                                                .animation(ResponsiveAnimation.fast, value: tempAvatar)
                                        }
                                    }
                                }
                                .padding(.vertical, ResponsiveSpacing.small)
                            }
                            .frame(maxHeight: DeviceType.current == .phone ? 300 : 400)
                        }
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 30)
                        .animation(ResponsiveAnimation.default.delay(0.7), value: animateContent)
                        
                        Spacer()
                        
                        // MARK: - Action Buttons
                        HStack(spacing: ResponsiveSpacing.medium) {
                            Button("İptal") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.vertical, ResponsiveSpacing.medium)
                            .padding(.horizontal, ResponsiveSpacing.large)
                            .background(
                                RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
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
                            .padding(.vertical, ResponsiveSpacing.medium)
                            .padding(.horizontal, ResponsiveSpacing.large)
                            .background(
                                RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                                    .fill(Color.blue)
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            )
                            .disabled(tempNickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(tempNickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                        }
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(ResponsiveAnimation.default.delay(0.8), value: animateContent)
                    }
                    .padding(.horizontal, ResponsivePadding.horizontal)
                    .padding(.top, ResponsivePadding.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
                    // Navigation Bar konfigürasyonunu uygula
                    NavigationBarConfigurator.configureNavigationBar()
                    
                    tempNickname = userProfile.nickname
                    tempAvatar = userProfile.avatar
                    
                    withAnimation(ResponsiveAnimation.default.delay(0.2)) {
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
            VStack(spacing: ResponsiveSpacing.small) {
                Image(systemName: icon)
                    .font(ResponsiveFont.title3)
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.7))
                
                Text(title)
                    .font(ResponsiveFont.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.7))
            }
            .padding(.horizontal, ResponsiveSpacing.medium)
            .padding(.vertical, ResponsiveSpacing.small)
            .background(
                RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                            .stroke(isSelected ? Color.clear : Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(ResponsiveAnimation.fast, value: isSelected)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
