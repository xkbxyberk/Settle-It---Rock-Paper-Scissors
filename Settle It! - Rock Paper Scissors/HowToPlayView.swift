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
                
                ResponsiveContainer {
                    VStack(spacing: ResponsiveSpacing.extraLarge) {
                        
                        // MARK: - Header
                        headerSection
                        
                        // MARK: - Tutorial Content
                        tutorialContentSection
                        
                        // MARK: - Navigation Controls
                        navigationControlsSection
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                    .font(ResponsiveFont.callout)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
                    // Navigation Bar konfigürasyonunu uygula
                    NavigationBarConfigurator.configureNavigationBar()
                    
                    withAnimation(ResponsiveAnimation.default.delay(0.2)) {
                        animateContent = true
                    }
                }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            Text("📖")
                .font(ResponsiveFont.emoji(size: .medium))
                .scaleEffect(animateContent ? 1.0 : 0.5)
                .animation(ResponsiveAnimation.default.delay(0.1), value: animateContent)
            
            Text("Nasıl Oynanır?")
                .font(ResponsiveFont.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                .animation(ResponsiveAnimation.default.delay(0.3), value: animateContent)
            
            Text("Adım adım oyun rehberi")
                .font(ResponsiveFont.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                .animation(ResponsiveAnimation.default.delay(0.4), value: animateContent)
        }
    }
    
    // MARK: - Tutorial Content Section
    private var tutorialContentSection: some View {
        VStack(spacing: ResponsiveSpacing.medium) {
            
            // Progress indicator
            HStack(spacing: ResponsiveSpacing.small) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.white : Color.white.opacity(0.3))
                        .frame(width: ResponsiveSize.iconSmall * 0.4, height: ResponsiveSize.iconSmall * 0.4)
                        .scaleEffect(index == currentStep ? 1.3 : 1.0)
                        .animation(ResponsiveAnimation.fast, value: currentStep)
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
        HStack(spacing: ResponsiveSpacing.medium) {
            
            // Previous button
            Button(action: {
                withAnimation(ResponsiveAnimation.fast) {
                    if currentStep > 0 {
                        currentStep -= 1
                    }
                }
            }) {
                HStack(spacing: ResponsiveSpacing.small) {
                    Image(systemName: "chevron.left")
                    Text("Önceki")
                }
                .font(ResponsiveFont.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(currentStep > 0 ? .white : .white.opacity(0.5))
                .padding(.vertical, ResponsiveSpacing.medium)
                .padding(.horizontal, ResponsivePadding.content)
                .background(
                    RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                        .fill(Color.white.opacity(currentStep > 0 ? 0.2 : 0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                                .stroke(Color.white.opacity(currentStep > 0 ? 0.3 : 0.2), lineWidth: 1)
                        )
                )
            }
            .disabled(currentStep == 0)
            
            Spacer()
            
            // Next/Close button
            Button(action: {
                if currentStep < steps.count - 1 {
                    withAnimation(ResponsiveAnimation.fast) {
                        currentStep += 1
                    }
                } else {
                    presentationMode.wrappedValue.dismiss()
                }
            }) {
                HStack(spacing: ResponsiveSpacing.small) {
                    Text(currentStep < steps.count - 1 ? "Sonraki" : "Tamam")
                    
                    if currentStep < steps.count - 1 {
                        Image(systemName: "chevron.right")
                    } else {
                        Image(systemName: "checkmark")
                    }
                }
                .font(ResponsiveFont.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.vertical, ResponsiveSpacing.medium)
                .padding(.horizontal, ResponsivePadding.content)
                .background(
                    RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                        .fill(currentStep < steps.count - 1 ? Color.blue : Color.green)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                )
            }
        }
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(y: animateContent ? 0 : 20)
        .animation(ResponsiveAnimation.default.delay(0.7), value: animateContent)
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
        VStack(spacing: ResponsiveSpacing.medium) {
            
            // Icon
            ZStack {
                Circle()
                    .fill(step.color.opacity(0.3))
                    .frame(width: ResponsiveSize.countdownCircle * 0.4, height: ResponsiveSize.countdownCircle * 0.4)
                    .overlay(
                        Circle()
                            .stroke(step.color.opacity(0.5), lineWidth: 2)
                    )
                
                Image(systemName: step.icon)
                    .font(.system(size: ResponsiveSize.countdownCircle * 0.15))
                    .foregroundColor(step.color)
            }
            .scaleEffect(isAnimated ? 1.0 : 0.3)
            .animation(ResponsiveAnimation.default.delay(0.5), value: isAnimated)
            
            // Content
            VStack(spacing: ResponsiveSpacing.medium) {
                Text(step.title)
                    .font(ResponsiveFont.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(step.description)
                    .font(ResponsiveFont.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(isAnimated ? 1.0 : 0.0)
            .offset(y: isAnimated ? 0 : 30)
            .animation(ResponsiveAnimation.default.delay(0.6), value: isAnimated)
        }
        .padding(.vertical, ResponsiveSpacing.extraLarge)
        .padding(.horizontal, ResponsivePadding.content)
        .frame(maxWidth: .infinity)
        .responsiveCard()
        .scaleEffect(isAnimated ? 1.0 : 0.8)
        .animation(ResponsiveAnimation.default.delay(0.4), value: isAnimated)
    }
}

// MARK: - Preview
#Preview {
    HowToPlayView()
}
