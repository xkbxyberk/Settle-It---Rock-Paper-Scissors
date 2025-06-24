import SwiftUI

struct VotingView: View {
    
    // MARK: - Properties
    /// MultipeerManager'dan geçirilen environment object
    @EnvironmentObject var multipeerManager: MultipeerManager
    
    /// Kullanıcının oy verip vermediğini kontrol eder
    private var hasUserVoted: Bool {
        let currentUserName = multipeerManager.getCurrentPlayerName()
        return multipeerManager.gameState.votes.keys.contains(currentUserName)
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
                isSelected: hasUserVoted && multipeerManager.gameState.votes[multipeerManager.getCurrentPlayerName()] == .dokunma,
                isDisabled: hasUserVoted
            ) {
                multipeerManager.castVote(mode: .dokunma)
            }
            
            // Sallayarak Oyna
            VoteOptionButton(
                title: "📱 Sallayarak Oyna",
                subtitle: "Cihazınızı sallayarak seçim yapın",
                gameMode: .sallama,
                isSelected: hasUserVoted && multipeerManager.gameState.votes[multipeerManager.getCurrentPlayerName()] == .sallama,
                isDisabled: hasUserVoted
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
        VStack(alignment: .leading, spacing: 8) {
            Text("📊 Anlık Durum")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            // Her mode için oy sayısı
            let dokunmaVotes = multipeerManager.gameState.votes.values.filter { $0 == .dokunma }.count
            let sallamaVotes = multipeerManager.gameState.votes.values.filter { $0 == .sallama }.count
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("👆 Dokunma: \(dokunmaVotes)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("📱 Sallama: \(sallamaVotes)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
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

// MARK: - Vote Option Button
struct VoteOptionButton: View {
    let title: String
    let subtitle: String
    let gameMode: GameMode
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
