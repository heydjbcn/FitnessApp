//
//  ExerciseDetailSheet.swift
//  FitnessApp
//
//  Detalle de ejercicio del rediseño «Pulso»: icono grande, días, técnica,
//  tabla de datos, historial y "Editar ejercicio" — como el prototipo — más lo
//  que la app ya hacía y el prototipo no dibuja: series de hoy con su tipo,
//  peso, reps y RPE, superserie, calculadora de discos y gráfica de progreso.
//

import SwiftUI

struct ExerciseDetailSheet: View {
    let exerciseId: UUID
    var workoutExerciseId: UUID? = nil
    var day: WorkoutDay? = nil
    /// Abrir directamente el editor de las series de esa fecha (desde Historial).
    var focusDate: Date? = nil

    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var showingPlates = false
    @State private var showingEdit = false
    @State private var editingPast: HistoryRef? = nil

    private var p: Palette { themeManager.p }
    private var exercise: Exercise? { viewModel.getExercise(by: exerciseId) }

    private var todayRecord: WorkoutExercise? {
        guard let wid = workoutExerciseId, let d = day else { return nil }
        return viewModel.dailyWorkoutRecords[d]?.first(where: { $0.id == wid })
    }

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)

            if let ex = exercise {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        hero(ex)
                        dataTable(ex).padding(.top, 20)
                        if let s = viewModel.suggestion(for: ex) {
                            SuggestionCard(suggestion: s, p: p).padding(.top, 12)
                        }
                        if ex.segundos == 0 {
                            if ex.loadKind == .total {
                                WarmupCard(work: viewModel.proposedSet(for: ex, record: todayRecord).weight, p: p,
                                           bar: viewModel.activeEquipment.barWeightKg)
                                    .padding(.top, 12)
                            }
                            GoalCard(exercise: ex, p: p).padding(.top, 12)
                        }
                        if let rec = todayRecord { todaySets(rec).padding(.top, 20) }
                        TechniqueCard(name: ex.name, p: p).padding(.top, 12)
                        LibraryCard(exercise: ex, recordId: todayRecord?.id, day: todayRecord == nil ? nil : day, p: p) {
                            dismiss()
                        }
                        .padding(.top, 12)
                        platesButton.padding(.top, 12)
                        progress.padding(.top, 20)
                        history(ex).padding(.top, 20)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 16)
                }
            } else {
                Spacer()
                Text("Ejercicio no disponible").font(.fig(14, .medium)).foregroundColor(p.mute)
                Spacer()
            }
        } footer: {
            if exercise != nil {
                SheetFooter(p: p) {
                    SoftButton(title: "Editar ejercicio", icon: "pencil", height: 50, fontSize: 15, p: p) {
                        showingEdit = true
                    }
                }
            }
        }
        .sheet(item: $editingPast) { ref in
            if let ex = exercise {
                PastSetsEditor(ref: ref, exercise: ex)
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)
            }
        }
        .onAppear {
            if let d = focusDate, editingPast == nil { editingPast = viewModel.historyRef(for: exerciseId, on: d) }
        }
        .sheet(isPresented: $showingPlates) {
            PlateCalculatorView(initialWeight: exercise?.weight ?? 0)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingEdit) {
            if let ex = exercise {
                ExerciseFormSheet(editing: ex, prefillDay: nil)
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)
            }
        }
    }

    // MARK: - Cabecera

    private func hero(_ ex: Exercise) -> some View {
        VStack(spacing: 0) {
            if let data = ex.imageData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 92, height: 92)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(color: p.glow1, radius: 20, y: 16)
            } else {
                IconTile(symbol: ExerciseSymbols.symbol(for: ex), size: 92, radius: 30,
                         gradient: true, glow: true, iconSize: 38, p: p)
            }

            Text((ex.name).loc)
                .font(.bri(24))
                .em(-0.02, size: 24)
                .foregroundColor(p.ink)
                .multilineTextAlignment(.center)
                .padding(.top, 16)

            let days = viewModel.days(for: ex.id)
            if !days.isEmpty {
                HStack(spacing: 5) {
                    ForEach(days) { DayTag(text: $0.shortLabel, p: p) }
                }
                .padding(.top, 10)
            }

            if let note = ex.setupText {
                Label(note, systemImage: "wrench.adjustable")
                    .font(.fig(13, .semibold))
                    .foregroundColor(p.ink)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(Capsule().fill(p.soft))
                    .padding(.top, 12)
            }

            if !ex.info.isEmpty {
                Text((ex.info).loc)
                    .font(.fig(14, .medium))
                    .lineSpacing(5)
                    .foregroundColor(p.mute)
                    .multilineTextAlignment(.center)
                    .padding(.top, 14)
            }

            if let last = viewModel.lastPerformance(for: exerciseId) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath").font(.system(size: 12, weight: .semibold))
                    Text("Última vez: \(WorkoutViewModel.kg(last.weight)) × \(last.reps) reps")
                        .font(.fig(13, .semibold))
                }
                .foregroundColor(p.acc)
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tabla de datos

    private func dataTable(_ ex: Exercise) -> some View {
        var rows: [(String, String)] = [("Series", "\(ex.totalSets)")]
        if ex.segundos > 0 { rows.append(("Segundos", "\(ex.segundos) s")) }
        else if ex.repetitions > 0 { rows.append(("Repeticiones", "\(ex.repetitions)")) }
        if ex.weight > 0 || ex.loadKind == .bodyweight {
            rows.append((ex.loadKind.fieldLabel, WorkoutViewModel.weightText(ex.weight, kind: ex.loadKind)))
        }
        if ex.loadKind != .total { rows.append(("Tipo de carga", ex.loadKind.label)) }
        if ex.rir > 0 { rows.append(("RIR", "\(ex.rir)")) }
        rows.append(("Descanso", WorkoutViewModel.restText(ex.restDuration)))
        if let g = ex.muscleGroup { rows.append(("Grupo muscular", g)) }
        if let pr = viewModel.personalRecord(for: exerciseId), pr.weight > 0 || ex.loadKind.lowerIsBetter {
            let when = viewModel.recordDate(for: exerciseId).map { " · \(Self.shortDate($0))" } ?? ""
            rows.append(("Récord personal", WorkoutViewModel.weightText(pr.weight, kind: ex.loadKind) + when))
            if pr.oneRepMax > 0 {
                rows.append(("1RM estimado", WorkoutViewModel.kg((pr.oneRepMax * 10).rounded() / 10)))
            }
        }

        return VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                HStack {
                    Text((row.0).loc).font(.fig(14, .medium)).foregroundColor(p.mute)
                    Spacer()
                    Text((row.1).loc).font(.bri(15)).foregroundColor(p.ink)
                }
                .padding(.vertical, 11)
                .overlay(alignment: .bottom) {
                    if i < rows.count - 1 { Rectangle().fill(p.line).frame(height: 1) }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(p.line, lineWidth: 1))
    }

    // MARK: - Series de hoy (tipo, peso, reps, RPE) y superserie

    private func todaySets(_ rec: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                UpperLabel(text: "Series de hoy", p: p)
                Spacer()
                Menu {
                    Button("Sin superserie") { setSuperset(nil) }
                    ForEach(0..<4, id: \.self) { g in
                        Button("Bloque \(Self.ssLetter(g))") { setSuperset(g) }
                    }
                } label: {
                    Text(rec.supersetGroup.map { "\(blockKind($0).label) \(Self.ssLetter($0))" } ?? "+ Superserie")
                        .font(.fig(12, .semibold))
                        .foregroundColor(p.acc)
                }
                .accessibilityIdentifier("detail.superset")
            }
            if let g = rec.supersetGroup, let d = day { blockEditor(g, d) }

            if rec.setLogs.isEmpty {
                Text("Aún no has marcado series hoy. Toca las bolitas del ejercicio en Inicio y aquí podrás ajustar peso, repeticiones, tipo de serie y RPE.")
                    .font(.fig(13, .medium))
                    .lineSpacing(3)
                    .foregroundColor(p.mute)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(p.line, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
            } else {
                ForEach(Array(rec.setLogs.enumerated()), id: \.element.id) { idx, log in
                    HStack(spacing: 6) {
                        SetLogRow(index: idx + 1, log: log, p: p) { updated in
                            if let wid = workoutExerciseId, let d = day {
                                viewModel.updateSetLog(updated, for: wid, in: d)
                            }
                        }
                        Button {
                            if let wid = workoutExerciseId, let d = day { viewModel.deleteSetLog(log.id, for: wid, in: d) }
                        } label: {
                            Image(systemName: "trash").font(.system(size: 13, weight: .semibold)).foregroundColor(p.danger)
                                .frame(width: 34, height: 34)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(String(localized: "Borrar la serie \(idx + 1)"))
                    }
                }
            }
        }
    }

    private var platesButton: some View {
        Button { showingPlates = true } label: {
            HStack(spacing: 12) {
                IconTile(symbol: "circle.hexagongrid.fill", size: 38, radius: 12, p: p)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Calculadora de discos").font(.fig(15, .semibold)).foregroundColor(p.ink)
                    Text("Qué discos poner en cada lado de la barra").font(.fig(12, .medium)).foregroundColor(p.mute)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(p.mute)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.soft))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("detail.plates")
    }

    private var progress: some View {
        VStack(alignment: .leading, spacing: 8) {
            UpperLabel(text: "Progreso", p: p)
            ExerciseProgressChart(exerciseId: exerciseId)
        }
    }

    // MARK: - Historial

    private func history(_ ex: Exercise) -> some View {
        let entries = historyEntries(ex)
        return VStack(alignment: .leading, spacing: 8) {
            UpperLabel(text: "Historial", p: p)
            if entries.isEmpty {
                Text("Aún no has realizado este ejercicio.")
                    .font(.fig(13, .medium))
                    .foregroundColor(p.mute)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(p.line, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
            } else {
                ForEach(entries, id: \.date) { e in
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .firstTextBaseline) {
                            Text((WeeklyCalendarView.longDate(e.date)).loc).font(.fig(14, .semibold)).foregroundColor(p.ink)
                            Spacer()
                            Text((e.text).loc).font(.fig(12, .semibold)).foregroundColor(p.mute)
                            Button { editingPast = viewModel.historyRef(for: ex.id, on: e.date) } label: {
                                Image(systemName: "pencil").font(.system(size: 12, weight: .bold)).foregroundColor(p.acc)
                                    .frame(width: 28, height: 28).background(Circle().fill(p.card))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(String(localized: "Corregir las series del \(WeeklyCalendarView.longDate(e.date))"))
                            .accessibilityIdentifier("history.edit.\(MonthGrid.stamp(e.date))")
                        }
                        // Cada serie de ese día: kg × reps, con su tipo y RPE si los tiene.
                        if !e.logs.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(Array(e.logs.enumerated()), id: \.element.id) { _, log in
                                    HStack(spacing: 3) {
                                        if let tag = log.type.shortTag {
                                            Text((tag).loc).font(.fig(9, .bold)).foregroundColor(p.acc)
                                        }
                                        Text((exercise?.segundos ?? 0) > 0 ? "\(log.reps) s" : "\(Units.number(log.weight))×\(log.reps)")
                                            .font(.fig(11, .semibold)).foregroundColor(p.ink)
                                        if let rpe = log.rpe {
                                            Text("@\(rpe)").font(.fig(9, .medium)).foregroundColor(p.mute)
                                        }
                                    }
                                    .padding(.horizontal, 7).padding(.vertical, 4)
                                    .background(Capsule().fill(p.card))
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.top, 8)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(p.card)
                                Capsule().fill(p.hgrad).frame(width: geo.size.width * e.pct)
                            }
                        }
                        .frame(height: 5)
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
                }
            }
        }
    }

    private func historyEntries(_ ex: Exercise) -> [(date: Date, text: String, pct: Double, logs: [SetLog])] {
        viewModel.workoutHistory
            .sorted { $0.key > $1.key }
            .prefix(30)
            .compactMap { date, byDay in
                let recs = byDay.values.flatMap { $0 }.filter { $0.exerciseId == ex.id && $0.completedSets > 0 }
                guard let r = recs.max(by: { $0.completedSets < $1.completedSets }) else { return nil }
                let kg = WorkoutViewModel.best(r.setLogs.map(\.weight), kind: ex.loadKind) ?? 0
                let volume = viewModel.volume(r.setLogs, exerciseId: ex.id)
                var text = String(localized: "\(r.completedSets)/\(r.planned(ex)) series")
                if kg > 0 { text += " · \(ex.loadKind.lowerIsBetter ? "mín" : "máx") \(WorkoutViewModel.weightText(kg, kind: ex.loadKind))" }
                if volume > 0 { text += " · \(Units.tonnage(volume))" }
                return (date, text, min(1, Double(r.completedSets) / Double(max(1, r.planned(ex)))), r.setLogs)
            }
    }

    /// A–Z; el grupo puede venir de una copia o del reloj, así que se acota.
    static func ssLetter(_ g: Int) -> String { String(UnicodeScalar(UInt8(65 + min(25, max(0, g))))) }

    /// "3 jun"
    static func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = AppLanguage.locale
        f.dateFormat = "d MMM"
        return f.string(from: date).replacingOccurrences(of: ".", with: "")
    }

    private func blockKind(_ g: Int) -> BlockKind { day.map { viewModel.block($0, g).kind } ?? .superset }

    /// Qué tipo de bloque es y sus números (descanso por vuelta, minutos).
    private func blockEditor(_ g: Int, _ d: WorkoutDay) -> some View {
        let s = viewModel.block(d, g)
        let set: (BlockSettings) -> Void = { viewModel.setBlock($0, d, g); HapticManager.shared.selectionFeedback() }
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ForEach(BlockKind.allCases) { k in
                    TagChip(text: k.label, selected: s.kind == k, p: p) { var n = s; n.kind = k; set(n) }
                        .accessibilityIdentifier("block.kind.\(k.rawValue)")
                }
            }
            Text((s.kind.detail).loc).font(.fig(12, .medium)).foregroundColor(p.mute).fixedSize(horizontal: false, vertical: true)
            if s.kind == .circuit {
                stepperLine("Descanso entre vueltas", WorkoutViewModel.restText(s.restBetweenRounds),
                            minus: { var n = s; n.restBetweenRounds = max(0, n.restBetweenRounds - 15); set(n) },
                            plus: { var n = s; n.restBetweenRounds = min(600, n.restBetweenRounds + 15); set(n) })
            } else if s.kind.timed {
                stepperLine(s.kind == .amrap ? "Tiempo tope" : "Minutos", String(localized: "\(s.minutes) min"),
                            minus: { var n = s; n.minutes = max(1, n.minutes - 1); set(n) },
                            plus: { var n = s; n.minutes = min(60, n.minutes + 1); set(n) })
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
        .accessibilityIdentifier("detail.block")
    }

    private func stepperLine(_ label: String, _ value: String, minus: @escaping () -> Void, plus: @escaping () -> Void) -> some View {
        HStack {
            Text((label).loc).font(.fig(13, .semibold)).foregroundColor(p.ink)
            Spacer()
            Button(action: minus) { Image(systemName: "minus") }.accessibilityIdentifier("block.minus")
            Text((value).loc).font(.bri(15)).foregroundColor(p.ink).frame(minWidth: 64)
            Button(action: plus) { Image(systemName: "plus") }.accessibilityIdentifier("block.plus")
        }
        .font(.system(size: 14, weight: .bold)).foregroundColor(p.acc)
        .buttonStyle(.plain)
    }

    private func setSuperset(_ g: Int?) {
        if let wid = workoutExerciseId, let d = day {
            viewModel.setSupersetGroup(g, for: wid, in: d)
        }
    }
}

