import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager // Usar el del App, no crear uno nuevo
    @StateObject private var userManager = UserManager()
    @StateObject private var focusModeManager = FocusModeManager()
    @State private var selectedTab = UserDefaults.standard.integer(forKey: "selectedTab") // Cargar pestaña guardada
    @State private var shouldShowAddExerciseTab = false
    
    // NUEVO: Observer para Spotify
    @ObservedObject private var spotifyManager = SpotifyManager.shared

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // DASHBOARD
                NavigationStack {
                    ZStack {
                        AppColors.background(isDark: themeManager.isDarkMode).ignoresSafeArea()
                        VStack(spacing: 0) {
                            // Header personalizado FIJO
                            HeaderView(mainSelectedTab: $selectedTab)
                                .environmentObject(themeManager)
                                .environmentObject(userManager)
                                .environmentObject(viewModel)
                                .padding(.top, 10)
                                .padding(.bottom, 10)
                            
                            // Contenido principal
                            ScrollView(showsIndicators: false) {
                                VStack(spacing: 24) {
                                    // Progreso semanal
                                    WeeklyProgressView()
                                        .environmentObject(viewModel)
                                        .environmentObject(themeManager)
                                    
                                    // Frase motivacional
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Motivación Diaria")
                                            .font(AppFonts.subtitle)
                                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                        Text(userManager.getMotivationalQuote())
                                            .font(AppFonts.body)
                                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                            .italic()
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .cardStyle(isDarkMode: themeManager.isDarkMode)
                                    
                                    // Botón para ir al calendario del día actual
                                    Button(action: {
                                        HapticManager.shared.buttonTapped()
                                        selectedTab = 1
                                    }) {
                                        HStack {
                                            Image(systemName: "play.circle.fill")
                                                .foregroundColor(.white)
                                                .font(.system(size: 20))
                                            Text("Empecemos con tu rutina")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(AppColors.primary(themeManager: themeManager))
                                        .cornerRadius(12)
                                        .shadow(color: AppColors.primary(themeManager: themeManager).opacity(0.3), radius: 4, x: 0, y: 2)
                                    }
                                    .padding(.horizontal)
                                    
                                    // Estadísticas en tarjetas
                                    StatsCardsView(
                                        onNavigateToBestDay: { bestDay in
                                            selectedTab = 1
                                        },
                                        onNavigateToExercises: {
                                            selectedTab = 2
                                        }
                                    )
                                    .environmentObject(viewModel)
                                    .environmentObject(themeManager)
                                    
                                    // Personal Records Card
                                    PersonalRecordsCardView(workoutViewModel: viewModel)
                                    
                                    // Lista de ejercicios semanales
                                    WeeklyExercisesList()
                                        .environmentObject(viewModel)
                                        .environmentObject(themeManager)
                                }
                                .padding(.bottom, spotifyManager.isConnected ? 160 : 100) // Espacio dinámico
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

                // CONFIGURACIÓN
                SettingsView()
                    .environmentObject(themeManager)
                    .environmentObject(userManager)
                    .environmentObject(viewModel)
                    .environmentObject(focusModeManager)
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Configuración")
                    }
                    .tag(4)
            }
            .accentColor(AppColors.primary(themeManager: themeManager))
            .onAppear {
                // Configurar TabBar appearance una sola vez
                DispatchQueue.main.async {
                    updateTabBarAppearance()
                }
            }
            .onChange(of: themeManager.isDarkMode) { _, _ in
                updateTabBarAppearance()
            }
            .onChange(of: selectedTab) { _, newValue in
                HapticManager.shared.tabChanged()
                
                if newValue != 2 {
                    shouldShowAddExerciseTab = false
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Comentar esta línea para no resetear a dashboard
                // selectedTab = 0
            }
            .onChange(of: selectedTab) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "selectedTab") // Guardar pestaña seleccionada
            }
            
            // REPRODUCTOR DE SPOTIFY - POSICIONAMIENTO MEJORADO
            if spotifyManager.isConnected {
                SpotifyPlayerView()
                    .environmentObject(themeManager)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1000) // Asegurar que esté encima
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: spotifyManager.isConnected)
            }
            
            // Onboarding Overlay
            OnboardingOverlayView(onboardingManager: viewModel.onboardingManager)
                .environmentObject(themeManager)
        }
        .focusMode()
        .onAppear {
            // Configurar callbacks del onboarding
            viewModel.onboardingManager.onNavigateToExercises = {
                shouldShowAddExerciseTab = true
                selectedTab = 2
            }
            viewModel.onboardingManager.onNavigateToCalendar = {
                selectedTab = 1
            }
        }
    }
    
    private func updateTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
        ]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
        
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AppColors.primary(themeManager: themeManager))
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppColors.primary(themeManager: themeManager))
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Extension para persistir la pestaña seleccionada
extension ContentView {
    func saveSelectedTab() {
        UserDefaults.standard.set(selectedTab, forKey: "selectedTab")
    }
}
