import SwiftUI

struct ResultsView: View {
    
    // MARK: - Properties
    /// MultipeerManager'dan geçirilen environment object
    @EnvironmentObject var multipeerManager: MultipeerManager
    
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
    
    // MARK: - Body
    var body: some View {
        ResponsiveContainer {
            VStack(spacing: ResponsiveSpacing.extraLarge) {
                
                // MARK: - Header
                headerSection
                
                // MARK: - Round Analysis
                roundAnalysisSection
                
                // MARK: - Results Section
                resultsSection
                
                // MARK: - Continuing Players
                continuingPlayersSection
                
                Spacer()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            Text("📊")
                .font(ResponsiveFont.emoji(size: .medium))
            
            Text("Tur \(multipeerManager.gameState.currentRound) Sonuçları")
                .font(ResponsiveFont.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Round Analysis Section
    private var roundAnalysisSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            
            // Seçimleri göster
            choicesSummaryView
            
            // Kazanan/kaybeden analizi
            if roundAnalysis.hasEliminations,
               let winningChoice = roundAnalysis.winningChoice,
               let losingChoice = roundAnalysis.losingChoice {
                
                VStack(spacing: ResponsiveSpacing.medium) {
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
                        
                        Text("VS")
                            .font(ResponsiveFont.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.6))
                        
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
                    }
                }
                .padding(.vertical, ResponsiveSpacing.medium)
                .frame(maxWidth: .infinity)
                .responsiveCard()
            }
        }
    }
    
    // MARK: - Choices Summary View
    private var choicesSummaryView: some View {
        VStack(alignment: .leading, spacing: ResponsiveSpacing.medium) {
            Text("🎯 Bu Turdaki Seçimler")
                .font(ResponsiveFont.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
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
    
    // MARK: - Results Section
    private var resultsSection: some View {
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
                    
                    Text("Herkes devam ediyor")
                        .font(ResponsiveFont.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.vertical, ResponsiveSpacing.medium)
                .frame(maxWidth: .infinity)
                .responsiveCard(backgroundColor: Color.green.opacity(0.2), borderColor: Color.green.opacity(0.4))
                
            } else {
                // Eliminasyon var
                VStack(alignment: .leading, spacing: ResponsiveSpacing.medium) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(ResponsiveFont.title2)
                            .foregroundColor(.red)
                        
                        Text("Elenen Oyuncular")
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
                }
                .responsiveCard(backgroundColor: Color.red.opacity(0.2), borderColor: Color.red.opacity(0.4))
            }
        }
    }
    
    // MARK: - Continuing Players Section
    private var continuingPlayersSection: some View {
        VStack(alignment: .leading, spacing: ResponsiveSpacing.medium) {
            HStack {
                Image(systemName: "arrow.forward.circle.fill")
                    .font(ResponsiveFont.title2)
                    .foregroundColor(.blue)
                
                Text("Yola Devam Edenler")
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
            }
        }
        .responsiveCard(backgroundColor: Color.blue.opacity(0.2), borderColor: Color.blue.opacity(0.4))
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
            
            Image(systemName: "xmark.circle")
                .font(ResponsiveFont.title3)
                .foregroundColor(.red.opacity(0.8))
        }
        .padding(.vertical, ResponsiveSpacing.small)
        .padding(.horizontal, ResponsiveSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                .fill(Color.red.opacity(0.1))
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
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: ResponsiveSize.avatarSmall, height: ResponsiveSize.avatarSmall)
                    .overlay(
                        Circle()
                            .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                    )
                
                Text(player.avatar)
                    .font(.system(size: ResponsiveSize.avatarSmall * 0.7))
            }
            
            // Player info
            VStack(alignment: .center, spacing: ResponsiveSpacing.tiny) {
                Text(player.displayName)
                    .font(ResponsiveFont.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if let choice = choice {
                    HStack(spacing: ResponsiveSpacing.tiny) {
                        Text(getChoiceIcon(choice))
                            .font(ResponsiveFont.caption)
                        
                        Text(choice.rawValue)
                            .font(ResponsiveFont.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                
                Image(systemName: "checkmark.circle")
                    .font(ResponsiveFont.caption)
                    .foregroundColor(.blue.opacity(0.8))
            }
        }
        .padding(.vertical, ResponsiveSpacing.small)
        .padding(.horizontal, ResponsiveSpacing.small)
        .background(
            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                .fill(Color.blue.opacity(0.1))
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
