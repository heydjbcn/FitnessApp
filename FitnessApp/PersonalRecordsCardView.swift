import SwiftUI

struct PersonalRecordsCardView: View {
    @ObservedObject var workoutViewModel: WorkoutViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                        .font(.title2)
                    
                    Text("Personal Records")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                Text("TOP 5")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // Personal Records List
            let topRecords = workoutViewModel.getTopPersonalRecords(limit: 5)
            
            if topRecords.isEmpty {
                // Estado vacío
                VStack(spacing: 8) {
                    Image(systemName: "trophy")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Text("Sin récords aún")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("¡Completa ejercicios para establecer tus primeros Personal Records!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Lista de récords
                VStack(spacing: 8) {
                    ForEach(Array(topRecords.enumerated()), id: \.offset) { index, record in
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct PersonalRecordRow: View {
    let rank: Int
    let exerciseName: String
    let weight: Double
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 24, height: 24)
                
                Text("\(rank)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Exercise name
            Text(exerciseName)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Spacer()
            
            // Weight with trophy icon
            HStack(spacing: 4) {
                Text("\(weight, specifier: "%.1f") kg")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Image(systemName: "trophy.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
        )
    }
    
    private var rankColor: Color {
        switch rank {
        case 1:
            return .yellow  // Oro
        case 2:
            return .gray    // Plata
        case 3:
            return .orange  // Bronce
        default:
            return .blue    // Otros
        }
    }
}

#Preview {
    PersonalRecordsCardView(workoutViewModel: WorkoutViewModel())
        .padding()
}
