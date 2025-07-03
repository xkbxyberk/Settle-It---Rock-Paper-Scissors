import SwiftUI

struct ResultsView: View {
    
    // MARK: - Properties
    /// MultipeerManager'dan geçirilen environment object
    @EnvironmentObject var multipeerManager: MultipeerManager
    
    /// Aşamalı gösterim için animasyon state'leri
    @State private var showHeader = false
    @State private var showChoicesSummary = false
    @State private var showAnalysis = false
    @State private var showEliminatedPlayers = false
    @State private var showContinuingPlayers = false
    @State private var showFinalMessage = false
    
    /// Elenen oyuncuları hesaplar
    private var eliminatedPlayers: [Player] {
        // Choices'da olan ama activePlayers'da olmayan oyuncuları bul
        let choicePlayerDeviceIDs = Set(multipeerManager.gameState.choices.keys)
        let activePlayerDeviceIDs = Set(multipeerManager.gameState.activePlayers.map { $0.deviceID })
        let eliminatedDeviceIDs = choicePlayerDeviceIDs.subtracting(activePlayerDeviceIDs)
        
        // Player objelerini bul
        return multipeerManager.gameState.players.filter { player in
            eliminatedDeviceIDs.contains(player.deviceID)
        }
    }
    
    /// Sonuçları analiz eder
    private var roundAnalysis: (hasEliminations: Bool, winningChoice: Choice?, losingChoice: Choice?) {
        let uniqueChoices = Set(multipeerManager.gameState.choices.values)
        
        if uniqueChoices.count == 2 && !eliminatedPlayers.isEmpty {
            // İki farklı seçim var ve eliminasyon olmuş
            let choicesArray = Array(uniqueChoices)
            let choice1 = choicesArray[0]
            let choice2 = choicesArray[1]
            
            let winningChoice = determineWinner(choice1: choice1, choice2: choice2)
            let losingChoice = winningChoice == choice1 ? choice2 : choice1
            
            return (hasEliminations: true, winningChoice: winningChoice, losingChoice: losingChoice)
        }
        
        return (hasEliminations: false, winningChoice: nil, losingChoice: nil)
    }
    
    /// Oyunun bitmek üzere olup olmadığını kontrol eder
    private var isGameEndingSoon: Bool {
        return multipeerManager.gameState.activePlayers.count <= 1
    }
    
    /// Oyuncu sayısına göre uygun başlık belirleme
    private var continuingPlayersTitle: (icon: String, title: String) {
        let activeCount = multipeerManager.gameState.activePlayers.count
        let totalCount = multipeerManager.gameState.players.count
        
        switch (activeCount, totalCount) {
        case (1, 2):
            return ("👑", "Kazanan")
        case (1, _):
            return ("👑", "Büyük Kazanan")
        case (2, 2):
            return ("⚔️", "Her İki Oyuncu Devam Ediyor")
        case (2, _):
            return ("🔥", "Finale Kalan Oyuncular")
        case (3, _):
            return ("⚡️", "Son 3 Oyuncu")
        case (4, _):
            return ("💪", "Yarı-Finale Kalan Oyuncular")
        default:
            return ("🌟", "Devam Eden Oyuncular")
        }
    }
    
    // MARK: - Body
    var body: some View {
        ResponsiveContainer {
            VStack(spacing: ResponsiveSpacing.extraLarge) {
                
                // MARK: - Header
                if showHeader {
                    headerSection
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // MARK: - Choices Summary
                if showChoicesSummary {
                    choicesSummaryView
                        .transition(.scale.combined(with: .opacity))
                }
                
                // MARK: - Round Analysis
                if showAnalysis {
                    roundAnalysisSection
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
                
                // MARK: - Eliminated Players
                if showEliminatedPlayers {
                    eliminationResultsSection
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // MARK: - Continuing Players
                if showContinuingPlayers {
                    continuingPlayersSection
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
                
                // MARK: - Final Message
                if showFinalMessage {
                    finalMessageSection
                        .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
            }
        }
        .onAppear {
            startProgressiveDisplay()
        }
    }
    
    // MARK: - Progressive Display Logic
    private func startProgressiveDisplay() {
        // Reset all states
        showHeader = false
        showChoicesSummary = false
        showAnalysis = false
        showEliminatedPlayers = false
        showContinuingPlayers = false
        showFinalMessage = false
        
        // Progressive display with haptic feedback
        
        // 1. Header (hemen)
        withAnimation(ResponsiveAnimation.default) {
            showHeader = true
        }
        multipeerManager.playHaptic(style: .light)
        
        // 2. Choices Summary (1.5 saniye sonra)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(ResponsiveAnimation.default) {
                showChoicesSummary = true
            }
            multipeerManager.playHaptic(style: .light)
        }
        
        // 3. Analysis (3 saniye sonra)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(ResponsiveAnimation.default) {
                showAnalysis = true
            }
            multipeerManager.playHaptic(style: .medium)
        }
        
        // 4. Eliminated Players (4.5 saniye sonra)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            withAnimation(ResponsiveAnimation.default) {
                showEliminatedPlayers = true
            }
            if !eliminatedPlayers.isEmpty {
                multipeerManager.playHaptic(style: .warning)
            } else {
                multipeerManager.playHaptic(style: .success)
            }
        }
        
