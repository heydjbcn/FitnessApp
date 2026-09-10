//
//  WeeklyCalendarView.swift
//  FitnessApp
//
//  Calendario del rediseño «Pulso». Es la pantalla de PLANIFICAR: cada día de
//  la semana en una tarjeta plegable con su nombre de sesión, sus ejercicios y
//  "Entrenar este día". Las series se marcan en Inicio. En modo Mes, la
//  rejilla del mes y lo que se hizo (o toca) el día elegido.
//

import SwiftUI

struct WeeklyCalendarView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager

    /// "Entrenar este día": lleva a Inicio con ese día seleccionado.
    var onTrain: (WorkoutDay) -> Void = { _ in }

    @State private var mode = 0                       // 0 Semana · 1 Mes
    @State private var expanded: WorkoutDay? = getCurrentDay()
    @State private var editingLabel: WorkoutDay? = nil
    @State private var labelInput = ""
    @State private var month = Date()
    @State private var selectedDate = Date()
    @State private var detail: DetailTarget? = nil
    @State private var formDay: HomeView.FormTarget? = nil
    @State private var reordering: WorkoutDay? = nil
    @State private var namingNew = false
    @State private var renaming = false
    @State private var routineName = ""
    @State private var routineToDelete: Routine? = nil

    // MARK: - Rutinas guardadas

    /// "Rutina: Fuerza ▾" — cambiar, crear, renombrar o eliminar rutinas.
    private var routineRow: some View {
        let saved = viewModel.savedRoutines
        return Menu {
            Section("Rutinas") {
                Label(viewModel.activeRoutineName, systemImage: "checkmark").disabled(true)
                ForEach(saved) { r in
                    Button { viewModel.activate(r) } label: {
                        Label("\(r.name) · \(r.summary)", systemImage: "arrow.right.circle")
                    }
                }
            }
            Section {
                Button { routineName = ""; namingNew = true } label: { Label("Nueva rutina…", systemImage: "plus") }
                Button { routineName = viewModel.activeRoutineName; renaming = true } label: { Label("Renombrar la actual…", systemImage: "pencil") }
            }
            if !saved.isEmpty {
                Section("Eliminar") {
                    ForEach(saved) { r in
                        Button(role: .destructive) { routineToDelete = r } label: { Label(r.name, systemImage: "trash") }
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                IconTile(symbol: "list.bullet.rectangle.portrait", size: 34, radius: 11, p: p)
                VStack(alignment: .leading, spacing: 1) {
                    UpperLabel(text: "Rutina activa", p: p)
                    Text(viewModel.activeRoutineName).font(.fig(15, .bold)).foregroundColor(p.ink).lineLimit(1)
                }
                Spacer()
                if !saved.isEmpty {
                    Text("+\(saved.count)").font(.fig(11, .bold)).foregroundColor(p.acc)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(p.soft))
                }
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 12, weight: .semibold)).foregroundColor(p.mute)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .pulsoCard(p, radius: 18)
            .padding(.top, 10)
        }
        .buttonStyle(.plain)
    }

    private var p: Palette { themeManager.p }
    private var today: WorkoutDay { Self.getCurrentDay() }

    /// El día de entrenamiento de hoy.
    static func getCurrentDay() -> WorkoutDay {
        WorkoutDay.from(date: Date()) ?? .monday
    }

    var body: some View {
        ZStack(alignment: .top) {
            PulsoBackground(p: p)
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeader(title: "Calendario", size: 26,
                             subtitle: "Tu semana de entrenamiento · toca un día para ver su sesión", p: p) {
                    PulsoSegmented(options: ["Semana", "Mes"], selection: $mode, p: p)
                }
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if mode == 0 {
                            routineRow
                            weekList
                        } else {
                            monthView
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 120)
                }
                .padding(.top, 10)
            }
        }
        .onAppear { viewModel.updateTimerEnabledState(themeManager.isTimerEnabled) }
        .alert("Nueva rutina", isPresented: $namingNew) {
            TextField("Nombre (Fuerza, Hipertrofia…)", text: $routineName)
            Button("Vacía") { viewModel.createRoutine(named: routineName, copyingCurrent: false) }
            Button("Copiar la actual") { viewModel.createRoutine(named: routineName, copyingCurrent: true) }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("La rutina de ahora se guarda con su nombre y la nueva pasa a ser la activa.")
        }
        .alert("Renombrar rutina", isPresented: $renaming) {
            TextField("Nombre", text: $routineName)
            Button("Guardar") { viewModel.renameActiveRoutine(routineName) }
            Button("Cancelar", role: .cancel) {}
        }
        .confirmationDialog("¿Eliminar «\(routineToDelete?.name ?? "")»?", isPresented: Binding(get: { routineToDelete != nil },
                                                                                            set: { if !$0 { routineToDelete = nil } }),
                            titleVisibility: .visible) {
            Button("Eliminar rutina", role: .destructive) {
                if let r = routineToDelete { viewModel.deleteRoutine(r) }
                routineToDelete = nil
            }
        }
        .sheet(item: $detail) { target in
            ExerciseDetailSheet(exerciseId: target.exerciseId,
                                workoutExerciseId: target.workoutExerciseId,
                                day: target.day)
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
        .sheet(item: $formDay) { target in
            ExerciseFormSheet(editing: nil, prefillDay: target.day)
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
    }

    struct DetailTarget: Identifiable {
        let exerciseId: UUID
        let workoutExerciseId: UUID?
        let day: WorkoutDay?
        var id: String { "\(exerciseId)-\(workoutExerciseId?.uuidString ?? "")" }
    }

    // MARK: - Semana

    private var weekList: some View {
        VStack(spacing: 0) {
            ForEach(WorkoutDay.allCases.sorted { $0.weekOrder < $1.weekOrder }) { day in
                dayCard(day).padding(.top, 10)
            }
        }
    }

    private func dayCard(_ day: WorkoutDay) -> some View {
        let records = viewModel.dailyWorkoutRecords[day] ?? []
        let total = viewModel.totalSets(for: day)
        let done = viewModel.completedSets(for: day)
        let isOpen = expanded == day

        return VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    expanded = isOpen ? nil : day
                    editingLabel = nil
                }
                HapticManager.shared.selectionFeedback()
            } label: {
                HStack(spacing: 12) {
                    dayBadge(day)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(day.displayName)
                                .font(.fig(16, .bold))
                                .foregroundColor(p.ink)
                            if let label = viewModel.label(for: day) {
                                Text(label)
                                    .font(.fig(13, .medium))
                                    .foregroundColor(p.acc)
                                    .lineLimit(1)
                            }
                        }
                        Text(records.isEmpty
                             ? "Día libre · sin ejercicios"
                             : "\(records.count) ejercicios · \(total) series · ~\(total * 3) min")
                            .font(.fig(13, .medium))
                            .foregroundColor(p.mute)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(p.mute)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if done > 0 && total > 0 {
                HStack(spacing: 10) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(p.soft)
                            Capsule().fill(p.hgrad).frame(width: geo.size.width * Double(done) / Double(total))
                        }
                    }
                    .frame(height: 6)
                    Text("\(Int((Double(done) / Double(total) * 100).rounded()))%")
                        .font(.fig(12, .bold))
                        .foregroundColor(p.acc)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            if isOpen { expandedContent(day, records: records) }
        }
        .pulsoCard(p, radius: 22)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    /// Cuadro de 46 de la izquierda: hoy en degradado, completado con ✓, el resto gris.
    @ViewBuilder private func dayBadge(_ day: WorkoutDay) -> some View {
        if day == today {
            Text(day.shortLabel)
                .font(.bri(13))
                .foregroundColor(p.onacc)
                .frame(width: 46, height: 46)
                .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(p.grad))
                .shadow(color: p.glow1, radius: 8, y: 6)
        } else if viewModel.isDayComplete(day) {
            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(p.acc)
                .frame(width: 46, height: 46)
                .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(p.soft))
        } else {
            Text(day.shortLabel)
                .font(.bri(13))
                .foregroundColor(p.mute)
                .frame(width: 46, height: 46)
                .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(p.soft))
        }
    }

    private func expandedContent(_ day: WorkoutDay, records: [WorkoutExercise]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if editingLabel == day {
                HStack(spacing: 8) {
                    TextField("", text: $labelInput,
                              prompt: Text("Ej. Pecho y tríceps").foregroundColor(p.mute.opacity(0.8)))
                        .font(.fig(14, .medium))
                        .foregroundColor(p.ink)
                        .padding(.horizontal, 12)
                        .frame(height: 40)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.soft))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(p.line, lineWidth: 1))
                        .submitLabel(.done)
                        .onSubmit { saveLabel(day) }
                    Button { saveLabel(day) } label: {
                        Text("Guardar").font(.fig(13, .bold)).foregroundColor(p.onacc)
                            .padding(.horizontal, 14).frame(height: 40)
                            .background(Capsule().fill(p.hgrad))
                    }
                    .buttonStyle(.plain)
                    Button { editingLabel = nil } label: {
                        Text("Cancelar").font(.fig(13, .semibold)).foregroundColor(p.mute)
                            .padding(.horizontal, 12).frame(height: 40)
                            .overlay(Capsule().strokeBorder(p.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack {
                    UpperLabel(text: "Nombre del día", p: p)
                    Spacer()
                    Button {
                        labelInput = viewModel.label(for: day) ?? ""
                        editingLabel = day
                    } label: {
                        Text(viewModel.label(for: day) == nil ? "Añadir nombre" : "Renombrar")
                            .font(.fig(12, .semibold))
                            .foregroundColor(p.acc)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }

            if !records.isEmpty {
                let isReordering = reordering == day
                VStack(spacing: 6) {
                    ForEach(Array(records.enumerated()), id: \.element.id) { i, record in
                        if let exercise = viewModel.getExercise(by: record.exerciseId) {
                            HStack(spacing: 6) {
                                ExerciseListRow(exercise: exercise, meta: viewModel.meta(for: exercise), p: p) {
                                    if !isReordering {
                                        detail = DetailTarget(exerciseId: exercise.id, workoutExerciseId: record.id, day: day)
                                    }
                                }
                                if isReordering {
                                    VStack(spacing: 4) {
                                        arrow("chevron.up", enabled: i > 0) { viewModel.moveExercise(in: day, from: i, to: i - 1) }
                                        arrow("chevron.down", enabled: i < records.count - 1) { viewModel.moveExercise(in: day, from: i, to: i + 1) }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.top, 12)
                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: records.map(\.id))

                if records.count > 1 {
                    Button {
                        withAnimation { reordering = isReordering ? nil : day }
                        HapticManager.shared.buttonTapped()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isReordering ? "checkmark" : "arrow.up.arrow.down").font(.system(size: 11, weight: .bold))
                            Text(isReordering ? "Listo" : "Reordenar").font(.fig(12, .semibold))
                        }
                        .foregroundColor(isReordering ? p.onacc : p.acc)
                        .padding(.horizontal, 12).frame(height: 30)
                        .background(Capsule().fill(isReordering ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(p.soft)))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                }
            }

            HStack(spacing: 8) {
                if !records.isEmpty {
                    PrimaryButton(title: "Entrenar este día", height: 44, fontSize: 14, p: p) {
                        HapticManager.shared.buttonTapped()
                        onTrain(day)
                    }
                }
                SoftButton(title: "+ Añadir ejercicio", height: 44, p: p) {
                    formDay = HomeView.FormTarget(day: day)
                }
            }
            .padding(.top, 14)

            // Duplicar la sesión en otro día: función de la app que el prototipo no dibuja.
            if !records.isEmpty {
                Menu {
                    ForEach(WorkoutDay.allCases.sorted { $0.weekOrder < $1.weekOrder }.filter { $0 != day }) { d in
                        Button("Copiar al \(d.displayName.lowercased())") {
                            viewModel.duplicateRoutine(from: day, to: d)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc").font(.system(size: 12, weight: .semibold))
                        Text("Duplicar este día en otro").font(.fig(12, .semibold))
                    }
                    .foregroundColor(p.mute)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .overlay(alignment: .top) { Rectangle().fill(p.line).frame(height: 1) }
    }

    private func arrow(_ symbol: String, enabled: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(p.ink)
                .frame(width: 30, height: 26)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(p.soft))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.3)
    }

    private func saveLabel(_ day: WorkoutDay) {
        viewModel.setLabel(labelInput, for: day)
        editingLabel = nil
        HapticManager.shared.success()
    }

    // MARK: - Mes

    private var monthView: some View {
        VStack(spacing: 0) {
            MonthGrid(month: $month, selected: $selectedDate,
                      hasWorkout: { viewModel.hasWorkoutForDate($0) }, p: p)
                .padding(.top, 10)
            selectedDateCard.padding(.top, 10)
        }
    }

    private var selectedDateCard: some View {
        let items = viewModel.historyItems(for: selectedDate)
        let weekday = WorkoutDay.from(date: selectedDate)
        let planned = weekday.map { viewModel.dailyWorkoutRecords[$0] ?? [] } ?? []
        let sub: String
        if let first = items.first {
            let sets = items.reduce(0) { $0 + $1.record.completedSets }
            sub = first.day == weekday ? "Entrenamiento · \(sets) series" : "Hiciste la rutina del \(first.day.displayName.lowercased())"
        } else if !planned.isEmpty, let weekday {
            sub = "Rutina del \(weekday.displayName.lowercased()) · \(planned.count) ejercicios"
        } else {
            sub = "Día libre · sin ejercicios"
        }

        return VStack(alignment: .leading, spacing: 0) {
            Text(Self.longDate(selectedDate))
                .font(.fig(16, .bold))
                .foregroundColor(p.ink)
            Text(sub)
                .font(.fig(13, .medium))
                .foregroundColor(p.mute)
                .padding(.top, 3)

            VStack(spacing: 6) {
                if !items.isEmpty {
                    ForEach(items, id: \.record.id) { item in
                        ExerciseListRow(exercise: item.exercise,
                                        meta: "\(item.record.completedSets)/\(item.exercise.totalSets) series · \(viewModel.meta(for: item.exercise))",
                                        p: p) {
                            detail = DetailTarget(exerciseId: item.exercise.id, workoutExerciseId: nil, day: nil)
                        }
                    }
                } else if let weekday {
                    ForEach(planned) { record in
                        if let exercise = viewModel.getExercise(by: record.exerciseId) {
                            ExerciseListRow(exercise: exercise, meta: viewModel.meta(for: exercise), p: p) {
                                detail = DetailTarget(exerciseId: exercise.id, workoutExerciseId: record.id, day: weekday)
                            }
                        }
                    }
                    if planned.isEmpty {
                        SoftButton(title: "+ Añadir ejercicio al \(weekday.displayName.lowercased())",
                                   height: 44, p: p) {
                            formDay = HomeView.FormTarget(day: weekday)
                        }
                    }
                }
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pulsoCard(p, radius: 22)
    }

    /// "Jueves, 10 de septiembre"
    static func longDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEEE, d 'de' MMMM"
        let s = f.string(from: date)
        return s.prefix(1).uppercased() + s.dropFirst()
    }
}