// MARK: - Fila editable de una serie registrada

/// Tipo de serie (menú), peso, repeticiones y RPE de una serie ya hecha.
struct SetLogRow: View {
    let index: Int
    let log: SetLog
    let p: Palette
    let onUpdate: (SetLog) -> Void

    @State private var weight = ""
    @State private var reps = ""
    @State private var type: SetType = .normal
    @State private var rpe = ""

    private func tagColor(_ t: SetType) -> Color {
        switch t {
        case .normal:  return .clear
        case .warmup:  return Color(hex: "#FBBF24")
        case .drop:    return Color(hex: "#60A5FA")
        case .failure: return Pulso.danger(isDark: p.dark)
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(SetType.allCases, id: \.self) { t in
                    Button(t.label.loc) { type = t; commit() }
                }
            } label: {
                Text(type.shortTag ?? "\(index)")
                    .font(.bri(13))
                    .foregroundColor(type == .normal ? p.onacc : .white)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(type == .normal ? AnyShapeStyle(p.grad) : AnyShapeStyle(tagColor(type)))
                    )
            }
            .accessibilityIdentifier("setlog.type.\(index)")
            .accessibilityLabel(String(localized: "Tipo de la serie \(index): \(type.label)"))

            field($weight, suffix: Units.symbol, keyboard: .decimalPad, width: 46)
            Text("×").font(.fig(14, .semibold)).foregroundColor(p.mute)
            field($reps, suffix: "reps", keyboard: .numberPad, width: 30)

