import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = WorkoutViewModel()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var userManager = UserManager()
    @State private var selectedTab = 0
    @State private var shouldShowAddExerciseTab = false

    var body: some View {
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
                            VStack(spacing: 24) {
                                // Progreso semanal (scrolleable)
                                WeeklyProgressView()
                                    .environmentObject(viewModel)
                                    .environmentObject(themeManager)
                                
                                // Frase motivacional - MOVIDO AQUÍ
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
                                
                                // Estadísticas en tarjetas
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
                                
                                // Lista de ejercicios semanales
                                WeeklyExercisesList()
                                    .environmentObject(viewModel)
                                    .environmentObject(themeManager)
                            }
                            .padding(.bottom, 60) // Aumentado para mayor separación de la barra de pestañas
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
        .accentColor(AppColors.primary)
        .onAppear {
            updateTabBarAppearance()
        }
        .onChange(of: themeManager.isDarkMode) { _, _ in
            updateTabBarAppearance()
        }
        .onChange(of: selectedTab) { _, newValue in
            // Resetear el estado cuando se cambia de pestaña
            if newValue != 2 {
                shouldShowAddExerciseTab = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Resetear la app al estado inicial cuando vuelve de estar completamente cerrada
            selectedTab = 0
        }
    }
    
    private func updateTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        
        // Color de texto para pestañas no seleccionadas
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
        ]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
        
        // Color de texto para pestaña seleccionada
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AppColors.primary)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppColors.primary)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
