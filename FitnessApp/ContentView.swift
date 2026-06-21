import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = WorkoutViewModel()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var userManager = UserManager()
    @State private var selectedTab = 0
    @State private var shouldShowAddExerciseTab = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // DASHBOARD
                NavigationStack {
                    ZStack {
                        AppColors.background(isDark: themeManager.isDarkMode).ignoresSafeArea()
                        VStack(spacing: 0) {
                            // Header personalizado FIJO (solo saludo e iconos)
                            HeaderView()
                                .environmentObject(themeManager)
                                .environmentObject(userManager)
                                .environmentObject(viewModel)
                                .padding(.top, 10)
                                .padding(.bottom, 10)
                            
                            // Contenido principal
                            ScrollView(showsIndicators: false) {
                                VStack(spacing: 20) {
                                    // 1. Tarjeta grande de progreso semanal (fondo lima)
                                    WeeklyProgressView()
                                        .environmentObject(viewModel)
                                        .environmentObject(themeManager)

                                    // 2. Fila de 3 tarjetas de stats
                                    StatsCardsView(
                                        onNavigateToBestDay: { bestDay in
                                            // Cambiar a la pestaña de calendario
                                            selectedTab = 1
                                            // Aquí podrías añadir lógica para navegar al día específico
                                        },
                                        onNavigateToExercises: {
                                            // Cambiar a la pestaña de ejercicios
                                            selectedTab = 2
                                        }
                                    )
                                    .environmentObject(viewModel)
                                    .environmentObject(themeManager)

                                    // 3. Tarjeta "Motivación Diaria" (icono estrella en cuadrito)
                                    HStack(alignment: .top, spacing: 14) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(AppColors.primary(themeManager: themeManager))
                                            .frame(width: 44, height: 44)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(AppColors.primary(themeManager: themeManager).opacity(0.15))
                                            )

                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("MOTIVACIÓN DIARIA")
                                                .font(AppFonts.label)
                                                .tracking(1.0)
                                                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                            Text(userManager.getMotivationalQuote())
                                                .font(AppFonts.subtitle)
                                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                                .fixedSize(horizontal: false, vertical: true)
                                        }

                                        Spacer(minLength: 0)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                                    .cardStyle(isDarkMode: themeManager.isDarkMode)

                                    // 4. Sección "Hoy · <día>" + lista de ejercicios del día
                                    WeeklyExercisesList()
                                        .environmentObject(viewModel)
                                        .environmentObject(themeManager)

                                    // 5. Botón ancho "Continuar entrenamiento"
                                    Button(action: {
                                        HapticManager.shared.buttonTapped()
                                        selectedTab = 1
                                    }) {
                                        HStack {
                                            Text("Continuar entrenamiento")
                                                .font(AppFonts.subtitle)
                                                .foregroundColor(AppColors.onPrimary(themeManager: themeManager))
                                            Image(systemName: "arrow.right")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(AppColors.onPrimary(themeManager: themeManager))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 18)
                                        .background(AppColors.primary(themeManager: themeManager))
                                        .cornerRadius(16)
                                        .shadow(color: AppColors.primary(themeManager: themeManager).opacity(0.3), radius: 4, x: 0, y: 2)
                                    }
                                }
                                .padding(.bottom, 60) // Separación de la barra de pestañas
                            }
                            .padding(.horizontal)
                        }
                    }
                    .sheet(isPresented: $userManager.showingNameInput) {
                        NameInputView()
                            .environmentObject(userManager)
                            .environmentObject(themeManager)
                            .interactiveDismissDisabled()
                    }
                }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Inicio")
                }
                .tag(0)

                // CALENDARIO SEMANAL
                WeeklyCalendarView(
                    onNavigateToAddExercise: {
                        // Cambiar a la pestaña de ejercicios y mostrar la pestaña de añadir
                        shouldShowAddExerciseTab = true
                        selectedTab = 2
                    }
                )
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)
                    .environmentObject(userManager)
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Calendario")
                    }
                    .tag(1)

                // EJERCICIOS
                ExerciseManagementView(shouldShowAddExerciseTab: shouldShowAddExerciseTab)
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)
                    .tabItem {
                        Image(systemName: "dumbbell.fill")
                        Text("Ejercicios")
                    }
                    .tag(2)
                    .onAppear {
                        // Resetear el estado cuando se cambia de pestaña
                        if selectedTab != 2 {
                            shouldShowAddExerciseTab = false
                        }
                    }

                // HISTORIAL
                HistoryView()
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)
                    .tabItem {
                        Image(systemName: "clock.fill")
                        Text("Historial")
                    }
                    .tag(3)

                // PERFIL
                ProfileView()
                    .environmentObject(userManager)
                    .environmentObject(themeManager)
                    .environmentObject(viewModel)
                    .tabItem {
                        Image(systemName: "person.circle.fill")
                        Text("Perfil")
                    }
                    .tag(4)
            }
            .tint(AppColors.primary(themeManager: themeManager))
            .onAppear {
                updateTabBarAppearance()
                PhoneConnectivity.shared.viewModel = viewModel
                PhoneConnectivity.shared.sendTodayContext()
                if viewModel.needsWelcome {
                    viewModel.showWelcome = true
                }
            }
            .onChange(of: themeManager.isDarkMode) { _, _ in
                updateTabBarAppearance()
            }
            .onChange(of: themeManager.selectedAccentColor) { _, _ in
                updateTabBarAppearance()
            }
            .onChange(of: selectedTab) { _, newValue in
                // Haptic feedback para cambio de tab
                HapticManager.shared.tabChanged()
                
                // Resetear el estado cuando se cambia de pestaña
                if newValue != 2 {
                    shouldShowAddExerciseTab = false
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Resetear la app al estado inicial cuando vuelve de estar completamente cerrada
                selectedTab = 0
            }
            
            // Celebración de récord personal (Fase 4)
            if let pr = viewModel.prCelebration {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                        Text(pr).font(AppFonts.subtitle)
                    }
                    .foregroundColor(AppColors.onPrimary(themeManager: themeManager))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(AppColors.primary(themeManager: themeManager)))
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
                    .padding(.bottom, 110)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { viewModel.prCelebration = nil }
                    }
                }
            }
        }
        .focusMode() // Aplicar modificador de modo de enfoque
        .fullScreenCover(isPresented: $viewModel.showWelcome) {
            OnboardingCarouselView(onFinish: {
                viewModel.markWelcomeSeen()
            })
            .environmentObject(themeManager)
        }
    }
    
    private func updateTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        
        // Color de los items NO seleccionados (gris). El color del SELECCIONADO
        // lo controla SwiftUI con .tint(...) para que reaccione al cambio de acento.
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
        ]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        // Aplicar también a las tab bars ya instanciadas (el proxy appearance no
        // refresca las vivas), y fijar el tint del seleccionado al acento actual.
        let tint = UIColor(AppColors.primary(themeManager: themeManager))
        for window in UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).flatMap({ $0.windows }) {
            for tabBar in window.allTabBars() {
                tabBar.standardAppearance = appearance
                tabBar.scrollEdgeAppearance = appearance
                tabBar.tintColor = tint
            }
        }
    }
}

extension UIView {
    /// Busca recursivamente todas las UITabBar dentro de la jerarquía de vistas.
    func allTabBars() -> [UITabBar] {
        var result: [UITabBar] = []
        if let tb = self as? UITabBar { result.append(tb) }
        for sub in subviews { result.append(contentsOf: sub.allTabBars()) }
        return result
    }
}
