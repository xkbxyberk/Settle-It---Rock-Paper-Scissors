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
        VStack(spacing: 30) {
            
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
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 15) {
            Text("🗳️")
                .font(.system(size: 60))
            
            Text("Oyun Modunu Oylayın")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Turnuvada hangi modu oynamak istiyorsunuz?")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 12) {
            
            // Progress bar
            ProgressView(value: votingProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .background(Color.white.opacity(0.3))
                .cornerRadius(4)
            
            // Progress text
            Text("\(multipeerManager.gameState.votes.count) / \(multipeerManager.gameState.players.count) oy tamamlandı")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Voting Options Section
    private var votingOptionsSection: some View {
        VStack(spacing: 16) {
            
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
        }
    }
    
    // MARK: - Status Section
    private var statusSection: some View {
        VStack(spacing: 16) {
            
            if hasUserVoted {
                // Kullanıcı oy vermiş - bekleme durumu
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("Oyunuz alındı!")
                            .fontWeight(.semibold)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    
                    if let vote = userVote {
                        Text("Seçiminiz: \(vote.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text("Diğer oyuncuların oyları bekleniyor...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.4), lineWidth: 1)
                        )
                )
                
            } else {
                // Kullanıcı henüz oy vermemiş
                VStack(spacing: 8) {
                    Text("⏳ Lütfen bir mod seçin")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    Text("Oylamanın tamamlanması için seçiminizi yapın")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                        )
                )
            }
            
            // Oy dağılımını göster (eğer oylar varsa)
            if !multipeerManager.gameState.votes.isEmpty {
                votingSummaryView
            }
        }
    }
    
    // MARK: - Voting Summary View
    private var votingSummaryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 Anlık Durum")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            // Her mode için oy sayısı ve oyuncular
            let dokunmaVoters = multipeerManager.gameState.votes.filter { $0.value == .dokunma }
            let sallamaVoters = multipeerManager.gameState.votes.filter { $0.value == .sallama }
            
            VStack(spacing: 12) {
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
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
            HStack(spacing: 8) {
                Text(icon)
                    .font(.title2)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                
                Text("(\(voters.count))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Oy veren oyuncuların avatarları
            if !voters.isEmpty {
                HStack(spacing: -8) {
                    ForEach(Array(voters.keys.prefix(3)), id: \.self) { deviceID in
                        if let player = allPlayers.first(where: { $0.deviceID == deviceID }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                    )
                                
                                Text(player.avatar)
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    
                    // Eğer 3'ten fazla oyuncu varsa +X göster
                    if voters.count > 3 {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 32, height: 32)
                            
                            Text("+\(voters.count - 3)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
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
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .blue)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .blue.opacity(0.8))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue : Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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
