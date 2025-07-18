import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = WorkoutViewModel()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var userManager = UserManager()

    var body: some View {
        TabView {
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
                                StatsCardsView()
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

            // CALENDARIO SEMANAL
            WeeklyCalendarView()
                .environmentObject(viewModel)
                .environmentObject(themeManager)
                .environmentObject(userManager)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendario")
                }

            // PERFIL
            ProfileView()
                .environmentObject(userManager)
                .environmentObject(themeManager)
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Perfil")
                }
        }
        .accentColor(AppColors.primary)
        .onAppear {
            updateTabBarAppearance()
        }
        .onChange(of: themeManager.isDarkMode) {
            updateTabBarAppearance()
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
