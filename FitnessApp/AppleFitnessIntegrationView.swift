import SwiftUI
import HealthKit
import WatchConnectivity

// MARK: - Design System
private struct DesignSystem {
    static let padding: CGFloat = 16
    static let cornerRadius: CGFloat = 16
    
    struct Colors {
        static let background = Color(UIColor.systemGroupedBackground)
        static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let accent = Color.blue
    }
}

struct AppleFitnessIntegrationView: View {
    @EnvironmentObject var healthManager: HealthKitManagerSimple
    @State private var viewState: ViewState = .loading
    @State private var isInitialized = false
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()
                
                switch viewState {
                case .loading:
                    LoadingView()
                case .error(let errorMessage):
                    ErrorView(message: errorMessage, buttonTitle: "Abrir Configuración") {
                        openSettings()
                    }
                case .content:
                    mainContent
                }
            }
            .navigationTitle("Apple Fitness")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshData) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewState == .loading)
                }
            }
            .onAppear {
                if !isInitialized {
                    initializeHealthData()
                }
            }
            .alert("Permisos de Salud Necesarios", isPresented: $showingPermissionAlert) {
                Button("Ir a Configuración", action: openSettings)
                Button("Autorizar", action: requestPermissions)
                Button("Cancelar", role: .cancel) { }
            } message: {
                Text("Necesitamos acceso a tus datos de salud para mostrar información precisa en la aplicación. Si ya has rechazado los permisos anteriormente, deberás habilitarlos manualmente en la configuración de Salud.")
            }
        }
    }
    
    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.padding) {
                StatusBannerView(isConnected: healthManager.appleWatchConnected, isLoading: healthManager.isLoading)
                
                CardView(title: "Resumen Diario") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.padding), count: 2), spacing: DesignSystem.padding) {
                        HealthMetricCard(
                            title: "Pasos",
                            value: "\(healthManager.todaySteps)",
                            systemImage: "figure.walk",
                            color: .blue
                        )
                        
                        HealthMetricCard(
                            title: "Calorías",
                            value: "\(Int(healthManager.todayCalories))",
                            systemImage: "flame.fill",
                            color: .orange
                        )
                        
                        HealthMetricCard(
                            title: "Distancia",
                            value: String(format: "%.1f km", healthManager.todayDistance),
                            systemImage: "location.fill",
                            color: .green
                        )
                        
                        HealthMetricCard(
                            title: "Ritmo Cardíaco",
                            value: "\(Int(healthManager.heartRate)) bpm",
                            systemImage: "heart.fill",
                            color: .red
                        )
                    }
                }
                
                CardView(title: "Pasos Semanales") {
                    WeeklyStepsChart(steps: healthManager.weeklyStepsArray)
                }
                
                CardView(title: "Entrenamientos Recientes") {
                    if healthManager.workouts.isEmpty {
                        Text("No se han encontrado entrenamientos recientes.")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .padding(.vertical)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(healthManager.workouts.prefix(3), id: \.uuid) { workout in
                                CompactWorkoutRow(workout: workout)
                            }
                        }
                    }
                }
            }
            .padding(DesignSystem.padding)
        }
    }
    
    
    // MARK: - Logic
    private func initializeHealthData() {
        guard !isInitialized else { 
            print("⚠️ Ya está inicializado, saltando...")
            return 
        }
        
        isInitialized = true
        viewState = .loading
        
        print("🏃‍♂️ Iniciando inicialización de datos de salud...")
        
        Task {
            await performHealthInitialization()
        }
    }
    
    private func refreshData() {
        Task {
            await healthManager.loadAllData()
        }
    }
    
    private func requestPermissions() {
        Task {
            let success = await healthManager.requestPermissions()
            if success {
                initializeHealthData()
            }
        }
    }
    
    private func openSettings() {
        // Primero intentamos abrir directamente la app de Salud
        let healthAppUrl = URL(string: "x-apple-health://")
        if let url = healthAppUrl, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url) { success in
                if !success {
                    // Si no se puede abrir la app de Salud, intentamos con la configuración de Salud
                    self.openHealthSettings()
                }
            }
        } else {
            // Si no se puede abrir la app de Salud, intentamos con la configuración de Salud
            self.openHealthSettings()
        }
    }
    
    private func openHealthSettings() {
        // Abrimos la configuración de Salud
        let healthSettingsUrl = URL(string: "App-prefs:root=HEALTH")
        if let url = healthSettingsUrl, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url) { success in
                if !success {
                    // Si no se puede abrir la configuración de Salud, abrimos la configuración general de la app
                    self.openAppSettings()
                }
            }
        } else {
            // Fallback a la configuración general de la app
            self.openAppSettings()
        }
    }
    
    private func openAppSettings() {
        // Abrimos la configuración general de la app
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func performHealthInitialization() async {
        print("🔑 Solicitando autorización...")
        let authorized = await healthManager.requestAuthorization()
        
        if authorized {
            print("✅ HealthKit autorizado, cargando datos...")
            await healthManager.loadAllData()
            await MainActor.run {
                self.viewState = .content
                print("📊 Datos cargados exitosamente")
            }
        } else {
            print("❌ HealthKit no autorizado")
            
            // Si la autorización falló, intentamos solicitar permisos una vez más
            let permissionsResult = await healthManager.requestPermissions()
            
            if permissionsResult {
                print("✅ Permisos de HealthKit obtenidos en segundo intento, cargando datos...")
                await healthManager.loadAllData()
                await MainActor.run {
                    self.viewState = .content
                    print("📊 Datos cargados exitosamente")
                }
            } else {
                await MainActor.run {
                    self.viewState = .error("Necesitamos permisos para acceder a tus datos de salud. Actívalos en la app Salud o en Configuración > Privacidad > Salud > FitnessApp.")
                }
            }
        }
    }
    
    enum ViewState: Equatable {
        case loading
        case content
        case error(String)
    }
}

