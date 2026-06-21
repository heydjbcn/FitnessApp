import SwiftUI

struct CustomCalendarView: View {
    @Binding var selectedDate: Date?
    @State private var currentMonth = Date()
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var viewModel: WorkoutViewModel
    
    private let calendar: Calendar = {
        var cal = Calendar.current
        cal.locale = Locale(identifier: "es_ES")
        cal.firstWeekday = 2 // Lunes = 1, así que 2 hace que lunes sea el primer día
        return cal
    }()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 8) {
            // Header con mes y año
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                        .font(.system(size: 15, weight: .semibold))
                }

                Spacer()

                Text(dateFormatter.string(from: currentMonth))
                    .font(AppFonts.subtitle)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .padding(.horizontal, 4)

            // Días de la semana
            HStack {
                ForEach(weekdays, id: \.self) { dayInitial in
                    Text(dayInitial)
                        .font(AppFonts.label)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                        .frame(maxWidth: .infinity)
                }
            }

            // Grid de días
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(daysInMonth, id: \.self) { date in
                    DayView(date: date, selectedDate: $selectedDate, currentMonth: currentMonth)
                        .environmentObject(themeManager)
                        .environmentObject(viewModel)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.09), radius: 12, x: 0, y: 6)
        .onAppear {
            // Asegurar que currentMonth se inicialice correctamente
            if selectedDate == nil {
                selectedDate = Date()
            }
        }
    }
    
    private var weekdays: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        // Obtener los símbolos de días de la semana empezando por lunes
        var weekdaySymbols = formatter.shortWeekdaySymbols!
        // Rotar el array para que lunes sea el primero
        let sunday = weekdaySymbols.removeFirst()
        weekdaySymbols.append(sunday)
        return weekdaySymbols.map { String($0.prefix(1)).uppercased() }
    }
    
    private var daysInMonth: [Date] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: currentMonth) else { return [] }
        
        let firstDayOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        var firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        // Ajustar para que lunes sea 0 (weekday: Dom=1, Lun=2, etc.)
        firstWeekday = (firstWeekday + 5) % 7
        
        var days: [Date] = []
        
        // Añadir días del mes anterior
        if firstWeekday > 0 {
            let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
            if let previousMonthRange = calendar.range(of: .day, in: .month, for: previousMonth) {
                let daysFromPreviousMonth = firstWeekday
                for i in (previousMonthRange.count - daysFromPreviousMonth + 1)...previousMonthRange.count {
                    if let date = calendar.date(byAdding: .day, value: i - 1, to: calendar.dateInterval(of: .month, for: previousMonth)?.start ?? previousMonth) {
                        days.append(date)
                    }
                }
            }
        }
        
        // Añadir días del mes actual
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        // Añadir días del siguiente mes para completar la grid
        let totalCells = 42 // 6 semanas × 7 días
        let remainingCells = totalCells - days.count
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        let firstDayOfNextMonth = calendar.dateInterval(of: .month, for: nextMonth)?.start ?? nextMonth
        
        for i in 0..<remainingCells {
            if let date = calendar.date(byAdding: .day, value: i, to: firstDayOfNextMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
}

struct DayView: View {
    let date: Date
    @Binding var selectedDate: Date?
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var viewModel: WorkoutViewModel
    let currentMonth: Date
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: {
            selectedDate = date
        }) {
            ZStack {
                Text("\(calendar.component(.day, from: date))")
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(textColor)
                    .frame(width: 32, height: 32)
                    .background(backgroundColor)
                    .clipShape(Circle())

                // Indicador verde para días con entrenamiento
                if hasWorkout && isCurrentMonth {
                    Circle()
                        .fill(AppColors.primary(themeManager: themeManager))
                        .frame(width: 5, height: 5)
                        .offset(x: 11, y: -11)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var isSelected: Bool {
        guard let selectedDate = selectedDate else { return false }
        return calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    private var isCurrentMonth: Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
    
    private var hasWorkout: Bool {
        viewModel.hasWorkoutForDate(date)
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return AppColors.primary(themeManager: themeManager)
        } else if isToday {
            return AppColors.primary(themeManager: themeManager).opacity(0.3)
        } else {
            return Color.clear
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return AppColors.onPrimary(themeManager: themeManager)
        } else if isCurrentMonth {
            return AppColors.textPrimary(isDark: themeManager.isDarkMode)
        } else {
            return AppColors.textSecondary(isDark: themeManager.isDarkMode).opacity(0.5)
        }
    }
}
