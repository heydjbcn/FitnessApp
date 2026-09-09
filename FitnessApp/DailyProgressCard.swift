import SwiftUI

struct DailyProgressCard: View {
    let day: WorkoutDay
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.displayName)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        .font(AppFonts.subtitle)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Progress circle
                ZStack {
                    Circle()
                        .stroke(AppColors.cardBackground(isDark: themeManager.isDarkMode), lineWidth: 4)
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(dailyProgress))
                        .stroke(AppColors.primary(themeManager: themeManager), lineWidth: 4)
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(dailyProgress * 100))%")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        .fontWeight(.medium)
                }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.primary(themeManager: themeManager))
                            .font(.caption)
                        Text("Series")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    }
                    Text("\(completedSets)/\(totalSets)")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .foregroundColor(AppColors.primary(themeManager: themeManager))
                            .font(.caption)
                        Text("Tiempo")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    }
                    Text("\(estimatedMinutes) min")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
        }
        .padding(12)
        .cardStyle(isDarkMode: themeManager.isDarkMode)
    }
}

extension DailyProgressCard {
    private var exercisesForDay: [WorkoutExercise] {
        viewModel.dailyWorkoutRecords[day] ?? []
    }
    
    private var totalSets: Int {
        exercisesForDay.compactMap { record in
            viewModel.getExercise(by: record.exerciseId)?.totalSets
        }.reduce(0, +)
    }
    
    private var completedSets: Int {
        exercisesForDay.map { $0.completedSets }.reduce(0, +)
    }
    
    private var dailyProgress: Double {
        guard totalSets > 0 else { return 0 }
        return Double(completedSets) / Double(totalSets)
    }
    
    private var estimatedMinutes: Int {
        exercisesForDay.compactMap { record in
            viewModel.getExercise(by: record.exerciseId)?.totalSets
        }.reduce(0, +) * 2 // Estimamos 2 minutos por serie
    }
}

#Preview {
    DailyProgressCard(day: .monday)
        .environmentObject(WorkoutViewModel())
        .environmentObject(UserManager())
        .environmentObject(ThemeManager())
        .padding()
}