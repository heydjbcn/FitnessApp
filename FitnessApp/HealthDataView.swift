import SwiftUI
import HealthKit
import WatchConnectivity

struct HealthDataView: View {
    @EnvironmentObject var healthKitManager: HealthKitManagerSimple
    @EnvironmentObject var themeManager: ThemeManager
    @State private var activityData: ActivityData?
    @State private var workouts: [WorkoutData] = []
    @State private var isLoading = true
    @State private var showingAuthAlert = false
    @State private var useSimulatedData = false
    @State private var hasInitialized = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if !healthKitManager.isHealthKitAvailable || useSimulatedData {
                        simulatedDataView
                    } else if !healthKitManager.isAuthorized {
                        authorizationView
                    } else if isLoading {
                        loadingView
                    } else {
                        contentView
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 60)
            }
            .refreshable {
                await refreshData()
            }
            .navigationTitle("Apple Fitness")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Actualizar") {
                        Task {
                            await refreshData()
                        }
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
        .task {
            // Solo ejecutar una vez al inicializar
            if !hasInitialized {
                hasInitialized = true
                await setupHealthKit()
            }
        }
        .alert("Autorización requerida", isPresented: $showingAuthAlert) {
            Button("Usar datos simulados") {
                useSimulatedData = true
                showingAuthAlert = false
            }
            Button("Cancelar", role: .cancel) {
                showingAuthAlert = false
            }
        } message: {
            Text("HealthKit no está disponible o no se pudo autorizar. ¿Quieres usar datos simulados para ver cómo funciona?")
        }
    }
    
    private var simulatedDataView: some View {
        VStack(spacing: 20) {
            // Banner informativo
            VStack(spacing: 12) {
                Image(systemName: "heart.circle")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
                
                Text("Datos de demostración")
                    .font(AppFonts.subtitle)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Text("Mostrando datos de ejemplo. Para ver datos reales de Apple Health, toca el botón de abajo.")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    .multilineTextAlignment(.center)
                
                Button("Conectar con Apple Health") {
                    Task {
                        await tryRealHealthKit()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
                .disabled(isLoading)
            }
            .padding()
            .cardStyle(isDarkMode: themeManager.isDarkMode)
            
            // Datos simulados
            dailyActivityCard(simulatedActivityData)
            simulatedWorkoutsSection
        }
    }
    
    private var simulatedActivityData: ActivityData {
        ActivityData(
            steps: 8547,
            activeCalories: 342,
            calories: 342,
            distance: 6.2,
            heartRate: 75.0,
            date: Date()
        )
    }
    
    private var simulatedWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "dumbbell")
                    .foregroundColor(AppColors.primary)
                    .font(.title2)
                
                Text("Entrenamientos simulados")
                    .font(AppFonts.subtitle)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Spacer()
            }
            
            ForEach(simulatedWorkouts, id: \.id) { workout in
                WorkoutCard(workout: workout)
                    .environmentObject(themeManager)
            }
        }
        .padding()
        .cardStyle(isDarkMode: themeManager.isDarkMode)
    }
    
    private var simulatedWorkouts: [WorkoutData] {
        [
            WorkoutData(
                activityType: "running",
                name: "Carrera",
                duration: 3600, // 1 hora
                totalEnergyBurned: 520,
                totalDistance: 8.5, // 8.5 km
                calories: 520,
                date: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
                type: "Running",
                startDate: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
            ),
            WorkoutData(
                activityType: "traditionalStrengthTraining",
                name: "Entrenamiento de Fuerza",
                duration: 2700, // 45 minutos
                totalEnergyBurned: 280,
                totalDistance: nil,
                calories: 280,
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                type: "Strength",
                startDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            ),
            WorkoutData(
                activityType: "cycling",
                name: "Ciclismo",
                duration: 3600, // 1 hora
                totalEnergyBurned: 420,
                totalDistance: 15.0, // 15 km
                calories: 420,
                date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                type: "Cycling",
                startDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
            )
        ]
    }
    
    private var unavailableView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 50))
                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            
            Text("HealthKit no disponible")
                .font(AppFonts.subtitle)
                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
            
            Text("Los datos de salud no están disponibles en este dispositivo.")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                .multilineTextAlignment(.center)
        }
        .padding()
        .cardStyle(isDarkMode: themeManager.isDarkMode)
    }
    
    private var authorizationView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.circle")
                .font(.system(size: 50))
                .foregroundColor(AppColors.primary)
            
            Text("Conectar con Apple Fitness")
                .font(AppFonts.subtitle)
                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
            
            Text("Permite que la app acceda a tus datos de actividad para mostrarte un resumen completo de tu actividad física.")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                .multilineTextAlignment(.center)
            
            Button("Autorizar acceso") {
                Task {
                    await healthKitManager.requestAuthorization()
                    if healthKitManager.isAuthorized {
                        await refreshData()
                    } else {
                        showingAuthAlert = true
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primary)
        }
        .padding()
        .cardStyle(isDarkMode: themeManager.isDarkMode)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(AppColors.primary)
            
            Text("Cargando datos de actividad...")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
        }
        .padding()
        .cardStyle(isDarkMode: themeManager.isDarkMode)
    }
    
    private var contentView: some View {
        VStack(spacing: 20) {
            // Resumen diario
            if let activityData = activityData {
                dailyActivityCard(activityData)
            }
            
            // Workouts recientes
            if !workouts.isEmpty {
                recentWorkoutsSection
            } else {
                noWorkoutsView
            }
        }
    }
    
    private func dailyActivityCard(_ data: ActivityData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(AppColors.primary)
                    .font(.title2)
                
                Text("Actividad de hoy")
                    .font(AppFonts.subtitle)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Spacer()
                
                Text(formatDate(data.date))
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ActivityMetricCard(
                    icon: "figure.walk",
                    title: "Pasos",
                    value: "\(data.steps)",
                    subtitle: "pasos"
                )
                
                ActivityMetricCard(
                    icon: "flame",
                    title: "Calorías",
                    value: "\(data.activeCalories)",
                    subtitle: "cal activas"
                )
                
                ActivityMetricCard(
                    icon: "location",
                    title: "Distancia",
                    value: String(format: "%.1f", data.distance),
                    subtitle: "km caminando"
                )
                
                ActivityMetricCard(
                    icon: "timer",
                    title: "Ejercicio",
                    value: "45", // Tiempo de ejercicio simulado
                    subtitle: "minutos"
                )
            }
        }
        .padding()
        .cardStyle(isDarkMode: themeManager.isDarkMode)
    }
    
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "dumbbell")
                    .foregroundColor(AppColors.primary)
                    .font(.title2)
                
                Text("Entrenamientos recientes")
                    .font(AppFonts.subtitle)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Spacer()
            }
            
            ForEach(Array(workouts.prefix(5).enumerated()), id: \.offset) { index, workout in
                WorkoutCard(workout: workout)
                    .environmentObject(themeManager)
            }
        }
        .padding()
        .cardStyle(isDarkMode: themeManager.isDarkMode)
    }
    
    private var noWorkoutsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell")
                .font(.system(size: 40))
                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            
            Text("Sin entrenamientos recientes")
                .font(AppFonts.subtitle)
                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
            
            Text("Los entrenamientos registrados en Apple Fitness aparecerán aquí.")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                .multilineTextAlignment(.center)
        }
        .padding()
        .cardStyle(isDarkMode: themeManager.isDarkMode)
    }
    
    private func setupHealthKit() async {
        // En simulador o si HealthKit no está disponible, usar datos simulados automáticamente
        guard healthKitManager.isHealthKitAvailable else {
            await MainActor.run {
                useSimulatedData = true
                isLoading = false
            }
            return
        }
        
        // En dispositivo real, intentar autorización
        await healthKitManager.requestAuthorization()
        
        await MainActor.run {
            if healthKitManager.isAuthorized {
                // Autorización exitosa, cargar datos reales
                useSimulatedData = false
                Task {
                    await refreshData()
                }
            } else {
                // Sin autorización, usar datos simulados sin mostrar alerta agresiva
                useSimulatedData = true
                print("ℹ️ Usando datos simulados: HealthKit no autorizado")
            }
            isLoading = false
        }
    }
    
    private func refreshData() async {
        guard healthKitManager.isAuthorized else { return }
        
        async let activityTask = healthKitManager.fetchRecentActivityData()
        async let workoutsTask = healthKitManager.fetchRecentWorkoutsData()
        
        activityData = await activityTask
        workouts = await workoutsTask
    }
    
    private func tryRealHealthKit() async {
        await MainActor.run {
            isLoading = true
        }
        
        await healthKitManager.requestAuthorization()
        
        await MainActor.run {
            if healthKitManager.isAuthorized {
                useSimulatedData = false
                Task {
                    await refreshData()
                }
                print("✅ HealthKit autorizado, cambiando a datos reales")
            } else {
                showingAuthAlert = true
                print("❌ HealthKit no autorizado")
            }
            isLoading = false
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
}

struct ActivityMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppColors.primary)
                    .font(.title3)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(12)
    }
}

