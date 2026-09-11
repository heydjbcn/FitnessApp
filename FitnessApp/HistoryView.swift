//
//  HistoryView.swift
//  FitnessApp
//
//  Historial del rediseño «Pulso»: cifras de la semana, calendario del mes,
//  peso corporal y notas de cada sesión, lo que se hizo ese día y los récords.
//  Añade el volumen por grupo muscular, que la app ya calculaba.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager

    @State private var month = Date()
    @State private var date = Date()
    @State private var editingWeight = false
    @State private var weightInput = ""
    @State private var editingNote = false
    @State private var noteInput = ""
    @State private var confirmDelete = false
    @State private var detail: Exercise? = nil
    /// Fecha con la que se abre la ficha (desde lo hecho ese día: editar esas series).
    @State private var detailDate: Date? = nil
    @FocusState private var weightFocused: Bool

    private var p: Palette { themeManager.p }

    var body: some View {
        ZStack(alignment: .top) {
            PulsoBackground(p: p)
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeader(title: "Historial", subtitle: "Progreso, peso corporal, notas y récords", p: p)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        weekCard.padding(.bottom, 8)
                        statsGrid
                        MonthGrid(month: $month, selected: $date,
                                  hasWorkout: { viewModel.hasWorkoutForDate($0) }, p: p)
                            .padding(.top, 10)

                        Text(WeeklyCalendarView.longDate(date))
                            .font(.bri(18))
                            .em(-0.02, size: 18)
                            .foregroundColor(p.ink)
                            .padding(.horizontal, 4)
                            .padding(.top, 20)
                            .padding(.bottom, 4)

                        HStack(alignment: .top, spacing: 8) {
                            weightCard
                            noteCard
                        }
                        .padding(.top, 6)

                        dayItems
                        HealthWeekCard(p: p).padding(.top, 18)
                        recordsCard.padding(.top, 10)
                        muscleCard.padding(.top, 10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 120)
                }
                .scrollDismissesKeyboard(.interactively)
                .padding(.top, 10)
            }
        }
        .onChange(of: date) { _, _ in
            editingWeight = false
            editingNote = false
        }
        .task {
            // El peso de la báscula (vía Salud) entra solo si hoy no hay uno apuntado.
            if let w = await HealthManager.shared.latestBodyWeight(), Calendar.current.isDateInToday(w.date) {
                viewModel.importBodyWeight((w.kg * 10).rounded() / 10, date: w.date)
            }
        }
        .sheet(item: $detail) { ex in
            ExerciseDetailSheet(exerciseId: ex.id, focusDate: detailDate)
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
        .confirmationDialog("¿Borrar el historial de este día?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Borrar historial del día", role: .destructive) { viewModel.deleteHistory(for: date) }
        } message: {
            Text("Se borran las series registradas, el peso y la nota de \(WeeklyCalendarView.longDate(date).lowercased()).")
        }
    }

    // MARK: - Esta semana contra la anterior

    private var weekCard: some View {
        let now = viewModel.weekStats()
        let prev = viewModel.weekStats(offset: -1)
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Esta semana").font(.fig(16, .bold)).foregroundColor(p.ink)
                Spacer()
                Text("vs. anterior")
                    .font(.fig(10, .bold)).tracking(0.8).foregroundColor(p.mute)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(p.soft))
            }
            HStack(spacing: 8) {
                weekTile("Sesiones", "\(now.sessions)", delta: Double(now.sessions - prev.sessions), unit: "")
                weekTile("Series", "\(now.sets)", delta: Double(now.sets - prev.sets), unit: "")
                weekTile("Tonelaje", tonelaje(now.volume), delta: now.volume - prev.volume, unit: "kg")
                weekTile("Minutos", "\(now.minutes)", delta: Double(now.minutes - prev.minutes), unit: "")
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .pulsoCard(p, radius: 22)
    }

    private func weekTile(_ label: String, _ value: String, delta: Double, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.fig(11, .medium)).foregroundColor(p.mute)
            Text(value).font(.bri(18)).foregroundColor(p.ink).lineLimit(1).minimumScaleFactor(0.7)
            Group {
                if delta == 0 {
                    Text("=").foregroundColor(p.mute)
                } else {
                    let up = delta > 0
                    let abs = Swift.abs(delta)
                    let text = unit == "kg"
                        ? (abs >= 1000 ? String(format: "%.1f t", abs / 1000).replacingOccurrences(of: ".", with: ",") : "\(Int(abs.rounded())) kg")
                        : "\(Int(abs.rounded()))"
                    Text("\(up ? "▲" : "▼") \(text)")
                        .foregroundColor(up ? Pulso.ok(isDark: p.dark) : p.danger)
                }
            }
            .font(.fig(11, .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.soft))
    }

    private func tonelaje(_ kg: Double) -> String {
        kg >= 1000 ? String(format: "%.1f t", kg / 1000).replacingOccurrences(of: ".", with: ",") : "\(Int(kg.rounded())) kg"
    }

    // MARK: - Cifras

    private var statsGrid: some View {
        let best = viewModel.bestWorkoutDay()
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible())], spacing: 8) {
            stat(icon: "flame.fill", title: "Racha", value: "\(viewModel.consecutiveWorkoutDays())", sub: "días seguidos")
            stat(icon: "clock.fill", title: "Esta semana", value: "\(viewModel.weeklyTrainedMinutes())", sub: "min entrenados")
            stat(icon: "trophy.fill", title: "Mejor día", value: best?.day.shortLabel ?? "—",
                 sub: best.map { "\(Int(($0.pct * 100).rounded()))% completado" } ?? "sin datos")
            stat(icon: "dumbbell.fill", title: "Ejercicios", value: "\(viewModel.availableExercises.count)", sub: "únicos")
        }
    }

    private func stat(icon: String, title: String, value: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 11, weight: .semibold)).foregroundColor(p.acc)
                UpperLabel(text: title, p: p)
            }
            Text(value)
                .font(.bri(26))
                .foregroundColor(p.ink)
                .padding(.top, 8)
            Text(sub)
                .font(.fig(12, .medium))
                .foregroundColor(p.mute)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .pulsoCard(p, radius: 20)
    }

    // MARK: - Peso y notas

    private var weightCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "scalemass.fill").font(.system(size: 11, weight: .semibold)).foregroundColor(p.acc)
                UpperLabel(text: "Peso corporal", p: p)
            }
            if editingWeight {
                TextField("", text: $weightInput, prompt: Text("75,5").foregroundColor(p.mute.opacity(0.8)))
                    .keyboardType(.decimalPad)
                    .focused($weightFocused)
                    .font(.fig(16, .bold))
                    .foregroundColor(p.ink)
                    .padding(.horizontal, 12)
                    .frame(height: 42)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.soft))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(p.acc, lineWidth: 1))
                    .padding(.top, 10)
                    // El teclado tapa "Guardar": cerrarlo con "Listo" ya guarda.
                    .onChange(of: weightFocused) { _, focused in
                        if !focused && editingWeight { saveWeight() }
                    }
                PrimaryButton(title: "Guardar", height: 38, fontSize: 13, p: p) { saveWeight() }
                    .padding(.top, 8)
            } else {
                let w = viewModel.bodyWeightForDate(date)
                Text(w.map { WorkoutViewModel.kg($0) } ?? "Sin registrar")
                    .font(.bri(22))
                    .foregroundColor(w == nil ? p.mute : p.ink)
                    .padding(.top, 8)
                if let spark = sparkData {
                    WeightSpark(values: spark.values, p: p)
                        .frame(height: 40)
                        .padding(.top, 8)
                    Text(spark.trend)
                        .font(.fig(11, .medium))
                        .foregroundColor(p.mute)
                        .padding(.top, 4)
                }
                Spacer(minLength: 8)
                Button {
                    weightInput = viewModel.bodyWeightForDate(date).map { WorkoutViewModel.number($0) } ?? ""
                    editingWeight = true
                    weightFocused = true
                } label: {
                    Text("Editar").font(.fig(13, .semibold)).foregroundColor(p.acc)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 150, alignment: .topLeading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .pulsoCard(p, radius: 20)
    }

    private var sparkData: (values: [Double], trend: String)? {
        let values = viewModel.bodyWeightSeries().suffix(10).map(\.weight)
        guard values.count >= 2, let first = values.first, let last = values.last else { return nil }
        let delta = last - first
        let sign = delta > 0 ? "+" : delta < 0 ? "−" : ""
        let text = String(format: "%.1f", abs(delta)).replacingOccurrences(of: ".", with: ",")
        return (Array(values), "\(sign)\(text) kg en \(values.count) registros")
    }

    private func saveWeight() {
        if let w = Double(weightInput.replacingOccurrences(of: ",", with: ".")), w > 0 {
            viewModel.updateBodyWeight(for: date, weight: w)
            HapticManager.shared.success()
        }
        editingWeight = false
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "note.text").font(.system(size: 11, weight: .semibold)).foregroundColor(p.acc)
                UpperLabel(text: "Notas", p: p)
            }
            if editingNote {
                ZStack(alignment: .topLeading) {
                    if noteInput.isEmpty {
                        Text("¿Cómo fue la sesión?")
                            .font(.fig(13, .medium)).foregroundColor(p.mute.opacity(0.8))
                            .padding(.horizontal, 12).padding(.vertical, 10)
                    }
                    TextEditor(text: $noteInput)
                        .font(.fig(13, .medium))
                        .foregroundColor(p.ink)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                }
                .frame(height: 76)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.soft))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(p.acc, lineWidth: 1))
                .padding(.top, 10)
                HStack(spacing: 6) {
                    PrimaryButton(title: "Guardar", height: 36, fontSize: 13, p: p) {
                        viewModel.setNote(noteInput, for: date)
                        editingNote = false
                    }
                    Button { editingNote = false } label: {
                        Text("✕").font(.fig(12, .semibold)).foregroundColor(p.mute)
                            .padding(.horizontal, 10).frame(height: 36)
                            .overlay(Capsule().strokeBorder(p.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
            } else {
                if let note = viewModel.note(for: date) {
                    Text(note)
                        .font(.fig(13, .medium))
                        .lineSpacing(3)
                        .foregroundColor(p.ink)
                        .lineLimit(4)
                        .padding(.top, 8)
                } else {
                    Text("Sin notas para esta sesión")
                        .font(.fig(13, .medium))
                        .italic()
                        .foregroundColor(p.mute)
                        .padding(.top, 8)
                }
                Spacer(minLength: 8)
                Button {
                    noteInput = viewModel.note(for: date) ?? ""
                    editingNote = true
                } label: {
                    Text(viewModel.note(for: date) == nil ? "Añadir nota" : "Editar")
                        .font(.fig(13, .semibold)).foregroundColor(p.acc)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 150, alignment: .topLeading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .pulsoCard(p, radius: 20)
    }

    // MARK: - Lo que se hizo ese día

    @ViewBuilder private var dayItems: some View {
        let items = viewModel.historyItems(for: date)
        let weekday = WorkoutDay.from(date: date)
        if let other = items.first?.day, other != weekday {
            Text("Hiciste la rutina del \(other.displayName.lowercased())")
                .font(.fig(13, .medium))
                .foregroundColor(p.acc)
                .padding(.horizontal, 4)
                .padding(.top, 14)
        }
        if items.isEmpty {
            VStack(spacing: 4) {
                Text("No hay ejercicios completados").font(.fig(14, .semibold)).foregroundColor(p.ink)
                Text("en esta fecha").font(.fig(12, .medium)).foregroundColor(p.mute)
            }
            .frame(maxWidth: .infinity)
            .padding(22)
            .pulsoCard(p, radius: 20, dashed: true)
            .padding(.top, 10)
        } else {
            VStack(spacing: 8) {
                ForEach(items, id: \.record.id) { item in
                    Button { detailDate = date; detail = item.exercise } label: {
                        HStack(spacing: 12) {
                            ExerciseIcon(exercise: item.exercise, size: 42, radius: 14, p: p)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.exercise.name).font(.fig(15, .bold)).foregroundColor(p.ink).lineLimit(1)
                                Text(historyMeta(item.record, item.exercise)).font(.fig(12, .medium)).foregroundColor(p.mute)
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2).fill(p.soft)
                                        RoundedRectangle(cornerRadius: 2).fill(p.hgrad)
                                            .frame(width: geo.size.width * min(1, Double(item.record.completedSets) / Double(max(1, item.exercise.totalSets))))
                                    }
                                }
                                .frame(height: 4)
                                .padding(.top, 8)
                            }
                            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(p.mute)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .pulsoCard(p, radius: 18)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 10)
            SoftButton(title: "Borrar historial del día", icon: "trash", height: 42, fontSize: 13,
                       color: p.danger, filled: false, p: p) { confirmDelete = true }
                .padding(.top, 12)
        }
    }

    private func historyMeta(_ r: WorkoutExercise, _ ex: Exercise) -> String {
        let kg = r.setLogs.map(\.weight).max() ?? ex.weight
        return "\(r.completedSets)/\(ex.totalSets) series" + (kg > 0 ? " · \(WorkoutViewModel.kg(kg))" : "")
    }

    // MARK: - Récords y grupos musculares

    private var recordsCard: some View {
        let prs = viewModel.topRecords()
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill").font(.system(size: 14, weight: .semibold)).foregroundColor(p.acc)
                    Text("Récords personales").font(.fig(16, .bold)).foregroundColor(p.ink)
                }
                Spacer()
                Text("TOP 5")
                    .font(.fig(10, .bold)).tracking(0.8).foregroundColor(p.mute)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(p.soft))
            }
            if prs.isEmpty {
                Text("Sin récords aún. Completa series con peso para establecer tus primeras marcas.")
                    .font(.fig(13, .medium)).lineSpacing(3).foregroundColor(p.mute)
                    .padding(.top, 10)
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(prs.enumerated()), id: \.element.exercise.id) { i, pr in
                        Button { detailDate = nil; detail = pr.exercise } label: {
                            HStack(spacing: 12) {
                                Text("\(i + 1)")
                                    .font(.bri(12))
                                    .foregroundColor(i == 0 ? p.onacc : p.mute)
                                    .frame(width: 26, height: 26)
                                    .background(Circle().fill(i == 0 ? AnyShapeStyle(p.grad) : AnyShapeStyle(Color.clear)))
                                    .overlay(Circle().strokeBorder(i == 0 ? .clear : p.line, lineWidth: 1))
                                Text(pr.exercise.name).font(.fig(14, .semibold)).foregroundColor(p.ink).lineLimit(1)
                                Spacer()
                                Text(WorkoutViewModel.kg(pr.weight)).font(.bri(14)).foregroundColor(p.acc)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.soft))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 12)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .pulsoCard(p, radius: 22)
    }

    @ViewBuilder private var muscleCard: some View {
        let groups = viewModel.setsByMuscleGroup()
        if !groups.isEmpty {
            let maxSets = max(1, groups.map(\.sets).max() ?? 1)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 14, weight: .semibold)).foregroundColor(p.acc)
                        Text("Músculos esta semana").font(.fig(16, .bold)).foregroundColor(p.ink)
                    }
                    Spacer()
                    Text(volumeText)
                        .font(.fig(10, .bold)).tracking(0.8).foregroundColor(p.mute)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(p.soft))
                }
                MuscleMapView(sets: Dictionary(uniqueKeysWithValues: groups.map { ($0.group, $0.sets) }), p: p)
                    .padding(.top, 14)
                VStack(spacing: 10) {
                    ForEach(groups, id: \.group) { g in
                        HStack(spacing: 10) {
                            Text(g.group).font(.fig(13, .semibold)).foregroundColor(p.ink)
                                .frame(width: 78, alignment: .leading)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(p.soft)
                                    Capsule().fill(p.hgrad).frame(width: geo.size.width * Double(g.sets) / Double(maxSets))
                                }
                            }
                            .frame(height: 8)
                            Text("\(g.sets)").font(.bri(13)).foregroundColor(p.acc).frame(width: 26, alignment: .trailing)
                        }
                    }
                }
                .padding(.top, 14)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .pulsoCard(p, radius: 22)
        }
    }

    private var volumeText: String {
        let kg = viewModel.weeklyVolume()
        return kg >= 1000
            ? String(format: "%.1f T", kg / 1000).replacingOccurrences(of: ".", with: ",")
            : "\(Int(kg)) KG"
    }
}

/// La línea de peso corporal del prototipo (últimos 10 registros).
private struct WeightSpark: View {
    let values: [Double]
    let p: Palette

    var body: some View {
        GeometryReader { geo in
            let lo = values.min() ?? 0, hi = values.max() ?? 1
            let span = (hi - lo) == 0 ? 1 : hi - lo
            let pts = values.enumerated().map { i, v in
                CGPoint(x: geo.size.width * CGFloat(i) / CGFloat(max(1, values.count - 1)),
                        y: geo.size.height - 4 - CGFloat((v - lo) / span) * (geo.size.height - 8))
            }
            ZStack {
                Path { path in
                    guard let first = pts.first else { return }
                    path.move(to: first)
                    pts.dropFirst().forEach { path.addLine(to: $0) }
                }
                .stroke(p.hgrad, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                if let last = pts.last {
                    Circle().fill(p.acc).frame(width: 7, height: 7).position(last)
                }
            }
        }
    }
}
