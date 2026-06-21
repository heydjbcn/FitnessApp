import SwiftUI

struct PersonalRecordsCardView: View {
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                        .font(.title2)
                    
                    Text("Récords Personales")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                }
                
                Spacer()
                
                Text("TOP 5")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            
            if getTopPersonalRecordDisplays().isEmpty {
                emptyState
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(getTopPersonalRecordDisplays().enumerated()), id: \.offset) { index, record in
                        PersonalRecordRow(
                            rank: index + 1,
                            exerciseName: record.exerciseName,
                            weight: record.weight
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Helper Functions
    private func getTopPersonalRecordDisplays() -> [PersonalRecordDisplay] {
        var recordsMap: [UUID: PersonalRecordDisplay] = [:]
        
        // Recorrer todos los días y ejercicios para encontrar récords
        for day in WorkoutDay.allCases {
            if let records = workoutViewModel.dailyWorkoutRecords[day] {
                for record in records {
                    if let exercise = workoutViewModel.getExercise(by: record.exerciseId) {
                        let bestWeight = record.weight
                        
                        if bestWeight > 0 {
                            let existingRecord: PersonalRecordDisplay? = recordsMap[record.exerciseId]
                            if existingRecord == nil || bestWeight > existingRecord!.weight {
                                recordsMap[record.exerciseId] = PersonalRecordDisplay(
                                    exerciseId: record.exerciseId,
                                    exerciseName: exercise.name,
                                    weight: bestWeight
                                )
                            }
                        }
                    }
                }
            }
        }
        
        // Retornar los top 5 ordenados por peso
        return Array(recordsMap.values)
            .sorted { $0.weight > $1.weight }
            .prefix(5)
            .map { $0 }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy")
                .font(.largeTitle)
                .foregroundColor(.gray)
            
            Text("Sin récords aún")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("¡Completa ejercicios para establecer tus primeros Récords Personales!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Personal Record Model
struct PersonalRecordDisplay {
    let exerciseId: UUID
    let exerciseName: String
    let weight: Double
}

struct PersonalRecordRow: View {
    let rank: Int
    let exerciseName: String
    let weight: Double
    @EnvironmentObject var themeManager: ThemeManager
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return AppColors.primary(themeManager: themeManager)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(rankColor).frame(width: 24, height: 24)
                Text("\(rank)").font(.caption).fontWeight(.bold).foregroundColor(.white)
            }
            
            Text(exerciseName).font(.subheadline).fontWeight(.medium).lineLimit(1)
            Spacer()
            
            HStack(spacing: 4) {
                Text("\(weight, specifier: "%.1f") kg").font(.subheadline).fontWeight(.semibold)
                Image(systemName: "trophy.fill").font(.caption).foregroundColor(.yellow)
            }
        }
        .padding(8)
        .background(AppColors.background(isDark: themeManager.isDarkMode))
        .cornerRadius(8)
    }
}