// MARK: - Reusable UI Components
struct CardView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            content
        }
        .padding(DesignSystem.padding)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.cornerRadius)
    }
}

struct StatusBannerView: View {
    let isConnected: Bool
    let isLoading: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isConnected ? "applewatch.watchface" : "applewatch.slash")
                .foregroundColor(isConnected ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                if isConnected {
                    Text("Apple Watch Conectado")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    Text("Datos sincronizados")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Apple Watch Desconectado")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    #if targetEnvironment(simulator)
                    Text("Datos simulados")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    #else
                    Text("Conecta tu Apple Watch")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    #endif
                }
            }
            
            Spacer()
            
            #if targetEnvironment(simulator)
            Text("SIM")
                .font(.caption.bold())
                .padding(.horizontal, 6)
                .background(Color.gray.opacity(0.5))
                .cornerRadius(4)
            #endif
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .font(.subheadline.weight(.medium))
        .padding(12)
        .background(isConnected ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(DesignSystem.cornerRadius)
    }
}

struct HealthMetricCard: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundColor(color)
            
            Spacer()
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(1)
            
            Text(title)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(DesignSystem.cornerRadius)
    }
}

struct WeeklyStepsChart: View {
    let steps: [Int]
    @State private var selectedIndex: Int? = nil
    
    private let weekDays = ["L", "M", "X", "J", "V", "S", "D"]
    
    var body: some View {
        let maxSteps = max(steps.max() ?? 1, 1)
        let safeSteps = steps.count == 7 ? steps : Array(repeating: 0, count: 7)
        
        VStack(spacing: 12) {
            if let selectedIndex = selectedIndex {
                Text("Pasos: **\(safeSteps[selectedIndex])**")
                    .font(.subheadline)
                    .transition(.opacity)
            } else {
                Text("Total semanal: **\(safeSteps.reduce(0, +))**")
                    .font(.subheadline)
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 4) {
                        Capsule()
                            .fill(selectedIndex == index ? DesignSystem.Colors.accent : Color.blue.opacity(0.7))
                            .frame(width: 32, height: max(CGFloat(safeSteps[index]) / CGFloat(maxSteps) * 80, 3))
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    selectedIndex = (selectedIndex == index) ? nil : index
                                }
                            }
                        
                        Text(weekDays[index])
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(safeSteps[index])")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .frame(height: 150)
    }
}