struct WorkoutCard: View {
    let workout: WorkoutData
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Icono del tipo de actividad
            Image(systemName: iconForActivity(workout.activityType))
                .font(.title2)
                .foregroundColor(AppColors.primary)
                .frame(width: 40, height: 40)
                .background(AppColors.primary.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Text(formatWorkoutDate(workout.startDate))
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                
                HStack(spacing: 16) {
                    Label(formatDuration(workout.duration), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    
                    if let distance = workout.totalDistance {
                        Label(formatDistance(distance), systemImage: "location")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    }
                    
                    Label(formatCalories(workout.calories), systemImage: "flame")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(AppColors.background(isDark: themeManager.isDarkMode))
        .cornerRadius(12)
    }
    
    private func iconForActivity(_ type: String) -> String {
        switch type {
        case "running":
            return "figure.run"
        case "walking":
            return "figure.walk"
        case "cycling":
            return "bicycle"
        case "swimming":
            return "figure.pool.swim"
        case "yoga":
            return "figure.yoga"
        case "traditionalStrengthTraining", "functionalStrengthTraining":
            return "dumbbell"
        case "hiking":
            return "figure.hiking"
        case "dance":
            return "figure.dance"
        case "soccer":
            return "soccerball"
        case "basketball":
            return "basketball"
        case "tennis":
            return "tennisball"
        default:
            return "figure.strengthtraining.traditional"
        }
    }
    
    private func formatWorkoutDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        } else {
            return String(format: "%.0f m", distance)
        }
    }
    
    private func formatCalories(_ calories: Double) -> String {
        return String(format: "%.0f cal", calories)
    }
}

#Preview {
    HealthDataView()
        .environmentObject(ThemeManager())
}
