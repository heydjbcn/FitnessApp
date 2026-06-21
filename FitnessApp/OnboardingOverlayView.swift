import SwiftUI

struct OnboardingOverlayView: View {
    @ObservedObject var onboardingManager: OnboardingManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var highlightFrame: CGRect = .zero
    @State private var animateHighlight = false
    
    var body: some View {
        if onboardingManager.showingOnboarding {
            ZStack {
                // Overlay semi-transparente
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Haptic feedback para cerrar onboarding
                        HapticManager.shared.buttonTapped()
                        onboardingManager.completeOnboarding()
                    }
                
                // Contenido del onboarding
                VStack {
                    Spacer()
                    
                    onboardingCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: onboardingManager.showingOnboarding)
        }
    }
    
    private var onboardingCard: some View {
        VStack(spacing: 20) {
            // Barra de progreso
            HStack {
                ForEach(0..<OnboardingManager.onboardingSteps.count, id: \.self) { index in
                    Rectangle()
                        .fill(index <= onboardingManager.onboardingStep ? AppColors.primary(themeManager: themeManager) : AppColors.textSecondary(isDark: themeManager.isDarkMode).opacity(0.3))
                        .frame(height: 3)
                        .cornerRadius(1.5)
                        .animation(.easeInOut(duration: 0.3), value: onboardingManager.onboardingStep)
                }
            }
            .padding(.horizontal, 20)
            
            // Contenido del paso actual
            VStack(spacing: 16) {
                // Icono
                Image(systemName: currentStep.systemImage)
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.primary(themeManager: themeManager))
                    .padding(.top, 10)
                
                // Título
                Text(currentStep.title)
                    .font(AppFonts.title2)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    .multilineTextAlignment(.center)
                
                // Descripción
                Text(currentStep.description)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                
                // Botones
                HStack(spacing: 20) {
                    if onboardingManager.onboardingStep > 0 {
                        Button("Anterior") {
                            onboardingManager.previousStep()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(AppColors.textSecondary(isDark: themeManager.isDarkMode).opacity(0.2))
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        .cornerRadius(25)
                    }
                    
                    Button(onboardingManager.onboardingStep == OnboardingManager.onboardingSteps.count - 1 ? "Finalizar" : "Siguiente") {
                        // Haptic feedback para navegación del onboarding
                        HapticManager.shared.buttonTapped()
                        
                        if onboardingManager.onboardingStep == OnboardingManager.onboardingSteps.count - 1 {
                            // Haptic feedback especial para completar onboarding
                            HapticManager.shared.success()
                            onboardingManager.completeOnboarding()
                        } else {
                            onboardingManager.nextStep()
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(AppColors.primary(themeManager: themeManager))
                    .foregroundColor(AppColors.onPrimary(themeManager: themeManager))
                    .cornerRadius(25)
                    .shadow(color: AppColors.primary(themeManager: themeManager).opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .padding(.bottom, 10)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private var currentStep: OnboardingStep {
        guard onboardingManager.onboardingStep < OnboardingManager.onboardingSteps.count else {
            return OnboardingManager.onboardingSteps.last!
        }
        return OnboardingManager.onboardingSteps[onboardingManager.onboardingStep]
    }
}

// Modificador para resaltar elementos durante el onboarding
struct OnboardingHighlightModifier: ViewModifier {
    let isHighlighted: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isHighlighted ? AppColors.primary(themeManager: themeManager) : Color.clear,
                        lineWidth: isHighlighted ? 3 : 0
                    )
                    .shadow(
                        color: isHighlighted ? AppColors.primary(themeManager: themeManager).opacity(0.5) : Color.clear,
                        radius: isHighlighted ? 8 : 0
                    )
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isHighlighted)
            )
    }
}

extension View {
    func onboardingHighlight(isHighlighted: Bool) -> some View {
        self.modifier(OnboardingHighlightModifier(isHighlighted: isHighlighted))
    }
}

#Preview {
    OnboardingOverlayView(onboardingManager: OnboardingManager())
        .environmentObject(ThemeManager())
}