            Spacer(minLength: 2)

            HStack(spacing: 4) {
                Text("RPE").font(.fig(10, .bold)).tracking(0.4).foregroundColor(p.mute)
                TextField("–", text: $rpe)
                    .keyboardType(.numberPad)
                    .font(.fig(14, .bold))
                    .foregroundColor(p.ink)
                    .frame(width: 22)
                    .multilineTextAlignment(.center)
                    .onChange(of: rpe) { _, _ in commit() }
            }
            .padding(.horizontal, 10)
            .frame(height: 38)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.card))
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
        .onAppear {
            weight = Units.number(log.weight)
            reps = "\(log.reps)"
            type = log.type
            rpe = log.rpe.map { "\($0)" } ?? ""
        }
    }

    private func field(_ text: Binding<String>, suffix: String, keyboard: UIKeyboardType, width: CGFloat) -> some View {
        HStack(spacing: 4) {
            TextField("0", text: text)
                .keyboardType(keyboard)
                .font(.bri(15))
                .foregroundColor(p.ink)
                .frame(width: width)
                .multilineTextAlignment(.trailing)
                .onChange(of: text.wrappedValue) { _, _ in commit() }
            Text((suffix).loc).font(.fig(11, .medium)).foregroundColor(p.mute)
        }
        .padding(.horizontal, 10)
        .frame(height: 38)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.card))
    }

    private func commit() {
        var updated = log
        // Solo si ha cambiado lo escrito: así abrir en libras no mueve ni un gramo lo guardado.
        if weight != Units.number(log.weight), let w = Units.parse(weight) { updated.weight = w }
        if let r = Int(reps) { updated.reps = r }
        updated.type = type
        updated.rpe = Int(rpe)
        onUpdate(updated)
    }
}
