import SwiftUI
import HealthKit

struct HealthDataView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var isHealthKitAuthorized = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        
                        Text("Datos de Salud")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        
                        Text("Conecta con Apple Health para un seguimiento completo")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Estado de HealthKit
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: isHealthKitAuthorized ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .foregroundColor(isHealthKitAuthorized ? .green : .orange)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isHealthKitAuthorized ? "Conectado a Apple Health" : "No conectado")
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                
                                Text(isHealthKitAuthorized ? "Los datos se sincronizan automáticamente" : "Toca para conectar y sincronizar datos")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                            }
                            
                            Spacer()
                        }
                        
                        if !isHealthKitAuthorized {
                            Button(action: requestHealthKitAuthorization) {
                                Text("Conectar con Apple Health")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(20)
                    .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                    .cornerRadius(16)
                    
                    // Información sobre qué datos se sincronizan
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Datos que se sincronizan:")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        
                        HealthDataRow(icon: "figure.strengthtraining.traditional", title: "Entrenamientos de fuerza", subtitle: "Rutinas y ejercicios completados")
                        HealthDataRow(icon: "heart.fill", title: "Frecuencia cardíaca", subtitle: "Durante los entrenamientos")
                        HealthDataRow(icon: "flame.fill", title: "Calorías quemadas", subtitle: "Estimación basada en ejercicios")
                        HealthDataRow(icon: "clock.fill", title: "Tiempo de entrenamiento", subtitle: "Duración de las sesiones")
                    }
                    .padding(20)
                    .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                    .cornerRadius(16)
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
            }
            .background(AppColors.background(isDark: themeManager.isDarkMode))
            .navigationBarTitleDisplayMode(.inline)
            .alert("Apple Health", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
        .onAppear {
            checkHealthKitAuthorization()
        }
    }
    
    private func checkHealthKitAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            isHealthKitAuthorized = false
            return
        }
        
        // Simplificado - solo verificar si está disponible
        isHealthKitAuthorized = false
    }
    
    private func requestHealthKitAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            alertMessage = "Apple Health no está disponible en este dispositivo"
            showingAlert = true
            return
        }
        
        alertMessage = "Funcionalidad de Apple Health estará disponible en una futura actualización"
        showingAlert = true
    }
}

struct HealthDataRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.red)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }
            
            Spacer()
        }
    }
}
