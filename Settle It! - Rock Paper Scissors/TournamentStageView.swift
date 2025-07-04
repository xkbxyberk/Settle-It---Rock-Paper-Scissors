import SwiftUI

struct TournamentStageView: View {
    
    // MARK: - Properties
    @EnvironmentObject var multipeerManager: MultipeerManager
    
    var body: some View {
        ResponsiveContainer {
            VStack(spacing: ResponsiveSpacing.extraLarge) {
                
                // Ana içerik - turnuva aşamasına göre değişir
                mainContentView
                
                Spacer()
            }
        }
    }
    
    // MARK: - Main Content View
    @ViewBuilder
    private var mainContentView: some View {
        switch multipeerManager.gameState.tournamentPhase {
        case .elimination:
            eliminationPhaseView
            
        case .final:
            finalPhaseView
            
        case .duel:
            duelPhaseView
            
        case .spectating:
            spectatorPhaseView
            
        case .none:
            EmptyView()
        }
    }
    
    // MARK: - Elimination Phase View
    private var eliminationPhaseView: some View {
        VStack(spacing: ResponsiveSpacing.extraLarge) {
            
            // Header
            VStack(spacing: ResponsiveSpacing.medium) {
                Text("🏆")
                    .font(ResponsiveFont.emoji(size: .medium))
                
                Text("Eleme Aşaması")
                    .font(ResponsiveFont.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Tur \(multipeerManager.gameState.currentElimRound + 1) / \(multipeerManager.gameState.eliminationRounds)")
                    .font(ResponsiveFont.title2)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Skorlar
            if !multipeerManager.gameState.playerScores.isEmpty {
                eliminationScoresView
            }
            
            // Progress
            eliminationProgressView
            
            // Oyun kontrolü
            if multipeerManager.gameState.gamePhase == .turOynaniyor {
                gameControlsView
            }
        }
    }
    
    // MARK: - Final Phase View  
    private var finalPhaseView: some View {
        VStack(spacing: ResponsiveSpacing.extraLarge) {
            
            // Header
            VStack(spacing: ResponsiveSpacing.medium) {
                Text("🥇")
                    .font(ResponsiveFont.emoji(size: .medium))
                
                Text("FINAL MAÇI")
                    .font(ResponsiveFont.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Tur \(multipeerManager.gameState.currentFinalRound + 1) / \(multipeerManager.gameState.finalRounds)")
                    .font(ResponsiveFont.title2)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Finalistler
            finalistsView
            
            // Final skorları
            if !multipeerManager.gameState.playerScores.isEmpty {
                finalScoresView
            }
            
            // Oyun kontrolü
            if multipeerManager.gameState.gamePhase == .turOynaniyor {
                gameControlsView
            }
        }
    }
    
    // MARK: - Duel Phase View
    private var duelPhaseView: some View {
        VStack(spacing: ResponsiveSpacing.extraLarge) {
            
            // Header
            VStack(spacing: ResponsiveSpacing.medium) {
                Text("⚔️")
                    .font(ResponsiveFont.emoji(size: .medium))
                
                Text("DÜELLO MODU")
                    .font(ResponsiveFont.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(multipeerManager.gameState.duelWinTarget) Galibiyet Gerekli")
                    .font(ResponsiveFont.title2)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Düello skorları
            duelScoresView
            
            // Oyun kontrolü
            if multipeerManager.gameState.gamePhase == .turOynaniyor {
                gameControlsView
            }
        }
    }
    
    // MARK: - Spectator Phase View
    private var spectatorPhaseView: some View {
        VStack(spacing: ResponsiveSpacing.extraLarge) {
            
            // Header
            VStack(spacing: ResponsiveSpacing.medium) {
                Text("👀")
                    .font(ResponsiveFont.emoji(size: .medium))
                
                Text("İZLEYİCİ MODU")
                    .font(ResponsiveFont.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Final maçını izliyorsunuz")
                    .font(ResponsiveFont.title2)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Final maçı bilgileri
            if multipeerManager.gameState.tournamentPhase == .final {
                spectatorFinalInfoView
            }
            
            // İzleyici aksiyonları
            spectatorActionsView
        }
    }
    
    // MARK: - Supporting Views
    
    private var eliminationScoresView: some View {
        VStack(alignment: .leading, spacing: ResponsiveSpacing.medium) {
            Text("📊 Eleme Sıralaması")
                .font(ResponsiveFont.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVStack(spacing: ResponsiveSpacing.small) {
                ForEach(sortedPlayers, id: \.id) { player in
                    eliminationPlayerRow(player: player)
                }
            }
        }
        .responsiveCard()
    }
    
    private var eliminationProgressView: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            Text("Eleme turları tamamlandığında en iyi 2 oyuncu finale kalacak!")
                .font(ResponsiveFont.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            ProgressView(value: Double(multipeerManager.gameState.currentElimRound), 
                        total: Double(multipeerManager.gameState.eliminationRounds))
                .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .responsiveCard(backgroundColor: Color.orange.opacity(0.2), borderColor: Color.orange.opacity(0.4))
    }
    
    private var finalistsView: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            Text("🏅 FİNALİSTLER")
                .font(ResponsiveFont.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack(spacing: ResponsiveSpacing.large) {
                ForEach(multipeerManager.gameState.finalists, id: \.id) { player in
                    finalistCard(player: player)
                }
            }
        }
        .responsiveCard(backgroundColor: Color.yellow.opacity(0.2), borderColor: Color.yellow.opacity(0.4))
    }
    
    private var finalScoresView: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            Text("🎯 Final Skorları")
                .font(ResponsiveFont.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack(spacing: ResponsiveSpacing.large) {
                ForEach(multipeerManager.gameState.finalists, id: \.id) { player in
                    finalScoreCard(player: player)
                }
            }
        }
        .responsiveCard()
    }
    
    private var duelScoresView: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            Text("⚔️ Düello Skorları")
                .font(ResponsiveFont.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack(spacing: ResponsiveSpacing.large) {
                ForEach(multipeerManager.gameState.players, id: \.id) { player in
                    duelScoreCard(player: player)
                }
            }
        }
        .responsiveCard()
    }
    
    private var gameControlsView: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            if let gameMode = multipeerManager.gameState.gameMode {
                switch gameMode {
                case .dokunma:
                    touchModeControls
                case .sallama:
                    shakeModeControls
                case .asamaliTurnuva:
                    EmptyView() // Bu durumda alt mode'a bakılmalı
                }
            }
        }
    }
    
    private var touchModeControls: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            Text("👆 Seçiminizi yapın")
                .font(ResponsiveFont.headline)
                .foregroundColor(.white.opacity(0.9))
            
            VStack(spacing: ResponsiveSpacing.medium) {
                choiceButton(.tas, "🪨", "TAŞ")
                choiceButton(.kagit, "📄", "KAĞIT")
                choiceButton(.makas, "✂️", "MAKAS")
            }
        }
    }
    
    private var shakeModeControls: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            Text("📱 Cihazınızı sallayın!")
                .font(ResponsiveFont.headline)
                .foregroundColor(.white.opacity(0.9))
            
            Image(systemName: "iphone.shake")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.8))
                .symbolEffect(.bounce, options: .repeating)
        }
        .responsiveCard()
    }
    
    private var spectatorFinalInfoView: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            Text("🏆 Final Maçı Devam Ediyor")
                .font(ResponsiveFont.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if !multipeerManager.gameState.finalists.isEmpty {
                HStack(spacing: ResponsiveSpacing.large) {
                    ForEach(multipeerManager.gameState.finalists, id: \.id) { player in
                        spectatorFinalistCard(player: player)
                    }
                }
            }
        }
        .responsiveCard(backgroundColor: Color.blue.opacity(0.2), borderColor: Color.blue.opacity(0.4))
    }
    
    private var spectatorActionsView: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            Text("Ne yapmak istiyorsunuz?")
                .font(ResponsiveFont.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: ResponsiveSpacing.medium) {
                Button(action: {
                    // Oyunu izlemeye devam et
                    multipeerManager.playHaptic(style: .light)
                }) {
                    HStack(spacing: ResponsiveSpacing.medium) {
                        Image(systemName: "play.circle.fill")
                            .font(ResponsiveFont.title2)
                        
                        Text("Final Maçını İzle")
                            .font(ResponsiveFont.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ResponsiveSpacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                }
                
                Button(action: {
                    multipeerManager.playHaptic(style: .medium)
                    multipeerManager.resetGame()
                }) {
                    HStack(spacing: ResponsiveSpacing.medium) {
                        Image(systemName: "house.circle")
                            .font(ResponsiveFont.title2)
                        
                        Text("Ana Menüye Dön")
                            .font(ResponsiveFont.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ResponsiveSpacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                            .fill(Color.red.opacity(0.8))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                }
            }
        }
        .responsiveCard()
    }
    
    // MARK: - Helper Methods
    
    private var sortedPlayers: [Player] {
        return multipeerManager.gameState.players.sorted { player1, player2 in
            let score1 = multipeerManager.gameState.playerScores[player1.deviceID] ?? 0
            let score2 = multipeerManager.gameState.playerScores[player2.deviceID] ?? 0
            return score1 > score2
        }
    }
    
    private func eliminationPlayerRow(player: Player) -> some View {
        let score = multipeerManager.gameState.playerScores[player.deviceID] ?? 0
        let position = sortedPlayers.firstIndex(where: { $0.id == player.id }) ?? 0
        
        return HStack(spacing: ResponsiveSpacing.medium) {
            // Position
            ZStack {
                Circle()
                    .fill(positionColor(position: position).opacity(0.3))
                    .frame(width: ResponsiveSize.avatarSmall * 0.8, height: ResponsiveSize.avatarSmall * 0.8)
                    .overlay(
                        Circle()
                            .stroke(positionColor(position: position), lineWidth: 2)
                    )
                
                Text("\(position + 1)")
                    .font(ResponsiveFont.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(positionColor(position: position))
            }
            
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: ResponsiveSize.avatarSmall, height: ResponsiveSize.avatarSmall)
                
                Text(player.avatar)
                    .font(.system(size: ResponsiveSize.avatarSmall * 0.7))
            }
            
            // Player info
            VStack(alignment: .leading, spacing: ResponsiveSpacing.tiny) {
                Text(player.displayName)
                    .font(ResponsiveFont.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Puan: \(score)")
                    .font(ResponsiveFont.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Finalist status
            if position < 2 && multipeerManager.gameState.currentElimRound >= multipeerManager.gameState.eliminationRounds {
                Text("FİNALİST")
                    .font(ResponsiveFont.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                    .padding(.horizontal, ResponsiveSpacing.small)
                    .padding(.vertical, ResponsiveSpacing.tiny)
                    .background(Color.yellow.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, ResponsiveSpacing.small)
        .padding(.horizontal, ResponsiveSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                .fill(position < 2 ? Color.yellow.opacity(0.1) : Color.white.opacity(0.05))
        )
    }
    
    private func finalistCard(player: Player) -> some View {
        VStack(spacing: ResponsiveSpacing.small) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.3))
                    .frame(width: ResponsiveSize.avatarLarge, height: ResponsiveSize.avatarLarge)
                    .overlay(
                        Circle()
                            .stroke(Color.yellow, lineWidth: 3)
                    )
                
                Text(player.avatar)
                    .font(ResponsiveFont.emoji(size: .small))
                
                Text("👑")
                    .font(ResponsiveFont.title3)
                    .offset(y: -ResponsiveSize.avatarLarge * 0.35)
            }
            
            Text(player.displayName)
                .font(ResponsiveFont.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func finalScoreCard(player: Player) -> some View {
        let score = multipeerManager.gameState.playerScores[player.deviceID] ?? 0
        
        return VStack(spacing: ResponsiveSpacing.small) {
            Text(player.avatar)
                .font(ResponsiveFont.emoji(size: .small))
            
            Text(player.displayName)
                .font(ResponsiveFont.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text("\(score)")
                .font(ResponsiveFont.title)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ResponsiveSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                .fill(Color.blue.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func duelScoreCard(player: Player) -> some View {
        let score = multipeerManager.gameState.duelScores[player.deviceID] ?? 0
        let targetScore = multipeerManager.gameState.duelWinTarget
        
        return VStack(spacing: ResponsiveSpacing.small) {
            Text(player.avatar)
                .font(ResponsiveFont.emoji(size: .small))
            
            Text(player.displayName)
                .font(ResponsiveFont.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text("\(score) / \(targetScore)")
                .font(ResponsiveFont.title)
                .fontWeight(.bold)
                .foregroundColor(score >= targetScore ? .green : .white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ResponsiveSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                .fill(score >= targetScore ? Color.green.opacity(0.15) : Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                        .stroke(score >= targetScore ? Color.green.opacity(0.3) : Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func spectatorFinalistCard(player: Player) -> some View {
        VStack(spacing: ResponsiveSpacing.small) {
            Text(player.avatar)
                .font(ResponsiveFont.emoji(size: .small))
            
            Text(player.displayName)
                .font(ResponsiveFont.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ResponsiveSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                .fill(Color.blue.opacity(0.15))
        )
    }
    
    private func choiceButton(_ choice: Choice, _ icon: String, _ title: String) -> some View {
        let currentDeviceID = multipeerManager.getCurrentUserDeviceID()
        let hasUserMadeChoice = multipeerManager.gameState.choices.keys.contains(currentDeviceID)
        let userChoice = multipeerManager.gameState.choices[currentDeviceID]
        let isSelected = hasUserMadeChoice && userChoice == choice
        
        return Button(action: {
            if !hasUserMadeChoice {
                multipeerManager.playHaptic(style: .medium)
                multipeerManager.makeChoice(choice: choice)
            }
        }) {
            HStack(spacing: ResponsiveSpacing.medium) {
                Text(icon)
                    .font(ResponsiveFont.emoji(size: .small))
                
                Text(title)
                    .font(ResponsiveFont.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(ResponsiveFont.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, ResponsiveSpacing.medium)
            .padding(.horizontal, ResponsiveSpacing.large)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadiusLarge)
                    .fill(isSelected ? Color.blue : Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(ResponsiveAnimation.fast, value: isSelected)
        }
        .disabled(hasUserMadeChoice)
        .opacity(hasUserMadeChoice && !isSelected ? 0.6 : 1.0)
    }
    
    private func positionColor(position: Int) -> Color {
        switch position {
        case 0: return .yellow
        case 1: return .orange
        default: return .white.opacity(0.6)
        }
    }
}

// MARK: - Preview
#Preview {
    TournamentStageView()
        .environmentObject(MultipeerManager())
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}
