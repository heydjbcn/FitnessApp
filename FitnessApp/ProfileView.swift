import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingProfileEdit = false
    
    private func calculateBMI() -> String {
        guard !userManager.userWeight.isEmpty, !userManager.userHeight.isEmpty,
              let weight = Double(userManager.userWeight),
              let height = Double(userManager.userHeight) else {
            return "No disponible"
        }
        
        let heightInMeters = height / 100
        let bmi = weight / (heightInMeters * heightInMeters)
        return String(format: "%.1f", bmi)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background(isDark: themeManager.isDarkMode).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header del perfil
                        VStack(spacing: 20) {
                            // Foto de perfil
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 100))
                                .foregroundColor(AppColors.primary)
                            
                            // Nombre
                            Text(userManager.currentUserName.isEmpty ? "Usuario" : userManager.currentUserName)
                                .font(AppFonts.title)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            
                            // Botón editar perfil
                            Button(action: {
                                showingProfileEdit = true
                            }) {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text("Editar perfil")
                                }
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                                .cornerRadius(16)
                            }
                        }
                        .padding(.top, 30)
                        
                        // Estadísticas del perfil
                        VStack(spacing: 16) {
                            Text("Información Personal")
                                .font(AppFonts.subtitle)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                // Edad
                                ProfileInfoCard(
                                    icon: "calendar",
                                    title: "Edad",
                                    value: userManager.userAge.isEmpty ? "No especificado" : "\(userManager.userAge) años"
                                )
                                .environmentObject(themeManager)
                                
                                // Altura
                                ProfileInfoCard(
                                    icon: "ruler",
                                    title: "Altura",
                                    value: userManager.userHeight.isEmpty ? "No especificado" : "\(userManager.userHeight) cm"
                                )
                                .environmentObject(themeManager)
                                
                                // Peso
                                ProfileInfoCard(
                                    icon: "scalemass",
                                    title: "Peso",
                                    value: userManager.userWeight.isEmpty ? "No especificado" : "\(userManager.userWeight) kg"
                                )
                                .environmentObject(themeManager)
                                
                                // IMC
                                ProfileInfoCard(
                                    icon: "heart.text.square",
                                    title: "IMC",
                                    value: calculateBMI()
                                )
                                .environmentObject(themeManager)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Progreso y estadísticas
                        VStack(spacing: 16) {
                            Text("Progreso")
                                .font(AppFonts.subtitle)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 12) {
                                ProfileProgressCard(
                                    title: "Entrenamientos completados",
                                    value: "12",
                                    subtitle: "Esta semana",
                                    progress: 0.6,
                                    themeManager: themeManager
                                )
                                
                                ProfileProgressCard(
                                    title: "Tiempo total de ejercicio",
                                    value: "4h 30m",
                                    subtitle: "Esta semana",
                                    progress: 0.8,
                                    themeManager: themeManager
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Mi Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingProfileEdit) {
                ProfileEditView()
                    .environmentObject(userManager)
                    .environmentObject(themeManager)
            }
        }
    }
}

struct ProfileInfoCard: View {
    let icon: String
    let title: String
    let value: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppColors.primary)
            
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            
            Text(value)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding()
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ProfileProgressCard: View {
    let title: String
    let value: String
    let subtitle: String
    let progress: Double
    let themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    
                    Text(subtitle)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
                
                Spacer()
                
                Text(value)
                    .font(AppFonts.title)
                    .foregroundColor(AppColors.primary)
                    .fontWeight(.bold)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding()
        .cardStyle(isDarkMode: themeManager.isDarkMode)
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserManager())
        .environmentObject(ThemeManager())
}