struct CompactWorkoutRow: View {
    let workout: HKWorkout
    
    var body: some View {
        HStack {
            Image(systemName: icon(for: workout.workoutActivityType))
                .font(.title2)
                .foregroundColor(color(for: workout.workoutActivityType))
                .frame(width: 40)

            VStack(alignment: .leading) {
                Text(workout.workoutActivityType.name)
                    .font(.subheadline.bold())
                Text(workout.startDate, style: .date)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(Int(workout.duration/60)) min")
                    .font(.subheadline.weight(.semibold))
                if let energyStats = workout.statistics(for: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!),
                   let totalEnergy = energyStats.sumQuantity() {
                    Text("\(Int(totalEnergy.doubleValue(for: .kilocalorie()))) kcal")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                } else {
                    Text("-- kcal")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    // Helper para íconos y colores
    private func icon(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .traditionalStrengthTraining: return "figure.strengthtraining.traditional"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        default: return "figure.mixed.cardio"
        }
    }
    
    private func color(for type: HKWorkoutActivityType) -> Color {
        switch type {
        case .running: return .blue
        case .walking: return .green
        case .traditionalStrengthTraining: return .orange
        case .cycling: return .purple
        case .swimming: return .cyan
        default: return .pink
        }
    }
}

// MARK: - Compact Workout Card (mantener para compatibilidad)
struct CompactWorkoutCard: View {
    let workout: HKWorkout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(workoutTypeString(for: workout.workoutActivityType))
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Text("\(Int(workout.duration/60))m")
                .font(.title3)
                .fontWeight(.bold)
            
            if let energyStats = workout.statistics(for: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!),
               let totalEnergy = energyStats.sumQuantity() {
                Text("\(Int(totalEnergy.doubleValue(for: .kilocalorie())))kcal")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .frame(width: 100, height: 80)
    }
    
    private func workoutTypeString(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "Correr"
        case .walking: return "Caminar"
        case .cycling: return "Ciclismo"
        case .swimming: return "Natación"
        case .other: return "Otro"
        default: return "Ejercicio"
        }
    }
}

// MARK: - State Views
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Cargando datos de Salud...")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Text("Esto puede tardar unos segundos")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

struct ErrorView: View {
    let message: String
    let buttonTitle: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 60))
                .foregroundColor(.pink)
            
            Text("Acceso a Salud Requerido")
                .font(.title2.bold())
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                PermissionRow(icon: "figure.walk", title: "Pasos", description: "Contar tus pasos diarios")
                PermissionRow(icon: "flame.fill", title: "Calorías", description: "Mostrar calorías quemadas")
                PermissionRow(icon: "heart.fill", title: "Ritmo Cardíaco", description: "Ver tu ritmo cardíaco")
                PermissionRow(icon: "figure.run", title: "Entrenamientos", description: "Acceder a entrenamientos registrados")
            }
            .padding(.vertical)
            
            Button(buttonTitle, action: retryAction)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.horizontal)
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.cornerRadius)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding()
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Models and Extensions
extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Carrera"
        case .walking: return "Caminata"
        case .cycling: return "Ciclismo"
        case .swimming: return "Natación"
        case .traditionalStrengthTraining: return "Entrenamiento de Fuerza"
        default: return "Ejercicio"
        }
    }
}

enum HealthKitError: LocalizedError {
    case notAuthorized
    case notAvailable
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "HealthKit no está autorizado. Por favor, habilita los permisos en Configuración."
        case .notAvailable:
            return "HealthKit no está disponible en este dispositivo."
        }
    }
}

#Preview {
    AppleFitnessIntegrationView()
}
