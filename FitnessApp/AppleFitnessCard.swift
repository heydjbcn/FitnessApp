import SwiftUI

struct FitnessActivityData {
    let steps: Int
    let calories: Int
    let distance: Double  // in kilometers
    let exerciseMinutes: Int
}

struct AppleFitnessCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    // Generate consistent activity data based on current day
    private var activityData: FitnessActivityData {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        
        // Use day as seed for consistent daily values
        var generator = SeededRandomNumberGenerator(seed: UInt64(dayOfYear))
        
        let steps = Int.random(in: 8000...15000, using: &generator)
        let calories = Int.random(in: 300...800, using: &generator)
        let distance = Double.random(in: 5.0...12.0, using: &generator)
        let exerciseMinutes = Int.random(in: 20...60, using: &generator)
        
        return FitnessActivityData(
            steps: steps,
            calories: calories,
            distance: distance,
            exerciseMinutes: exerciseMinutes
        )
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Actividad Diaria")
                .font(AppFonts.title2)
                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
            
            HStack(spacing: 20) {
                // Steps
                ActivityRing(
                    value: Double(activityData.steps),
                    goal: 10000,
                    color: .blue,
                    label: "Pasos",
                    unit: ""
                )
                
                // Calories
                ActivityRing(
                    value: Double(activityData.calories),
                    goal: 500,
                    color: .red,
                    label: "Calorías",
                    unit: "kcal"
                )
                
                // Distance
                ActivityRing(
                    value: activityData.distance,
                    goal: 8.0,
                    color: .green,
                    label: "Distancia",
                    unit: "km"
                )
                
                // Exercise Minutes
                ActivityRing(
                    value: Double(activityData.exerciseMinutes),
                    goal: 30,
                    color: .purple,
                    label: "Ejercicio",
                    unit: "min"
                )
            }
        }
        .padding()
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ActivityRing: View {
    let value: Double
    let goal: Double
    let color: Color
    let label: String
    let unit: String
    
    private var progress: Double {
        min(value / goal, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 8)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(progress))
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: progress)
                
                VStack(spacing: 2) {
                    if unit.isEmpty {
                        Text("\(Int(value))")
                            .font(AppFonts.caption)
                            .fontWeight(.bold)
                    } else {
                        Text(String(format: "%.0f", value))
                            .font(AppFonts.caption)
                            .fontWeight(.bold)
                    }
                }
            }
            
            VStack(spacing: 2) {
                Text(label)
                    .font(AppFonts.label)

                if !unit.isEmpty {
                    Text(unit)
                        .font(AppFonts.label)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// Seeded random number generator for consistent daily values
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    mutating func next() -> UInt64 {
        state = state &* 1103515245 &+ 12345
        return state
    }
}

extension Int {
    static func random(in range: ClosedRange<Int>, using generator: inout SeededRandomNumberGenerator) -> Int {
        let randomValue = generator.next()
        let rangeSize = UInt64(range.count)
        let scaledValue = randomValue % rangeSize
        return range.lowerBound + Int(scaledValue)
    }
}

extension Double {
    static func random(in range: ClosedRange<Double>, using generator: inout SeededRandomNumberGenerator) -> Double {
        let randomValue = generator.next()
        let normalizedValue = Double(randomValue) / Double(UInt64.max)
        return range.lowerBound + normalizedValue * (range.upperBound - range.lowerBound)
    }
}

#Preview {
    AppleFitnessCard()
        .environmentObject(ThemeManager())
}