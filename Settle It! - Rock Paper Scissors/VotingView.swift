import SwiftUI

struct VotingView: View {
    
    // MARK: - Properties
    /// MultipeerManager'dan geçirilen environment object
    @EnvironmentObject var multipeerManager: MultipeerManager
    
    /// Kullanıcının oy verip vermediğini kontrol eder
    private var hasUserVoted: Bool {
        let currentDeviceID = multipeerManager.getCurrentUserDeviceID()
        return multipeerManager.gameState.votes.keys.contains(currentDeviceID)
    }
    
    /// Kullanıcının verdiği oy
    private var userVote: GameMode? {
        let currentDeviceID = multipeerManager.getCurrentUserDeviceID()
        return multipeerManager.gameState.votes[currentDeviceID]
    }
    
    /// Oylama tamamlanma oranı
    private var votingProgress: Double {
        let totalPlayers = multipeerManager.gameState.players.count
        let totalVotes = multipeerManager.gameState.votes.count
        return totalPlayers > 0 ? Double(totalVotes) / Double(totalPlayers) : 0.0
    }
    
    // MARK: - Body
    var body: some View {
        ResponsiveContainer {
            VStack(spacing: ResponsiveSpacing.extraLarge) {
                
                // MARK: - Header
                headerSection
                
                // MARK: - Progress Section
                progressSection
                
                // MARK: - Voting Options
                votingOptionsSection
                
                // MARK: - Status Section
                statusSection
                
                Spacer()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            Text("🗳️")
                .font(ResponsiveFont.emoji(size: .medium))
            
            Text("Oyun Modunu Oylayın")
                .font(ResponsiveFont.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Turnuvada hangi modu oynamak istiyorsunuz?")
                .font(ResponsiveFont.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            
            // Progress bar
            ProgressView(value: votingProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .background(Color.white.opacity(0.3))
                .cornerRadius(4)
            
            // Progress text
            Text("\(multipeerManager.gameState.votes.count) / \(multipeerManager.gameState.players.count) oy tamamlandı")
                .font(ResponsiveFont.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
        }
    }
    
    // MARK: - Voting Options Section
    private var votingOptionsSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            
            // Dokunarak Seç
            VoteOptionButton(
                title: "👆 Dokunarak Seç",
                subtitle: "Ekranınıza dokunarak seçim yapın",
                gameMode: .dokunma,
                isSelected: hasUserVoted && userVote == .dokunma,
                isDisabled: hasUserVoted,
                multipeerManager: multipeerManager
            ) {
                multipeerManager.castVote(mode: .dokunma)
            }
            
            // Sallayarak Oyna
            VoteOptionButton(
                title: "📱 Sallayarak Oyna",
                subtitle: "Cihazınızı sallayarak seçim yapın",
                gameMode: .sallama,
                isSelected: hasUserVoted && userVote == .sallama,
                isDisabled: hasUserVoted,
                multipeerManager: multipeerManager
            ) {
                multipeerManager.castVote(mode: .sallama)
            }
            
            // Aşamalı Turnuva
            VoteOptionButton(
                title: "🏆 Aşamalı Turnuva",
                subtitle: "Dinamik eleme ve final sistemi",
                gameMode: .asamaliTurnuva,
                isSelected: hasUserVoted && userVote == .asamaliTurnuva,
                isDisabled: hasUserVoted,
                multipeerManager: multipeerManager
            ) {
                multipeerManager.castVote(mode: .asamaliTurnuva)
            }
        }
    }
    
    // MARK: - Status Section
    private var statusSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            
            if hasUserVoted {
                // Kullanıcı oy vermiş - bekleme durumu
                VStack(spacing: ResponsiveSpacing.small) {
                    HStack(spacing: ResponsiveSpacing.small) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("Oyunuz alındı!")
                            .fontWeight(.semibold)
                    }
                    .font(ResponsiveFont.headline)
                    .foregroundColor(.white)
                    
                    if let vote = userVote {
                        Text("Seçiminiz: \(vote.rawValue)")
                            .font(ResponsiveFont.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text("Diğer oyuncuların oyları bekleniyor...")
                        .font(ResponsiveFont.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.vertical, ResponsiveSpacing.medium)
                .frame(maxWidth: .infinity)
                .responsiveCard(backgroundColor: Color.green.opacity(0.2), borderColor: Color.green.opacity(0.4))
                
            } else {
                // Kullanıcı henüz oy vermemiş
                VStack(spacing: ResponsiveSpacing.small) {
                    Text("⏳ Lütfen bir mod seçin")
                        .font(ResponsiveFont.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    Text("Oylamanın tamamlanması için seçiminizi yapın")
                        .font(ResponsiveFont.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, ResponsiveSpacing.medium)
                .frame(maxWidth: .infinity)
                .responsiveCard(backgroundColor: Color.orange.opacity(0.2), borderColor: Color.orange.opacity(0.4))
            }
            
            // Oy dağılımını göster (eğer oylar varsa)
            if !multipeerManager.gameState.votes.isEmpty {
                votingSummaryView
            }
        }
    }
    
    // MARK: - Voting Summary View
    private var votingSummaryView: some View {
        VStack(alignment: .leading, spacing: ResponsiveSpacing.medium) {
            Text("📊 Anlık Durum")
                .font(ResponsiveFont.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            // Her mode için oy sayısı ve oyuncular
            let dokunmaVoters = multipeerManager.gameState.votes.filter { $0.value == .dokunma }
            let sallamaVoters = multipeerManager.gameState.votes.filter { $0.value == .sallama }
            
            VStack(spacing: ResponsiveSpacing.medium) {
                // Dokunma oyları
                VoteGroupView(
                    icon: "👆",
                    title: "Dokunma",
                    voters: dokunmaVoters,
                    allPlayers: multipeerManager.gameState.players
                )
                
                // Sallama oyları
                VoteGroupView(
                    icon: "📱",
                    title: "Sallama",
                    voters: sallamaVoters,
                    allPlayers: multipeerManager.gameState.players
                )
            }
        }
        .responsiveCard()
    }
}

// MARK: - Vote Group View
struct VoteGroupView: View {
    let icon: String
    let title: String
    let voters: [String: GameMode] // DeviceID: GameMode
    let allPlayers: [Player]
    
    var body: some View {
        HStack {
            // Icon ve başlık
            HStack(spacing: ResponsiveSpacing.small) {
                Text(icon)
                    .font(ResponsiveFont.title2)
                
                Text(title)
                    .font(ResponsiveFont.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                
                Text("(\(voters.count))")
                    .font(ResponsiveFont.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Oy veren oyuncuların avatarları
            if !voters.isEmpty {
                HStack(spacing: -ResponsiveSpacing.small) {
                    ForEach(Array(voters.keys.prefix(3)), id: \.self) { deviceID in
                        if let player = allPlayers.first(where: { $0.deviceID == deviceID }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: ResponsiveSize.avatarSmall * 0.8, height: ResponsiveSize.avatarSmall * 0.8)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                    )
                                
                                Text(player.avatar)
                                    .font(.system(size: ResponsiveSize.avatarSmall * 0.4))
                            }
                        }
                    }
                    
                    // Eğer 3'ten fazla oyuncu varsa +X göster
                    if voters.count > 3 {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: ResponsiveSize.avatarSmall * 0.8, height: ResponsiveSize.avatarSmall * 0.8)
                            
                            Text("+\(voters.count - 3)")
                                .font(ResponsiveFont.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .padding(.vertical, ResponsiveSpacing.small)
        .padding(.horizontal, ResponsiveSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                .fill(Color.white.opacity(voters.isEmpty ? 0.05 : 0.1))
        )
    }
}

// MARK: - Vote Option Button
struct VoteOptionButton: View {
    let title: String
    let subtitle: String
    let gameMode: GameMode
    let isSelected: Bool
    let isDisabled: Bool
    let multipeerManager: MultipeerManager
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if !isDisabled {
                multipeerManager.playHaptic(style: .light)
            }
            action()
        }) {
            HStack(spacing: ResponsiveSpacing.medium) {
                VStack(alignment: .leading, spacing: ResponsiveSpacing.tiny) {
                    Text(title)
                        .font(ResponsiveFont.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .blue)
                    
                    Text(subtitle)
                        .font(ResponsiveFont.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .blue.opacity(0.8))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(ResponsiveFont.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, ResponsiveSpacing.medium)
            .padding(.horizontal, ResponsivePadding.content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadiusLarge)
                    .fill(isSelected ? Color.blue : Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(ResponsiveAnimation.fast, value: isSelected)
        }
        .disabled(isDisabled)
        .opacity(isDisabled && !isSelected ? 0.6 : 1.0)
    }
}

// MARK: - Preview
#Preview {
    VotingView()
        .environmentObject(MultipeerManager())
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}
