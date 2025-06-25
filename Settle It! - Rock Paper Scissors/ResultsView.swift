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
        VStack(spacing: 30) {
            
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
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("📊")
                .font(.system(size: 60))
            
            Text("Tur \(multipeerManager.gameState.currentRound) Sonuçları")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Round Analysis Section
    private var roundAnalysisSection: some View {
        VStack(spacing: 16) {
            
            // Seçimleri göster
            choicesSummaryView
            
            // Kazanan/kaybeden analizi
            if roundAnalysis.hasEliminations,
               let winningChoice = roundAnalysis.winningChoice,
               let losingChoice = roundAnalysis.losingChoice {
                
                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        // Kazanan
                        VStack(spacing: 8) {
                            Text(getChoiceIcon(winningChoice))
                                .font(.system(size: 40))
                            
                            Text(winningChoice.rawValue)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            
                            Text("KAZANAN")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.green.opacity(0.8))
                        }
                        
                        Text("VS")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.6))
                        
                        // Kaybeden
                        VStack(spacing: 8) {
                            Text(getChoiceIcon(losingChoice))
                                .font(.system(size: 40))
                                .opacity(0.6)
                            
                            Text(losingChoice.rawValue)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                            
                            Text("KAYBEDEN")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red.opacity(0.8))
                        }
                    }
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Choices Summary View
    private var choicesSummaryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎯 Bu Turdaki Seçimler")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            choicesGridView
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Choices Grid View
    private var choicesGridView: some View {
        let choiceGroups = Dictionary(grouping: multipeerManager.gameState.choices) { $0.value }
        
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
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
        VStack(spacing: 16) {
            
            if eliminatedPlayers.isEmpty {
                // Kimse elenmemiş
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("Bu Turda Kimse Elenmedi!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Herkes devam ediyor")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.green.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.green.opacity(0.4), lineWidth: 1)
                        )
                )
                
            } else {
                // Eliminasyon var
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                        
                        Text("Elenen Oyuncular")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(eliminatedPlayers.count)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    
                    LazyVStack(spacing: 8) {
                        ForEach(eliminatedPlayers, id: \.id) { player in
                            EliminatedPlayerRow(
                                player: player,
                                choice: multipeerManager.gameState.choices[player.deviceID]
                            )
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.red.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red.opacity(0.4), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Continuing Players Section
    private var continuingPlayersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.forward.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Yola Devam Edenler")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(multipeerManager.gameState.activePlayers.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            if multipeerManager.gameState.activePlayers.isEmpty {
                Text("Hiç oyuncu kalmadı")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .italic()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(multipeerManager.gameState.activePlayers, id: \.id) { player in
                        ContinuingPlayerRow(
                            player: player,
                            choice: multipeerManager.gameState.choices[player.deviceID]
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                )
        )
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
        VStack(spacing: 8) {
            Text(getChoiceIcon(choice))
                .font(.system(size: 30))
            
            Text(choice.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
            
            Text("\(players.count) oyuncu")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            // Oyuncuların avatarları
            if !players.isEmpty {
                playersAvatarsView
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(players.isEmpty ? Color.white.opacity(0.05) : Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(players.isEmpty ? 0.1 : 0.3), lineWidth: 1)
                )
        )
        .opacity(players.isEmpty ? 0.5 : 1.0)
    }
    
    private var playersAvatarsView: some View {
        HStack(spacing: -4) {
            ForEach(players.prefix(3), id: \.id) { player in
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 20, height: 20)
                    
                    Text(player.avatar)
                        .font(.system(size: 10))
                }
            }
            
            if players.count > 3 {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 20, height: 20)
                    
                    Text("+\(players.count - 3)")
                        .font(.caption2)
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
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color.red.opacity(0.5), lineWidth: 2)
                    )
                
                Text(player.avatar)
                    .font(.title3)
            }
            
            // Player info
            VStack(alignment: .leading, spacing: 2) {
                Text(player.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                if let choice = choice {
                    HStack(spacing: 4) {
                        Text("Seçim:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(getChoiceIcon(choice))
                            .font(.caption)
                        
                        Text(choice.rawValue)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "xmark.circle")
                .font(.title3)
                .foregroundColor(.red.opacity(0.8))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
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
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                    )
                
                Text(player.avatar)
                    .font(.title3)
            }
            
            // Player info
            VStack(alignment: .leading, spacing: 2) {
                Text(player.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                if let choice = choice {
                    HStack(spacing: 4) {
                        Text("Seçim:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(getChoiceIcon(choice))
                            .font(.caption)
                        
                        Text(choice.rawValue)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle")
                .font(.title3)
                .foregroundColor(.blue.opacity(0.8))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
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
