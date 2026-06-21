//
//  OnboardingCarouselView.swift
//  FitnessApp
//
//  Onboarding de bienvenida (carrusel paginado). Se muestra la primera vez y
//  desde Ajustes ▸ "Ver tutorial". Autocontenido (no resalta widgets reales).
//

import SwiftUI

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let text: String
}

struct OnboardingCarouselView: View {
    @EnvironmentObject var themeManager: ThemeManager
    var onFinish: () -> Void

    @State private var page = 0
    private var isDark: Bool { themeManager.isDarkMode }

    private let pages: [OnboardingPage] = [
        .init(icon: "bolt.heart.fill",
              title: "Bienvenido a AppFit",
              text: "Tu entreno, ordenado y medido. Crea tu rutina y sigue tu progreso de verdad."),
        .init(icon: "dumbbell.fill",
              title: "Tu rutina por días",
              text: "Añade ejercicios desde el catálogo o personalizados y organízalos de lunes a viernes."),
        .init(icon: "checklist",
              title: "Registra cada serie",
              text: "Marca tus series con el peso y las repeticiones reales. Verás siempre tu “última vez”."),
        .init(icon: "chart.line.uptrend.xyaxis",
              title: "Progreso real",
              text: "Gráficas por ejercicio, récords personales y volumen por grupo muscular."),
        .init(icon: "sparkles",
              title: "Coach IA y Apple Watch",
              text: "Pide consejos a tu coach con IA y registra tus series desde el reloj.")
    ]

    var body: some View {
        ZStack {
            AppColors.background(isDark: isDark).ignoresSafeArea()

            VStack(spacing: 0) {
                // Saltar
                HStack {
                    Spacer()
                    Button("Saltar") { finish() }
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textSecondary(isDark: isDark))
                }
                .padding(.horizontal)
                .padding(.top, 12)

                // Páginas
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { idx, p in
                        VStack(spacing: 24) {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(AppColors.primary(themeManager: themeManager).opacity(0.15))
                                    .frame(width: 130, height: 130)
                                Image(systemName: p.icon)
                                    .font(.system(size: 56, weight: .semibold))
                                    .foregroundColor(AppColors.primary(themeManager: themeManager))
                            }
                            VStack(spacing: 12) {
                                Text(p.title)
                                    .font(AppFonts.title2)
                                    .foregroundColor(AppColors.textPrimary(isDark: isDark))
                                    .multilineTextAlignment(.center)
                                Text(p.text)
                                    .font(AppFonts.body)
                                    .foregroundColor(AppColors.textSecondary(isDark: isDark))
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 32)
                            Spacer()
                        }
                        .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: page)

                // Indicadores de página
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? AppColors.primary(themeManager: themeManager) : AppColors.textTertiary(isDark: isDark).opacity(0.4))
                            .frame(width: i == page ? 22 : 8, height: 8)
                            .animation(.easeInOut, value: page)
                    }
                }
                .padding(.bottom, 20)

                // Botón principal
                Button(action: advance) {
                    Text(page == pages.count - 1 ? "Empezar" : "Siguiente")
                }
                .buttonStyle(PrimaryButtonStyle(themeManager: themeManager))
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
    }

    private func advance() {
        if page < pages.count - 1 {
            withAnimation { page += 1 }
            HapticManager.shared.buttonTapped()
        } else {
            finish()
        }
    }

    private func finish() {
        HapticManager.shared.success()
        onFinish()
    }
}
