import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager
    @State private var selectedTab = 0
    @State private var shouldShowAddExerciseTab = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // DASHBOARD
                NavigationStack {
                    HomeView(selectedTab: $selectedTab)
                        .environmentObject(viewModel)
                        .environmentObject(themeManager)
                        .environmentObject(userManager)
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