        // 5. Continuing Players (5.5 saniye sonra)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            withAnimation(ResponsiveAnimation.default) {
                showContinuingPlayers = true
            }
            multipeerManager.playHaptic(style: .light)
        }
        
        // 6. Final Message (6.5 saniye sonra - sadece son tur ise)
        if isGameEndingSoon {
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.5) {
                withAnimation(ResponsiveAnimation.default) {
                    showFinalMessage = true
                }
                multipeerManager.playHaptic(style: .heavy)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            Text("📊")
                .font(ResponsiveFont.emoji(size: .medium))
                .scaleEffect(1.2)
            
            Text("Tur \(multipeerManager.gameState.currentRound) Sonuçları")
                .font(ResponsiveFont.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Choices Summary View
    private var choicesSummaryView: some View {
        VStack(alignment: .leading, spacing: ResponsiveSpacing.medium) {
            HStack {
                Text("🎯 Bu Turdaki Seçimler")
                    .font(ResponsiveFont.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(multipeerManager.gameState.choices.count) oyuncu")
                    .font(ResponsiveFont.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, ResponsiveSpacing.small)
                    .padding(.vertical, ResponsiveSpacing.tiny)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            choicesGridView
        }
        .responsiveCard()
    }
    
    // MARK: - Choices Grid View
    private var choicesGridView: some View {
        let choiceGroups = Dictionary(grouping: multipeerManager.gameState.choices) { $0.value }
        
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: ResponsiveSpacing.medium) {
            ForEach([Choice.tas, .kagit, .makas], id: \.self) { choice in
                ChoiceCardView(
                    choice: choice,
                    players: getPlayersForChoice(choice, from: choiceGroups)
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    private func getPlayersForChoice(_ choice: Choice, from choiceGroups: [Choice: [(key: String, value: Choice)]]) -> [Player] {
        return choiceGroups[choice]?.compactMap { deviceID in
            multipeerManager.gameState.players.first { $0.deviceID == deviceID.key }
        } ?? []
    }
    
    // MARK: - Round Analysis Section
    private var roundAnalysisSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            
            // Kazanan/kaybeden analizi
            if roundAnalysis.hasEliminations,
               let winningChoice = roundAnalysis.winningChoice,
               let losingChoice = roundAnalysis.losingChoice {
                
                VStack(spacing: ResponsiveSpacing.medium) {
                    Text("⚔️ Sonuç Analizi")
                        .font(ResponsiveFont.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: ResponsiveSpacing.large) {
                        // Kazanan
                        VStack(spacing: ResponsiveSpacing.small) {
                            Text(getChoiceIcon(winningChoice))
                                .font(ResponsiveFont.emoji(size: .small))
                            
                            Text(winningChoice.rawValue)
                                .font(ResponsiveFont.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            
                            Text("KAZANAN")
                                .font(ResponsiveFont.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.green.opacity(0.8))
                        }
                        .padding(.vertical, ResponsiveSpacing.medium)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                                .fill(Color.green.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                                        .stroke(Color.green.opacity(0.4), lineWidth: 2)
                                )
                        )
                        
                        Text("⚡️")
                            .font(ResponsiveFont.title2)
                            .foregroundColor(.yellow)
                        
                        // Kaybeden
                        VStack(spacing: ResponsiveSpacing.small) {
                            Text(getChoiceIcon(losingChoice))
                                .font(ResponsiveFont.emoji(size: .small))
                                .opacity(0.6)
                            
                            Text(losingChoice.rawValue)
                                .font(ResponsiveFont.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                            
                            Text("KAYBEDEN")
                                .font(ResponsiveFont.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .padding(.vertical, ResponsiveSpacing.medium)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                                .fill(Color.red.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                                        .stroke(Color.red.opacity(0.4), lineWidth: 2)
                                )
                        )
                    }
                }
                .responsiveCard()
                
            } else {
                // Beraberlik durumu
                VStack(spacing: ResponsiveSpacing.medium) {
                    Text("🤝 Beraberlik!")
                        .font(ResponsiveFont.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Bu turda kimse elenmedi")
                        .font(ResponsiveFont.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.vertical, ResponsiveSpacing.medium)
                .frame(maxWidth: .infinity)
                .responsiveCard(backgroundColor: Color.blue.opacity(0.2), borderColor: Color.blue.opacity(0.4))
            }
        }
    }
    
    // MARK: - Elimination Results Section
    private var eliminationResultsSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            
            if eliminatedPlayers.isEmpty {
                // Kimse elenmemiş
                VStack(spacing: ResponsiveSpacing.medium) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(ResponsiveFont.emoji(size: .medium))
                        .foregroundColor(.green)
                    
                    Text("Bu Turda Kimse Elenmedi!")
                        .font(ResponsiveFont.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Herkes bir sonraki tura geçiyor")
                        .font(ResponsiveFont.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.vertical, ResponsiveSpacing.extraLarge)
                .frame(maxWidth: .infinity)
                .responsiveCard(backgroundColor: Color.green.opacity(0.2), borderColor: Color.green.opacity(0.4))
                
            } else {
                // Eliminasyon var
                VStack(alignment: .leading, spacing: ResponsiveSpacing.medium) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(ResponsiveFont.title2)
                            .foregroundColor(.red)
                        
                        Text(eliminatedPlayersTitle)
                            .font(ResponsiveFont.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(eliminatedPlayers.count)")
                            .font(ResponsiveFont.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .padding(.horizontal, ResponsiveSpacing.small)
                            .padding(.vertical, ResponsiveSpacing.tiny)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    
                    LazyVStack(spacing: ResponsiveSpacing.small) {
                        ForEach(eliminatedPlayers, id: \.id) { player in
                            EliminatedPlayerRow(
                                player: player,
                                choice: multipeerManager.gameState.choices[player.deviceID]
                            )
                        }
                    }
                    
                    if !eliminatedPlayers.isEmpty {
                        HStack {
                            Spacer()
                            Text(eliminationMessage)
                                .font(ResponsiveFont.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.red.opacity(0.8))
                                .italic()
                            Spacer()
                        }
                        .padding(.top, ResponsiveSpacing.small)
                    }
                }
                .responsiveCard(backgroundColor: Color.red.opacity(0.2), borderColor: Color.red.opacity(0.4))
            }
        }
    }
    
    // MARK: - Continuing Players Section
    private var continuingPlayersSection: some View {
        VStack(alignment: .leading, spacing: ResponsiveSpacing.medium) {
            HStack {
                Text(continuingPlayersTitle.icon)
                    .font(ResponsiveFont.title2)
                
                Text(continuingPlayersTitle.title)
                    .font(ResponsiveFont.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(multipeerManager.gameState.activePlayers.count)")
                    .font(ResponsiveFont.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, ResponsiveSpacing.small)
                    .padding(.vertical, ResponsiveSpacing.tiny)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            if multipeerManager.gameState.activePlayers.isEmpty {
                Text("Hiç oyuncu kalmadı")
                    .font(ResponsiveFont.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .italic()
            } else {
                LazyVGrid(columns: ResponsiveGrid.playerColumns, spacing: ResponsiveSpacing.small) {
                    ForEach(multipeerManager.gameState.activePlayers, id: \.id) { player in
                        ContinuingPlayerRow(
                            player: player,
                            choice: multipeerManager.gameState.choices[player.deviceID]
                        )
                    }
                }
                
                // Devam eden oyuncular için motivasyon mesajı
                if shouldShowMotivationalMessage {
                    HStack {
                        Spacer()
                        Text(motivationalMessage)
                            .font(ResponsiveFont.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue.opacity(0.9))
                            .italic()
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding(.top, ResponsiveSpacing.small)
                }
            }
        }
        .responsiveCard(backgroundColor: Color.blue.opacity(0.2), borderColor: Color.blue.opacity(0.4))
    }
    
    // MARK: - Final Message Section
    private var finalMessageSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            if isGameEndingSoon {
                VStack(spacing: ResponsiveSpacing.medium) {
                    Text("🏁")
                        .font(ResponsiveFont.emoji(size: .medium))
                    
                    Text("Turnuva Sona Eriyor!")
                        .font(ResponsiveFont.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if multipeerManager.gameState.activePlayers.count == 1 {
                        Text("Kazanan belirlendi! Final sonuçları gösteriliyor...")
                    } else {
                        Text("Turnuva tamamlandı. Sonuçlar hazırlanıyor...")
                    }
                }
                .padding(.vertical, ResponsiveSpacing.large)
                .frame(maxWidth: .infinity)
                .responsiveCard(backgroundColor: Color.purple.opacity(0.3), borderColor: Color.purple.opacity(0.5))
            }
        }
    }
    
    // MARK: - Helper Properties
    private var eliminatedPlayersTitle: String {
        let totalCount = multipeerManager.gameState.players.count
        let eliminatedCount = eliminatedPlayers.count
        
        if totalCount == 2 {
            return "Kaybeden Oyuncu"
        } else if eliminatedCount == 1 {
            return "Elenen Oyuncu"
        } else {
            return "Elenen Oyuncular"
        }
    }
    
    private var eliminationMessage: String {
        let totalCount = multipeerManager.gameState.players.count
        
        if totalCount == 2 {
            return "Turda kaybetti! 😔"
        } else {
            return "Veda! 👋"
        }
    }
    
    private var shouldShowMotivationalMessage: Bool {
        let remainingCount = multipeerManager.gameState.activePlayers.count
        let totalCount = multipeerManager.gameState.players.count
        
        // 2 kişi oynarken ve her ikisi de devam ediyorsa mesaj gösterme
        if totalCount == 2 && remainingCount == 2 {
            return false
        }
        
        // 1 kişi kaldıysa (kazandıysa) mesaj gösterme
        if remainingCount <= 1 {
            return false
        }
        
        return true
    }
    
    private var motivationalMessage: String {
        let remainingCount = multipeerManager.gameState.activePlayers.count
        let totalCount = multipeerManager.gameState.players.count
        
        switch remainingCount {
        case 2:
            if totalCount == 2 {
                return "🤝 İki oyuncu da devam ediyor! Bir sonraki turda kazanan belli olacak!"
            } else {
                return "🔥 Final savaşı yakında! İyi şanslar!"
            }
        case 3:
            return "⚔️ Son 3 oyuncu! Hanginiz finale kalacak?"
        case 4:
            return "💪 Yarı-final zamanı! Güçlü kalın!"
        default:
            return "🌟 Mücadele devam ediyor! Bir sonraki tura hazır olun!"
        }
    }
    
    // MARK: - Helper Methods
    private func getChoiceIcon(_ choice: Choice) -> String {
        switch choice {
        case .tas: return "🪨"
        case .kagit: return "📄"
        case .makas: return "✂️"
        }
    }
    
    private func determineWinner(choice1: Choice, choice2: Choice) -> Choice {
        switch (choice1, choice2) {
        case (.tas, .makas), (.makas, .tas):
            return .tas // Taş makası yener
        case (.makas, .kagit), (.kagit, .makas):
            return .makas // Makas kağıdı yener
        case (.kagit, .tas), (.tas, .kagit):
            return .kagit // Kağıt taşı yener
        default:
            return choice1
        }
    }
}

// MARK: - Choice Card View
struct ChoiceCardView: View {
    let choice: Choice
    let players: [Player]
    
    var body: some View {
        VStack(spacing: ResponsiveSpacing.small) {
            Text(getChoiceIcon(choice))
                .font(ResponsiveFont.emoji(size: .small))
            
            Text(choice.rawValue)
                .font(ResponsiveFont.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
            
            Text("\(players.count) oyuncu")
                .font(ResponsiveFont.caption)
                .foregroundColor(.white.opacity(0.7))
            
            // Oyuncuların avatarları
            if !players.isEmpty {
                playersAvatarsView
            }
        }
        .padding(.vertical, ResponsiveSpacing.medium)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                .fill(players.isEmpty ? Color.white.opacity(0.05) : Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                        .stroke(Color.white.opacity(players.isEmpty ? 0.1 : 0.3), lineWidth: 1)
                )
        )
        .opacity(players.isEmpty ? 0.5 : 1.0)
    }
    
    private var playersAvatarsView: some View {
        HStack(spacing: -ResponsiveSpacing.tiny) {
            ForEach(players.prefix(3), id: \.id) { player in
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: ResponsiveSize.iconMedium, height: ResponsiveSize.iconMedium)
                    
                    Text(player.avatar)
                        .font(.system(size: ResponsiveSize.iconMedium * 0.5))
                }
            }
            
            if players.count > 3 {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: ResponsiveSize.iconMedium, height: ResponsiveSize.iconMedium)
                    
                    Text("+\(players.count - 3)")
                        .font(ResponsiveFont.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func getChoiceIcon(_ choice: Choice) -> String {
        switch choice {
        case .tas: return "🪨"
        case .kagit: return "📄"
        case .makas: return "✂️"
        }
    }
}

// MARK: - Eliminated Player Row
struct EliminatedPlayerRow: View {
    let player: Player
    let choice: Choice?
    
    var body: some View {
        HStack(spacing: ResponsiveSpacing.medium) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.3))
                    .frame(width: ResponsiveSize.avatarSmall, height: ResponsiveSize.avatarSmall)
                    .overlay(
                        Circle()
                            .stroke(Color.red.opacity(0.5), lineWidth: 2)
                    )
                
                Text(player.avatar)
                    .font(.system(size: ResponsiveSize.avatarSmall * 0.7))
                    .grayscale(0.5) // Slightly desaturated
            }
            
            // Player info
            VStack(alignment: .leading, spacing: ResponsiveSpacing.tiny) {
                Text(player.displayName)
                    .font(ResponsiveFont.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                if let choice = choice {
                    HStack(spacing: ResponsiveSpacing.tiny) {
                        Text("Seçim:")
                            .font(ResponsiveFont.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(getChoiceIcon(choice))
                            .font(ResponsiveFont.caption)
                        
                        Text(choice.rawValue)
                            .font(ResponsiveFont.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            
            Spacer()
            
            // Elimination badge
            HStack(spacing: ResponsiveSpacing.tiny) {
                Image(systemName: "xmark.circle.fill")
                    .font(ResponsiveFont.subheadline)
                    .foregroundColor(.red)
                
                Text("ELENEN")
                    .font(ResponsiveFont.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.red.opacity(0.8))
            }
        }
        .padding(.vertical, ResponsiveSpacing.small)
        .padding(.horizontal, ResponsiveSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func getChoiceIcon(_ choice: Choice) -> String {
        switch choice {
        case .tas: return "🪨"
        case .kagit: return "📄"
        case .makas: return "✂️"
        }
    }
}

// MARK: - Continuing Player Row
struct ContinuingPlayerRow: View {
    let player: Player
    let choice: Choice?
    
    var body: some View {
        VStack(spacing: ResponsiveSpacing.small) {
            // Avatar with victory glow
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: ResponsiveSize.avatarSmall, height: ResponsiveSize.avatarSmall)
                    .overlay(
                        Circle()
                            .stroke(Color.blue.opacity(0.6), lineWidth: 2)
                    )
                
                Text(player.avatar)
                    .font(.system(size: ResponsiveSize.avatarSmall * 0.7))
                
                // Success checkmark
                Image(systemName: "checkmark.circle.fill")
                    .font(ResponsiveFont.caption)
                    .foregroundColor(.green)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Circle())
                    .offset(x: ResponsiveSize.avatarSmall * 0.3, y: ResponsiveSize.avatarSmall * 0.3)
            }
            
            // Player info
            VStack(alignment: .center, spacing: ResponsiveSpacing.tiny) {
                Text(player.displayName)
                    .font(ResponsiveFont.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if let choice = choice {
                    HStack(spacing: ResponsiveSpacing.tiny) {
                        Text(getChoiceIcon(choice))
                            .font(ResponsiveFont.caption)
                        
                        Text(choice.rawValue)
                            .font(ResponsiveFont.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                
                Text("DEVAM")
                    .font(ResponsiveFont.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue.opacity(0.9))
            }
        }
        .padding(.vertical, ResponsiveSpacing.small)
        .padding(.horizontal, ResponsiveSpacing.small)
        .background(
            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.blue.opacity(0.05)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func getChoiceIcon(_ choice: Choice) -> String {
        switch choice {
        case .tas: return "🪨"
        case .kagit: return "📄"
        case .makas: return "✂️"
        }
    }
}

// MARK: - Preview
#Preview {
    ResultsView()
        .environmentObject(MultipeerManager())
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}
