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
                        AppColors.backgroundPrimary.ignoresSafeArea()
                        
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 0) {
                                // Header con saludo (solo visible al scroll hacia arriba)
                                ModernHeaderView()
                                    .padding(.horizontal, 20)
                                    .padding(.top, 10)
                                
                                // Contenido principal del dashboard
                                VStack(spacing: 24) {
                                    // Progreso semanal moderno
                                    ModernWeeklyProgressView()
                                    
                                    // Información de la rutina por defecto
                                    DefaultRoutineInfoCard()
                                    
                                    // Motivación diaria
                                    ModernMotivationView()
                                    
                                    // Botón principal "Empecemos con tu rutina"
                                    ModernStartWorkoutButton(selectedTab: $selectedTab)
                                    
                                    // Tarjetas de estadísticas (4 tarjetas)
                                    ModernStatsGrid()
                                    
                                    // Récords personales
                                    ModernPersonalRecordsView()
                                    
                                    // Tarjeta semanal con días de entrenamiento
                                    ModernWeeklyScheduleView()
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                                .padding(.bottom, spotifyManager.isConnected ? 160 : 100)
                            }
                        }
                    }
                    .sheet(isPresented: $userManager.showingNameInput) {
                        NameInputView()
                            .environmentObject(userManager)
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
                    
                    
                    .environmentObject(userManager)
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Calendario")
                    }
                    .tag(1)

                // EJERCICIOS
                ExerciseManagementView()
                    
                    
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
                    
                    
                    .tabItem {
                        Image(systemName: "clock.fill")
                        Text("Historial")
                    }
                    .tag(3)

                // CONFIGURACIÓN
                SettingsView()
                    
                    .environmentObject(userManager)
                    
                    .environmentObject(focusModeManager)
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Configuración")
                    }
                    .tag(4)

            }
            .accentColor(AppColors.accentRed)
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
            .onChange(of: selectedTab) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "selectedTab") // Guardar pestaña seleccionada
            }
            
            // REPRODUCTOR DE SPOTIFY - POSICIONAMIENTO MEJORADO
            if spotifyManager.isConnected {
                SpotifyPlayerView()
                    
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1000) // Asegurar que esté encima
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: spotifyManager.isConnected)
            }
            
            // Onboarding Overlay
            OnboardingOverlayView(onboardingManager: viewModel.onboardingManager)
                
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
        appearance.backgroundColor = UIColor(AppColors.backgroundCard)
        
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(AppColors.textSecondary)
        ]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppColors.textSecondary)
        
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AppColors.accentRed)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppColors.accentRed)
        
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
