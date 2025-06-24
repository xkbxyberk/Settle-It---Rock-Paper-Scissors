import SwiftUI

struct HowToPlayView: View {
    
    // MARK: - Properties
    @Environment(\.presentationMode) var presentationMode
    @State private var currentStep = 0
    @State private var animateContent = false
    
    private let steps = [
        TutorialStep(
            icon: "person.2.circle.fill",
            title: "1. Oyuncuları Topla",
            description: "En az 2 oyuncu gerekli. Arkadaşların da uygulamayı açsın, otomatik olarak birbirinizi bulacaksınız!",
            color: .blue
        ),
        TutorialStep(
            icon: "checkmark.circle.fill",
            title: "2. Oyun Modunu Seç",
            description: "Dokunarak veya sallayarak oynama modunu oylayın. En çok oyu alan mod kazanır!",
            color: .green
        ),
        TutorialStep(
            icon: "timer.circle.fill",
            title: "3. Geri Sayım",
            description: "5 saniyelik hazırlık süresi. Seçiminizi yapacağın moda hazırlan!",
            color: .orange
        ),
        TutorialStep(
            icon: "hand.point.up.left.fill",
            title: "4. Seçimini Yap",
            description: "Dokunma modunda: Taş, Kağıt veya Makas'a dokun\nSallama modunda: Cihazını salla, rastgele seçilir!",
            color: .purple
        ),
        TutorialStep(
            icon: "trophy.circle.fill",
            title: "5. Sonuçlar",
            description: "Taş makası, makas kağıdı, kağıt taşı yener. Kaybeden elenir, kazanan devam eder. Son kalan kazanır!",
            color: .yellow
        )
    ]
    
    // MARK: - Body
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
                
                VStack(spacing: 30) {
                    
                    // MARK: - Header
                    headerSection
                    
                    // MARK: - Tutorial Content
                    tutorialContentSection
                    
                    // MARK: - Navigation Controls
                    navigationControlsSection
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animateContent = true
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("📖")
                .font(.system(size: 50))
                .scaleEffect(animateContent ? 1.0 : 0.5)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateContent)
            
            Text("Nasıl Oynanır?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3), value: animateContent)
            
            Text("Adım adım oyun rehberi")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4), value: animateContent)
        }
    }
    
    // MARK: - Tutorial Content Section
    private var tutorialContentSection: some View {
        VStack(spacing: 20) {
            
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentStep ? 1.3 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentStep)
                }
            }
            .opacity(animateContent ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.6).delay(0.5), value: animateContent)
            
            // Current step content
            TutorialStepCard(step: steps[currentStep], isAnimated: animateContent)
        }
    }
    
    // MARK: - Navigation Controls Section
    private var navigationControlsSection: some View {
        HStack(spacing: 20) {
            
            // Previous button
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    if currentStep > 0 {
                        currentStep -= 1
                    }
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("Önceki")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(currentStep > 0 ? .white : .white.opacity(0.5))
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(currentStep > 0 ? 0.2 : 0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(currentStep > 0 ? 0.3 : 0.2), lineWidth: 1)
                        )
                )
            }
            .disabled(currentStep == 0)
            
            Spacer()
            
            // Next/Close button
            Button(action: {
                if currentStep < steps.count - 1 {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep += 1
                    }
                } else {
                    presentationMode.wrappedValue.dismiss()
                }
            }) {
                HStack(spacing: 8) {
                    Text(currentStep < steps.count - 1 ? "Sonraki" : "Tamam")
                    
                    if currentStep < steps.count - 1 {
                        Image(systemName: "chevron.right")
                    } else {
                        Image(systemName: "checkmark")
                    }
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(currentStep < steps.count - 1 ? Color.blue : Color.green)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                )
            }
        }
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.7), value: animateContent)
    }
}

// MARK: - Tutorial Step Model
struct TutorialStep {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Tutorial Step Card
struct TutorialStepCard: View {
    let step: TutorialStep
    let isAnimated: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Icon
            ZStack {
                Circle()
                    .fill(step.color.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(step.color.opacity(0.5), lineWidth: 2)
                    )
                
                Image(systemName: step.icon)
                    .font(.system(size: 32))
                    .foregroundColor(step.color)
            }
            .scaleEffect(isAnimated ? 1.0 : 0.3)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: isAnimated)
            
            // Content
            VStack(spacing: 12) {
                Text(step.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(step.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(isAnimated ? 1.0 : 0.0)
            .offset(y: isAnimated ? 0 : 30)
            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.6), value: isAnimated)
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .scaleEffect(isAnimated ? 1.0 : 0.8)
        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4), value: isAnimated)
    }
}

// MARK: - Preview
#Preview {
    HowToPlayView()
}
