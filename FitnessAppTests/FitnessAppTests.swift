//
//  FitnessAppTests.swift
//  ChamaFit
//
//  Pruebas del modelo (WorkoutViewModel y compañía) sobre un dominio de
//  UserDefaults propio por caso: nunca tocan los datos reales del iPhone.
//  Corren hospedadas en la app, en el dispositivo (`scripts/test-on-iphone.sh`).
//

import Testing
import Foundation
@testable import FitnessApp

/// Ancla para localizar los fixtures del bundle de pruebas.
final class FixtureAnchor {}

@MainActor
struct TestBox {
    let vm: WorkoutViewModel
    let defaults: UserDefaults
    let suite: String

    init(seed: ((UserDefaults) -> Void)? = nil) {
        suite = "Mauri.FitnessApp.unittests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        seed?(defaults)
        vm = WorkoutViewModel(defaults: defaults)
    }

    func tearDown() { defaults.removePersistentDomain(forName: suite) }

    /// Un ejercicio en la biblioteca y en el plan del día indicado.
    @discardableResult
    func add(_ name: String, sets: Int = 3, weight: Double = 40, reps: Int = 10, rest: Int = 90,
             on day: WorkoutDay, group: String? = nil) -> (Exercise, WorkoutExercise) {
        let ex = Exercise(name: name, repetitions: reps, weight: weight, totalSets: sets,
                          restDuration: rest, muscleGroup: group)
        vm.createExercise(ex, days: [day])
        let rec = vm.dailyWorkoutRecords[day]!.first { $0.exerciseId == ex.id }!
        return (ex, rec)
    }

    static var today: Date { Calendar.current.startOfDay(for: Date()) }
    static func daysAgo(_ n: Int) -> Date { Calendar.current.date(byAdding: .day, value: -n, to: today)! }
}

// MARK: - Sesión por fecha

@Suite(.serialized) @MainActor
struct SessionTests {

    @Test func markingASetLandsInTodayHistory() {
        let box = TestBox(); defer { box.tearDown() }
        let (_, rec) = box.add("Press", on: .monday)
        box.vm.completeSet(for: rec.id, in: .monday)
        #expect(box.vm.dailyWorkoutRecords[.monday]?.first?.completedSets == 1)
        #expect(box.vm.workoutHistory[TestBox.today]?[.monday]?.first?.setLogs.count == 1)
        #expect(box.vm.hasWorkoutForDate(Date()))
    }

    @Test func newDayArchivesAndResetsTemplate() {
        let box = TestBox(); defer { box.tearDown() }
        let (_, rec) = box.add("Press", on: .monday)
        box.vm.completeSet(for: rec.id, in: .monday)
        box.vm.completeSet(for: rec.id, in: .monday)
        // La sesión era de ayer: al comprobar, se archiva bajo ayer y hoy empieza a cero.
        box.vm.adoptSession(date: TestBox.daysAgo(1))
        // Lo que había en el historial de hoy pasa a ayer (mirror bajo sessionDate).
        box.vm.workoutHistory.removeValue(forKey: TestBox.today)
        box.vm.ensureSession()
        #expect(box.vm.sessionDate == TestBox.today)
        #expect(box.vm.dailyWorkoutRecords[.monday]?.first?.completedSets == 0)
        #expect(box.vm.workoutHistory[TestBox.daysAgo(1)]?[.monday]?.first?.completedSets == 2)
        #expect(box.vm.workoutHistory[TestBox.today] == nil)
    }

    @Test func clockMovedBackwardsStillArchives() {
        let box = TestBox(); defer { box.tearDown() }
        let (_, rec) = box.add("Press", on: .monday)
        box.vm.completeSet(for: rec.id, in: .monday)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: TestBox.today)!
        box.vm.adoptSession(date: tomorrow)
        box.vm.ensureSession()
        #expect(box.vm.sessionDate == TestBox.today)
        #expect(box.vm.dailyWorkoutRecords[.monday]?.first?.completedSets == 0)
        #expect(box.vm.workoutHistory[tomorrow]?[.monday] != nil)
    }

    @Test func sessionDatePersistsAcrossLaunch() {
        let box = TestBox()
        defer { box.tearDown() }
        box.vm.adoptSession(date: TestBox.daysAgo(3))
        let again = WorkoutViewModel(defaults: box.defaults)
        // Al cargar con una fecha antigua, ensureSession la trae a hoy.
        #expect(again.sessionDate == TestBox.today)
        #expect(box.defaults.object(forKey: "LastSessionDate") as? Date == TestBox.today)
    }

    @Test func firstLaunchWithoutSessionDateResetsProgress() {
        let box = TestBox(seed: { d in
            let ex = Exercise(name: "Viejo", repetitions: 8, weight: 20)
            let rec = WorkoutExercise(exerciseId: ex.id, completedSets: 2)
            d.set(try! JSONEncoder().encode([ex]), forKey: "AvailableExercises")
            d.set(try! JSONEncoder().encode([WorkoutDay.monday: [rec]]), forKey: "DailyWorkoutRecords")
        })
        defer { box.tearDown() }
        #expect(box.vm.availableExercises.count == 1)
        #expect(box.vm.dailyWorkoutRecords[.monday]?.first?.completedSets == 0)
        #expect(box.vm.dailyWorkoutRecords[.sunday] != nil)
    }
}

// MARK: - Series, deshacer, edición, superseries, récords

@Suite(.serialized) @MainActor
struct SetTests {

    @Test func completeUndoUpdate() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, rec) = box.add("Sentadilla", sets: 3, weight: 60, reps: 8, on: .monday)
        box.vm.completeSet(for: rec.id, in: .monday)
        box.vm.completeSet(for: rec.id, in: .monday, weight: 70, reps: 6, type: .failure, rpe: 9)
        var r = box.vm.dailyWorkoutRecords[.monday]!.first!
        #expect(r.completedSets == 2)
        #expect(r.setLogs.count == 2)
        #expect(r.setLogs[0].weight == 60 && r.setLogs[0].reps == 8)
        #expect(r.setLogs[1].weight == 70 && r.setLogs[1].type == .failure && r.setLogs[1].rpe == 9)
        // Más allá del total no se marca.
        box.vm.completeSet(for: rec.id, in: .monday)
        box.vm.completeSet(for: rec.id, in: .monday)
        #expect(box.vm.dailyWorkoutRecords[.monday]!.first!.completedSets == 3)
        // Editar la primera serie.
        var log = box.vm.dailyWorkoutRecords[.monday]!.first!.setLogs[0]
        log.weight = 65; log.rpe = 7
        box.vm.updateSetLog(log, for: rec.id, in: .monday)
        r = box.vm.dailyWorkoutRecords[.monday]!.first!
        #expect(r.setLogs[0].weight == 65 && r.setLogs[0].rpe == 7)
        // Deshacer tres veces y una de más.
        box.vm.undoLastSet(for: rec.id, in: .monday)
        box.vm.undoLastSet(for: rec.id, in: .monday)
        box.vm.undoLastSet(for: rec.id, in: .monday)
        box.vm.undoLastSet(for: rec.id, in: .monday)
        r = box.vm.dailyWorkoutRecords[.monday]!.first!
        #expect(r.completedSets == 0 && r.setLogs.isEmpty && r.lastSetCompletedAt == nil)
        #expect(box.vm.workoutHistory[TestBox.today] == nil, "sin series no queda rastro en el historial")
        #expect(box.vm.getExercise(by: ex.id) != nil)
    }

    @Test func undoStopsRestAndCelebration() {
        let box = TestBox(); defer { box.tearDown() }
        let (_, rec) = box.add("Press", sets: 3, weight: 50, on: .monday)
        box.vm.completeSet(for: rec.id, in: .monday)
        #expect(box.vm.timerActive)
        #expect(box.vm.prCelebration != nil, "la primera marca se celebra")
        box.vm.undoLastSet(for: rec.id, in: .monday)
        #expect(!box.vm.timerActive)
        #expect(box.vm.prCelebration == nil)
    }

    @Test func undoWithLegacyCounterOnly() {
        let box = TestBox(); defer { box.tearDown() }
        let ex = Exercise(name: "Viejo", repetitions: 8, weight: 20)
        box.vm.availableExercises.append(ex)
        let rec = WorkoutExercise(exerciseId: ex.id, completedSets: 2)
        box.vm.dailyWorkoutRecords[.monday] = [rec]
        box.vm.undoLastSet(for: rec.id, in: .monday)
        #expect(box.vm.dailyWorkoutRecords[.monday]?.first?.completedSets == 1)
    }

    @Test func lastPerformanceIgnoresWarmupAndDrop() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, rec) = box.add("Press", sets: 4, weight: 50, on: .monday)
        box.vm.completeSet(for: rec.id, in: .monday, weight: 20, reps: 15, type: .warmup)
        box.vm.completeSet(for: rec.id, in: .monday, weight: 60, reps: 8)
        box.vm.completeSet(for: rec.id, in: .monday, weight: 40, reps: 12, type: .drop)
        #expect(box.vm.lastPerformance(for: ex.id)?.weight == 60)
        // La siguiente serie sin datos hereda la última de trabajo.
        box.vm.completeSet(for: rec.id, in: .monday)
        #expect(box.vm.dailyWorkoutRecords[.monday]!.first!.setLogs.last!.weight == 60)
    }

    @Test func recordsCelebrateFirstAndBetterOnly() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, rec) = box.add("Press", sets: 5, weight: 50, on: .monday)
        box.vm.completeSet(for: rec.id, in: .monday, weight: 50, reps: 8)
        #expect(box.vm.prCelebration?.contains("Primera marca") == true)
        box.vm.prCelebration = nil
        box.vm.completeSet(for: rec.id, in: .monday, weight: 50, reps: 8)
        #expect(box.vm.prCelebration == nil, "el mismo peso no es récord")
        box.vm.completeSet(for: rec.id, in: .monday, weight: 55, reps: 5)
        #expect(box.vm.prCelebration?.contains("Nuevo récord") == true)
        #expect(box.vm.personalRecord(for: ex.id)?.weight == 55)
        #expect(box.vm.bestWeight(for: ex.id) == 55)
        #expect(box.vm.recordDate(for: ex.id) != nil)
        #expect(box.vm.notifications.filter { $0.kind == .achievement }.count == 2)
        // Un peso 0 (peso corporal) nunca es récord.
        box.vm.prCelebration = nil
        box.vm.completeSet(for: rec.id, in: .monday, weight: 0, reps: 12)
        #expect(box.vm.prCelebration == nil)
    }

    @Test func supersetRestOnlyWhenRoundCloses() {
        let box = TestBox(); defer { box.tearDown() }
        let (_, a) = box.add("A", sets: 3, on: .monday)
        let (_, b) = box.add("B", sets: 2, on: .monday)
        box.vm.setSupersetGroup(0, for: a.id, in: .monday)
        box.vm.setSupersetGroup(0, for: b.id, in: .monday)
        box.vm.completeSet(for: a.id, in: .monday)
        #expect(!box.vm.timerActive, "B va por detrás: sin descanso")
        #expect(box.vm.timerLabel.contains("Ahora B"))
        box.vm.completeSet(for: b.id, in: .monday)
        #expect(box.vm.timerActive, "vuelta cerrada: descanso")
        box.vm.stopTimer(silent: true)
        box.vm.completeSet(for: a.id, in: .monday)
        #expect(!box.vm.timerActive)
        box.vm.completeSet(for: b.id, in: .monday)   // B completo (2/2)
        #expect(box.vm.timerActive)
        box.vm.stopTimer(silent: true)
        // B ya está completo: A no debe esperarle.
        box.vm.completeSet(for: a.id, in: .monday)   // A 3/3: completo, sin descanso porque terminó
        #expect(!box.vm.timerActive)
        #expect(box.vm.isDayComplete(.monday))
    }

    @Test func supersetPartnerCompleteDoesNotBlockRest() {
        let box = TestBox(); defer { box.tearDown() }
        let (_, a) = box.add("A", sets: 4, on: .monday)
        let (_, b) = box.add("B", sets: 1, on: .monday)
        box.vm.setSupersetGroup(1, for: a.id, in: .monday)
        box.vm.setSupersetGroup(1, for: b.id, in: .monday)
        box.vm.completeSet(for: b.id, in: .monday)   // B completo de una
        box.vm.stopTimer(silent: true)
        box.vm.completeSet(for: a.id, in: .monday)   // A 1/4, B no puede ir "por detrás"
        #expect(box.vm.timerActive)
        box.vm.stopTimer(silent: true)
        box.vm.completeSet(for: a.id, in: .monday)   // A 2/4
        #expect(box.vm.timerActive)
    }

    @Test func removingExerciseKeepsHistory() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, rec) = box.add("Press", on: .monday)
        box.vm.completeSet(for: rec.id, in: .monday)
        box.vm.removeExercise(baseExercise: ex)
        #expect(box.vm.getExercise(by: ex.id) == nil)
        #expect(box.vm.dailyWorkoutRecords[.monday]?.isEmpty == true)
        #expect(box.vm.workoutHistory[TestBox.today]?[.monday]?.first?.exerciseId == ex.id)
        #expect(box.vm.exportCSV().contains("Ejercicio borrado"))
        #expect(box.vm.historyItems(for: Date()).isEmpty, "sin ejercicio base no se lista")
    }

    @Test func daysAndDuplicate() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, rec) = box.add("Press", on: .monday)
        box.vm.completeSet(for: rec.id, in: .monday)
        box.vm.setDays([.monday, .friday], for: ex.id)
        #expect(Set(box.vm.days(for: ex.id)) == [.monday, .friday])
        #expect(box.vm.dailyWorkoutRecords[.monday]?.first?.completedSets == 1, "quitar/poner días no toca el progreso")
        box.vm.setDays([.friday], for: ex.id)
        #expect(box.vm.days(for: ex.id) == [.friday])
        box.vm.duplicateRoutine(from: .friday, to: .sunday)
        #expect(box.vm.dailyWorkoutRecords[.sunday]?.count == 1)
        #expect(box.vm.dailyWorkoutRecords[.sunday]?.first?.completedSets == 0)
    }
}

// MARK: - Estadísticas

@Suite(.serialized) @MainActor
struct StatsTests {

    /// Deja `count` series de `weight` kg del ejercicio bajo la fecha dada.
    func seed(_ box: TestBox, _ ex: Exercise, on date: Date, day: WorkoutDay, count: Int, weight: Double, reps: Int = 10) {
        var rec = WorkoutExercise(exerciseId: ex.id)
        for i in 0..<count {
            rec.setLogs.append(SetLog(reps: reps, weight: weight, date: date.addingTimeInterval(Double(i) * 200)))
        }
        rec.completedSets = count
        var byDay = box.vm.workoutHistory[date] ?? [:]
        byDay[day] = (byDay[day] ?? []) + [rec]
        box.vm.workoutHistory[date] = byDay
    }

    @Test func weekStatsAndComparison() {
        let box = TestBox(); defer { box.tearDown() }
        let ex = Exercise(name: "Press", repetitions: 10, weight: 40, muscleGroup: "Pecho")
        box.vm.availableExercises = [ex]
        let thisWeek = box.vm.weekInterval()
        let lastWeek = box.vm.weekInterval(offset: -1)
        seed(box, ex, on: thisWeek.start, day: .monday, count: 3, weight: 50)
        seed(box, ex, on: lastWeek.start, day: .monday, count: 4, weight: 40)
        seed(box, ex, on: lastWeek.start.addingTimeInterval(2 * 86_400), day: .wednesday, count: 2, weight: 40)
        let now = box.vm.weekStats()
        let prev = box.vm.weekStats(offset: -1)
        #expect(now.sessions == 1 && now.sets == 3 && now.volume == 1500 && now.minutes == 9)
        #expect(prev.sessions == 2 && prev.sets == 6 && prev.volume == 2400)
        #expect(box.vm.weeklyVolume() == 1500)
        #expect(box.vm.weeklyTrainedMinutes() == 9)
        #expect(box.vm.setsByMuscleGroup().first?.group == "Pecho")
        #expect(box.vm.setsByMuscleGroup().first?.sets == 3)
        #expect(box.vm.bestWorkoutDay()?.day == .monday)
        #expect(box.vm.bestWorkoutDay()?.pct == 0.75)
    }

    @Test func weekIntervalStartsOnMonday() {
        let box = TestBox(); defer { box.tearDown() }
        var cal = Calendar(identifier: .gregorian); cal.firstWeekday = 2
        let w = box.vm.weekInterval()
        #expect(cal.component(.weekday, from: w.start) == 2)
        #expect(w.contains(Date()))
        #expect(box.vm.weekInterval(offset: -1).end == w.start)
    }

    @Test func streakSkipsRestDaysAndBreaksOnMissedDay() {
        let box = TestBox(); defer { box.tearDown() }
        // Rutina: todos los días tienen ejercicio (así un día sin series rompe la racha).
        let ex = Exercise(name: "Press", repetitions: 10, weight: 40)
        box.vm.availableExercises = [ex]
        for d in WorkoutDay.allCases { box.vm.dailyWorkoutRecords[d] = [WorkoutExercise(exerciseId: ex.id)] }
        for back in 1...3 {
            let date = TestBox.daysAgo(back)
            seed(box, ex, on: date, day: WorkoutDay.from(date: date)!, count: 1, weight: 40)
        }
        #expect(box.vm.consecutiveWorkoutDays() == 3, "hoy sin series aún no rompe")
        // Hace 4 días no se entrenó: la racha para ahí.
        let date = TestBox.daysAgo(5)
        seed(box, ex, on: date, day: WorkoutDay.from(date: date)!, count: 1, weight: 40)
        #expect(box.vm.consecutiveWorkoutDays() == 3)
        // Con un día de descanso en medio (sin rutina) la racha sigue.
        box.vm.dailyWorkoutRecords[WorkoutDay.from(date: TestBox.daysAgo(4))!] = []
        #expect(box.vm.consecutiveWorkoutDays() == 4)
        // Sin ningún historial: cero.
        box.vm.workoutHistory = [:]
        #expect(box.vm.consecutiveWorkoutDays() == 0)
    }

    @Test func chartSeriesWithZeroOneAndManySessions() {
        let box = TestBox(); defer { box.tearDown() }
        let ex = Exercise(name: "Press", repetitions: 10, weight: 40)
        box.vm.availableExercises = [ex]
        #expect(box.vm.exerciseDailyMaxWeight(for: ex.id).isEmpty)
        #expect(box.vm.exerciseDailyVolume(for: ex.id).isEmpty)
        #expect(box.vm.exerciseDailyOneRepMax(for: ex.id).isEmpty)
        #expect(box.vm.personalRecord(for: ex.id) == nil)
        seed(box, ex, on: TestBox.daysAgo(7), day: .monday, count: 2, weight: 40)
        #expect(box.vm.exerciseDailyMaxWeight(for: ex.id).count == 1)
        seed(box, ex, on: TestBox.daysAgo(3), day: .friday, count: 3, weight: 45, reps: 8)
        seed(box, ex, on: TestBox.daysAgo(3), day: .friday, count: 1, weight: 30)
        let max = box.vm.exerciseDailyMaxWeight(for: ex.id)
        #expect(max.count == 2 && max.last?.weight == 45 && max.first?.date == TestBox.daysAgo(7))
        let vol = box.vm.exerciseDailyVolume(for: ex.id)
        #expect(abs((vol.last?.volume ?? 0) - 1380) < 0.001)
        let orm = box.vm.exerciseDailyOneRepMax(for: ex.id)
        #expect(orm.last!.oneRepMax > 45 && orm.last!.oneRepMax < 60)
        // Peso corporal (0 kg) no entra en ninguna gráfica.
        seed(box, ex, on: TestBox.daysAgo(1), day: .wednesday, count: 3, weight: 0)
        #expect(box.vm.exerciseDailyVolume(for: ex.id).count == 2)
        #expect(box.vm.topRecords().first?.weight == 45)
    }

    @Test func setLogIndexInvalidatesOnHistoryChange() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, rec) = box.add("Press", sets: 5, weight: 40, on: .monday)
        #expect(box.vm.allSetLogs(for: ex.id).isEmpty)
        box.vm.completeSet(for: rec.id, in: .monday)
        #expect(box.vm.allSetLogs(for: ex.id).count == 1)
        box.vm.completeSet(for: rec.id, in: .monday)
        #expect(box.vm.allSetLogs(for: ex.id).count == 2)
        box.vm.deleteHistory(for: Date())
        #expect(box.vm.allSetLogs(for: ex.id).isEmpty)
        #expect(box.vm.dailyWorkoutRecords[.monday]?.first?.completedSets == 0, "borrar el historial de hoy deja la sesión a cero")
    }

    @Test func bodyWeightAndNotes() {
        let box = TestBox(); defer { box.tearDown() }
        box.vm.updateBodyWeight(for: TestBox.daysAgo(2), weight: 80)
        box.vm.updateBodyWeight(for: Date(), weight: 79.5)
        #expect(box.vm.bodyWeightForDate(Date()) == 79.5)
        #expect(box.vm.bodyWeightSeries().map(\.weight) == [80, 79.5])
        box.vm.setNote("  Buena sesión  ", for: Date())
        #expect(box.vm.note(for: Date()) == "Buena sesión")
        box.vm.setNote("   ", for: Date())
        #expect(box.vm.note(for: Date()) == nil)
        box.vm.setNote("x", for: Date())
        box.vm.deleteHistory(for: Date())
        #expect(box.vm.note(for: Date()) == nil && box.vm.bodyWeightForDate(Date()) == nil)
    }
}

// MARK: - Rutinas

@Suite(.serialized) @MainActor
struct RoutineTests {

    @Test func createActivateRenameDelete() {
        let box = TestBox(); defer { box.tearDown() }
        let (_, rec) = box.add("Press", on: .monday)
        box.vm.setLabel("Pecho", for: .monday)
        box.vm.completeSet(for: rec.id, in: .monday)
        #expect(box.vm.activeRoutineName == "Mi rutina")
        #expect(box.vm.savedRoutines.isEmpty)

        box.vm.createRoutine(named: "  Fuerza ", copyingCurrent: false)
        #expect(box.vm.activeRoutineName == "Fuerza")
        #expect(box.vm.dailyWorkoutRecords[.monday]?.isEmpty == true)
        #expect(box.vm.dayLabels.isEmpty)
        #expect(box.vm.savedRoutines.count == 1)
        #expect(box.vm.savedRoutines.first?.name == "Mi rutina")
        #expect(box.vm.savedRoutines.first?.plan[.monday]?.first?.completedSets == 0, "la estantería guarda la plantilla sin progreso")
        #expect(box.vm.workoutHistory[TestBox.today]?[.monday]?.first?.completedSets == 1, "el historial se queda")

        box.vm.createRoutine(named: "", copyingCurrent: false)
        #expect(box.vm.activeRoutineName == "Fuerza", "nombre vacío: nada")

        let mine = box.vm.savedRoutines.first!
        box.vm.activate(mine)
        #expect(box.vm.activeRoutineName == "Mi rutina")
        #expect(box.vm.dailyWorkoutRecords[.monday]?.count == 1)
        #expect(box.vm.label(for: .monday) == "Pecho")
        #expect(box.vm.savedRoutines.map(\.name) == ["Fuerza"])

        box.vm.createRoutine(named: "Copia", copyingCurrent: true)
        #expect(box.vm.dailyWorkoutRecords[.monday]?.count == 1)
        #expect(box.vm.label(for: .monday) == "Pecho")
        #expect(box.vm.savedRoutines.count == 2)

        box.vm.renameActiveRoutine("Copia 2")
        #expect(box.vm.activeRoutineName == "Copia 2")
        box.vm.renameActiveRoutine("   ")
        #expect(box.vm.activeRoutineName == "Copia 2")

        let fuerza = box.vm.savedRoutines.first { $0.name == "Fuerza" }!
        box.vm.deleteRoutine(fuerza)
        #expect(box.vm.savedRoutines.map(\.name) == ["Mi rutina"])
        // Persistencia real: otro VM sobre el mismo dominio ve lo mismo.
        let again = WorkoutViewModel(defaults: box.defaults)
        #expect(again.savedRoutines.map(\.name) == ["Mi rutina"])
        #expect(again.activeRoutineName == "Copia 2")
    }

    @Test func moveExerciseBounds() {
        let box = TestBox(); defer { box.tearDown() }
        let (a, _) = box.add("A", on: .monday)
        let (b, _) = box.add("B", on: .monday)
        let (c, _) = box.add("C", on: .monday)
        func order() -> [String] { box.vm.dailyWorkoutRecords[.monday]!.map { box.vm.getExercise(by: $0.exerciseId)!.name } }
        box.vm.moveExercise(in: .monday, from: 0, to: 2)
        #expect(order() == ["B", "C", "A"])
        box.vm.moveExercise(in: .monday, from: 2, to: 0)
        #expect(order() == ["A", "B", "C"])
        box.vm.moveExercise(in: .monday, from: 5, to: 0)
        box.vm.moveExercise(in: .monday, from: 0, to: -1)
        box.vm.moveExercise(in: .monday, from: 1, to: 1)
        box.vm.moveExercise(in: .sunday, from: 0, to: 1)
        #expect(order() == ["A", "B", "C"])
        _ = (a, b, c)
    }

    @Test func resetClearsEverythingButProfile() {
        let box = TestBox(); defer { box.tearDown() }
        box.defaults.set("Jordi", forKey: "user_name")
        let (_, rec) = box.add("Press", on: .monday)
        box.vm.completeSet(for: rec.id, in: .monday)
        box.vm.createRoutine(named: "Otra", copyingCurrent: true)
        box.vm.resetAllData()
        #expect(box.vm.availableExercises.isEmpty)
        #expect(box.vm.workoutHistory.isEmpty)
        #expect(box.vm.savedRoutines.isEmpty)
        #expect(box.vm.activeRoutineName == "Mi rutina")
        #expect(!box.vm.timerActive)
        #expect(box.defaults.string(forKey: "user_name") == "Jordi")
        let again = WorkoutViewModel(defaults: box.defaults)
        #expect(again.availableExercises.isEmpty && again.savedRoutines.isEmpty)
    }
}

// MARK: - Copia, CSV y compatibilidad

@Suite(.serialized) @MainActor
struct BackupTests {

    @Test func roundTrip() throws {
        let box = TestBox(); defer { box.tearDown() }
        box.defaults.set("Jordi", forKey: "user_name")
        box.defaults.set("80", forKey: "user_weight")
        let (_, rec) = box.add("Press \"inclinado\"", on: .monday)
        box.vm.completeSet(for: rec.id, in: .monday, weight: 42.5, reps: 8, rpe: 8)
        box.vm.setLabel("Pecho", for: .monday)
        box.vm.setNote("nota", for: Date())
        box.vm.updateBodyWeight(for: Date(), weight: 80)
        box.vm.createRoutine(named: "Otra", copyingCurrent: true)
        let data = try box.vm.backupData()

        let other = TestBox(); defer { other.tearDown() }
        try other.vm.restore(from: data)
        // Las fechas de las series pierden las fracciones de segundo en el
        // JSON: se comparan tras pasar ambas por el mismo codificador.
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601; enc.outputFormatting = [.sortedKeys]
        func same<T: Encodable>(_ a: T, _ b: T) throws -> Bool { try enc.encode(a) == enc.encode(b) }
        // Los diccionarios con clave enum/fecha se codifican en el orden de
        // iteración, que no es estable: se comparan clave a clave.
        func samePlan(_ a: [WorkoutDay: [WorkoutExercise]], _ b: [WorkoutDay: [WorkoutExercise]]) throws -> Bool {
            try Set(a.keys) == Set(b.keys) && a.keys.allSatisfy { try same(a[$0]!, b[$0]!) }
        }
        #expect(other.vm.availableExercises == box.vm.availableExercises)
        #expect(try samePlan(other.vm.dailyWorkoutRecords, box.vm.dailyWorkoutRecords))
        #expect(Set(other.vm.workoutHistory.keys) == Set(box.vm.workoutHistory.keys))
        for (date, byDay) in box.vm.workoutHistory {
            #expect(try samePlan(other.vm.workoutHistory[date] ?? [:], byDay))
        }
        #expect(other.vm.bodyWeightHistory == box.vm.bodyWeightHistory)
        #expect(other.vm.dayLabels == box.vm.dayLabels)
        #expect(other.vm.sessionNotes == box.vm.sessionNotes)
        #expect(other.vm.savedRoutines.map(\.id) == box.vm.savedRoutines.map(\.id))
        #expect(other.vm.savedRoutines.map(\.name) == box.vm.savedRoutines.map(\.name))
        for (a, b) in zip(other.vm.savedRoutines, box.vm.savedRoutines) {
            #expect(try samePlan(a.plan, b.plan))
            #expect(a.dayLabels == b.dayLabels && a.activeDays == b.activeDays)
        }
        #expect(other.vm.activeRoutineName == "Otra")
        #expect(other.defaults.string(forKey: "user_name") == "Jordi")
        #expect(other.vm.sessionDate == TestBox.today)
        // Persistió: un tercer VM lo lee igual.
        let again = WorkoutViewModel(defaults: other.defaults)
        #expect(Set(again.workoutHistory.keys) == Set(other.vm.workoutHistory.keys))
        for (date, byDay) in other.vm.workoutHistory {
            #expect(try samePlan(again.workoutHistory[date] ?? [:], byDay))
        }
    }

    @Test func restoreOldBackupArchivesItsSession() throws {
        let box = TestBox(); defer { box.tearDown() }
        let (_, rec) = box.add("Press", on: .monday)
        box.vm.completeSet(for: rec.id, in: .monday)
        var backup = box.vm.makeBackup()
        backup.exportedAt = TestBox.daysAgo(2)
        // La copia se hizo hace dos días con la plantilla marcada.
        backup.history = [TestBox.daysAgo(2): [.monday: backup.plan[.monday]!]]
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
        let data = try enc.encode(backup)

        let other = TestBox(); defer { other.tearDown() }
        try other.vm.restore(from: data)
        #expect(other.vm.sessionDate == TestBox.today)
        #expect(other.vm.dailyWorkoutRecords[.monday]?.first?.completedSets == 0, "las series de la copia no son de hoy")
        #expect(other.vm.workoutHistory[TestBox.daysAgo(2)]?[.monday]?.first?.completedSets == 1)
        #expect(other.vm.workoutHistory[TestBox.today] == nil)
    }

    @Test func restoreRejectsGarbageAndNewerVersions() {
        let box = TestBox(); defer { box.tearDown() }
        #expect(throws: WorkoutViewModel.RestoreError.self) { try box.vm.restore(from: Data("hola".utf8)) }
        #expect(throws: WorkoutViewModel.RestoreError.self) { try box.vm.restore(from: Data("{\"version\":1}".utf8)) }
        let newer = "{\"version\":2,\"exercises\":[]}"
        #expect(throws: WorkoutViewModel.RestoreError.self) { try box.vm.restore(from: Data(newer.utf8)) }
        // Copia mínima (solo ejercicios) se acepta.
        let minimal = "{\"exercises\":[{\"name\":\"X\",\"repetitions\":8,\"weight\":10}]}"
        #expect(throws: Never.self) { try box.vm.restore(from: Data(minimal.utf8)) }
        #expect(box.vm.availableExercises.first?.name == "X")
        #expect(box.vm.availableExercises.first?.totalSets == 4)
    }

    @Test func csvOneRowPerSet() {
        let box = TestBox(); defer { box.tearDown() }
        let (_, rec) = box.add("Press \"inclinado\"", on: .monday)
        box.vm.completeSet(for: rec.id, in: .monday, weight: 42.5, reps: 8, type: .warmup)
        box.vm.completeSet(for: rec.id, in: .monday, weight: 50, reps: 6, rpe: 9)
        let rows = box.vm.exportCSV().split(separator: "\n")
        #expect(rows[0] == "fecha,dia,ejercicio,serie,tipo,kg,reps,rpe")
        #expect(rows.count == 3)
        #expect(rows[1].hasSuffix(",Lunes,\"Press 'inclinado'\",1,warmup,42.5,8,"))
        #expect(rows[2].hasSuffix(",Lunes,\"Press 'inclinado'\",2,normal,50,6,9"))
    }

    @Test func tolerantDecoding() throws {
        let ex = try JSONDecoder().decode(Exercise.self, from: Data("{\"name\":\"Solo nombre\"}".utf8))
        #expect(ex.name == "Solo nombre" && ex.totalSets == 4 && ex.restDuration == 60 && ex.repetitions == 10)
        let r = try JSONDecoder().decode(Routine.self, from: Data("{\"name\":\"R\"}".utf8))
        #expect(r.name == "R" && r.activeDays == WorkoutDay.allCases)
        let s = try JSONDecoder().decode(TodaySummary.self, from: Data("{\"dayName\":\"Lunes\"}".utf8))
        #expect(s.dayName == "Lunes" && s.isRestDay)
        // Una clave ilegible no se pisa: se aparta y se avisa.
        let box = TestBox(seed: { d in d.set(Data("basura".utf8), forKey: "AvailableExercises") })
        defer { box.tearDown() }
        #expect(box.vm.loadWarning != nil)
        #expect(box.vm.availableExercises.isEmpty)
        let kept = box.defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("AvailableExercises-corrupt-") }
        #expect(kept.count == 1)
    }

    /// Los datos reales del iPhone de Jordi (copia local, fuera del repo).
    @Test(arguments: ["antes-pulso", "hoy"]) func realDataLoads(fixture: String) throws {
        guard let url = Bundle(for: FixtureAnchor.self).url(forResource: fixture, withExtension: "plist") else {
            return // sin fixture (repo limpio): no hay nada que comprobar
        }
        let raw = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as! [String: Any]
        let box = TestBox(seed: { d in
            for (k, v) in raw where !k.hasPrefix("NS") && !k.hasPrefix("Apple") { d.set(v, forKey: k) }
        })
        defer { box.tearDown() }
        #expect(box.vm.loadWarning == nil)
        #expect(box.vm.availableExercises.count == 16)
        #expect(box.vm.workoutHistory.count >= 13)
        #expect(box.vm.dailyWorkoutRecords.count == 7)
        #expect(box.vm.sessionDate == TestBox.today)
        #expect(box.vm.consecutiveWorkoutDays() >= 0)
        _ = box.vm.weekStats()
        _ = box.vm.setsByMuscleGroup()
        _ = box.vm.topRecords()
        for ex in box.vm.availableExercises {
            _ = box.vm.exerciseDailyMaxWeight(for: ex.id)
            _ = box.vm.exerciseDailyOneRepMax(for: ex.id)
            _ = box.vm.lastPerformance(for: ex.id)
        }
        #expect(!box.vm.exportCSV().isEmpty)
        let data = try box.vm.backupData()
        let other = TestBox(); defer { other.tearDown() }
        try other.vm.restore(from: data)
        #expect(other.vm.availableExercises.count == 16)
    }
}

// MARK: - Temporizador y avisos

@Suite(.serialized) @MainActor
struct TimerTests {

    @Test func startExtendStopComplete() {
        let box = TestBox(); defer { box.tearDown() }
        box.vm.startTimer(duration: 0)
        #expect(!box.vm.timerActive)
        box.vm.startTimer(duration: 90, isEnabled: false)
        #expect(!box.vm.timerActive)
        box.vm.startTimer(duration: 90)
        #expect(box.vm.timerActive && box.vm.timeRemaining == 90 && box.vm.timerEndDate != nil)
        box.vm.extendTimer(by: 30)
        #expect(box.vm.currentTimerDuration == 120 && box.vm.timeRemaining >= 119)
        box.vm.stopTimer()
        #expect(!box.vm.timerActive && box.vm.timerEndDate == nil)
        box.vm.extendTimer(by: 30)
        #expect(!box.vm.timerActive)
        // Fin natural: el reloj de pared manda.
        box.vm.startTimer(duration: 5)
        box.vm.tick()
        #expect(box.vm.timerActive)
        let before = box.vm.notifications.count
        box.vm.adoptTimerEnd(Date().addingTimeInterval(-1))
        box.vm.tick()
        #expect(!box.vm.timerActive)
        #expect(box.vm.notifications.count == before + 1)
        #expect(box.vm.notifications.first?.kind == .restTimer)
    }

    @Test func notificationsCenter() {
        let box = TestBox(); defer { box.tearDown() }
        for i in 0..<70 { box.vm.notify(.workoutReminder, title: "t\(i)", message: "m") }
        #expect(box.vm.notifications.count == 60, "tope de 60")
        #expect(box.vm.notifications.first?.title == "t69", "la última va la primera")
        #expect(box.vm.unreadNotifications == 60)
        box.vm.markNotificationRead(box.vm.notifications[0].id)
        #expect(box.vm.unreadNotifications == 59)
        box.vm.markAllNotificationsRead()
        #expect(box.vm.unreadNotifications == 0)
        box.vm.clearNotifications()
        #expect(box.vm.notifications.isEmpty)
        let again = WorkoutViewModel(defaults: box.defaults)
        #expect(again.notifications.isEmpty)
    }

    @Test func helpersFormatting() {
        #expect(WorkoutViewModel.kg(42.5) == "42,5 kg")
        #expect(WorkoutViewModel.kg(40) == "40 kg")
        #expect(WorkoutViewModel.kg(53.75) == "53,75 kg")
        #expect(WorkoutViewModel.number(0.5) == "0,5")
        #expect(WorkoutViewModel.restText(90) == "1:30")
        #expect(WorkoutViewModel.restText(30) == "30 s")
        #expect(ExerciseDetailSheet.ssLetter(0) == "A")
        #expect(ExerciseDetailSheet.ssLetter(999) == "Z")
        #expect(ExerciseDetailSheet.ssLetter(-4) == "A")
        #expect(ExerciseFormSheet.restParts(113) == (2, 0))
        #expect(ExerciseFormSheet.restParts(97) == (1, 30))
        #expect(ExerciseFormSheet.restParts(9999) == (10, 0))
        #expect(ExerciseFormSheet.restParts(-5) == (0, 0))
    }

    @Test func sampleRoutineIsIdempotent() {
        let box = TestBox(); defer { box.tearDown() }
        box.vm.loadSampleRoutine()
        let n = box.vm.availableExercises.count
        #expect(n == 15)
        #expect(box.vm.dailyWorkoutRecords[.monday]?.count == 5)
        box.vm.loadSampleRoutine()
        #expect(box.vm.availableExercises.count == n)
        #expect(box.vm.dailyWorkoutRecords[.monday]?.count == 5)
        #expect(box.vm.activeDays == [.monday, .wednesday, .friday])
    }
}

// MARK: - Fase 1: discos, calentamiento y sugerencia de peso

@Suite(.serialized) @MainActor
struct ProgressionTests {

    /// Deja una sesión de trabajo del ejercicio `daysAgo` días atrás.
    func session(_ box: TestBox, _ ex: Exercise, daysAgo: Int, weight: Double, reps: [Int], rpe: Int? = nil,
                 type: SetType = .normal) {
        let date = TestBox.daysAgo(daysAgo).addingTimeInterval(18 * 3600)
        var rec = WorkoutExercise(exerciseId: ex.id)
        for (i, r) in reps.enumerated() {
            rec.setLogs.append(SetLog(reps: r, weight: weight, type: i == reps.count - 1 ? type : .normal,
                                      rpe: i == reps.count - 1 ? rpe : nil, date: date.addingTimeInterval(Double(i) * 180)))
        }
        rec.completedSets = reps.count
        box.vm.workoutHistory[TestBox.daysAgo(daysAgo)] = [.monday: [rec]]
    }

    @Test func plates() {
        let side = PlateMath.perSide(target: 100, bar: 20)
        #expect(side.map(\.plate) == [25, 15])
        #expect(PlateMath.sideText(target: 100, bar: 20) == "25 + 15")
        #expect(PlateMath.sideText(target: 20, bar: 20) == "solo la barra")
        #expect(PlateMath.perSide(target: 10, bar: 20).isEmpty)
        #expect(abs(PlateMath.residual(target: 101, bar: 20) - 1) < 0.001)
        #expect(PlateMath.sideText(target: 62.5, bar: 20) == "20 + 1,25")
    }

    @Test func warmups() {
        #expect(PlateMath.warmup(for: 20).isEmpty)
        #expect(PlateMath.warmup(for: 30) == [.init(weight: 20, reps: 10)])
        let w = PlateMath.warmup(for: 100)
        #expect(w.map(\.weight) == [20, 50, 70, 85])
        #expect(w.map(\.reps) == [10, 5, 3, 1])
        let light = PlateMath.warmup(for: 50)
        #expect(light.map(\.weight) == [20, 25, 35])
        #expect(light.allSatisfy { $0.weight < 50 })
    }

    @Test func suggestsUpWhenCompletedEasy() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, _) = box.add("Press", sets: 3, weight: 60, reps: 8, on: .monday)
        session(box, ex, daysAgo: 3, weight: 60, reps: [8, 8, 8], rpe: 8)
        let s = box.vm.suggestion(for: ex)
        #expect(s?.trend == .up && s?.weight == 62.5 && s?.reps == 8)
        #expect(s?.reason.contains("60 kg") == true)
    }

    @Test func lightWeightsGoUpByOne() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, _) = box.add("Curl", sets: 3, weight: 12, reps: 10, on: .monday)
        session(box, ex, daysAgo: 2, weight: 12, reps: [10, 10, 10])
        #expect(box.vm.suggestion(for: ex)?.weight == 13)
    }

    @Test func staysWhenHardOrMissed() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, _) = box.add("Press", sets: 3, weight: 60, reps: 8, on: .monday)
        session(box, ex, daysAgo: 3, weight: 60, reps: [8, 8, 8], rpe: 10)
        #expect(box.vm.suggestion(for: ex)?.trend == .same)
        session(box, ex, daysAgo: 3, weight: 60, reps: [8, 7, 5])
        #expect(box.vm.suggestion(for: ex)?.trend == .same)
        #expect(box.vm.suggestion(for: ex)?.weight == 60)
    }

    @Test func goesDownAfterTwoMissedSessions() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, _) = box.add("Press", sets: 3, weight: 80, reps: 8, on: .monday)
        session(box, ex, daysAgo: 7, weight: 80, reps: [8, 6, 5])
        session(box, ex, daysAgo: 3, weight: 80, reps: [7, 6, 5])
        let s = box.vm.suggestion(for: ex)
        #expect(s?.trend == .down)
        #expect(s?.weight == 75)
    }

    @Test func bodyweightAndTimed() {
        let box = TestBox(); defer { box.tearDown() }
        let (dips, _) = box.add("Fondos", sets: 3, weight: 0, reps: 10, on: .monday)
        session(box, dips, daysAgo: 2, weight: 0, reps: [10, 10, 10])
        #expect(box.vm.suggestion(for: dips)?.reps == 11)
        var plank = Exercise(name: "Plancha", repetitions: 0, weight: 0, segundos: 45)
        box.vm.createExercise(plank, days: [.monday])
        plank = box.vm.getExercise(by: plank.id)!
        #expect(box.vm.suggestion(for: plank) == nil)
        let fresh = Exercise(name: "Nuevo", repetitions: 8, weight: 30)
        box.vm.createExercise(fresh, days: [.monday])
        #expect(box.vm.suggestion(for: fresh) == nil, "sin historial no se inventa")
    }

    @Test func dotUsesSuggestionThenTodaysLastSet() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, rec) = box.add("Press", sets: 4, weight: 60, reps: 8, on: .monday)
        session(box, ex, daysAgo: 3, weight: 60, reps: [8, 8, 8, 8], rpe: 7)
        box.vm.completeSet(for: rec.id, in: .monday)
        #expect(box.vm.dailyWorkoutRecords[.monday]!.first!.setLogs.last?.weight == 62.5, "la bolita usa la sugerencia")
        box.vm.completeSet(for: rec.id, in: .monday, weight: 65, reps: 6)
        box.vm.completeSet(for: rec.id, in: .monday)
        #expect(box.vm.dailyWorkoutRecords[.monday]!.first!.setLogs.last?.weight == 65, "dentro de la sesión, la serie anterior")
        // La sesión de hoy no cuenta para la sugerencia de hoy.
        #expect(box.vm.suggestion(for: ex)?.weight == 62.5)
    }

    @Test func newExerciseFieldsRoundTrip() throws {
        let ex = Exercise(name: "Prensa", repetitions: 10, weight: 120, setupNote: "asiento 4", goalWeight: 150)
        let back = try JSONDecoder().decode(Exercise.self, from: JSONEncoder().encode(ex))
        #expect(back.setupNote == "asiento 4" && back.goalWeight == 150)
        #expect(back.setupText == "asiento 4")
        let old = try JSONDecoder().decode(Exercise.self, from: Data("{\"name\":\"Viejo\"}".utf8))
        #expect(old.setupNote == nil && old.goalWeight == nil && old.setupText == nil)
    }
}

// MARK: - Fase 2: modo entreno y resumen

@Suite(.serialized) @MainActor
struct SessionFlowTests {

    @Test func nextRecordFollowsOrderSupersetsAndSkips() {
        let box = TestBox(); defer { box.tearDown() }
        let (_, a) = box.add("A", sets: 2, on: .monday)
        let (_, b) = box.add("B", sets: 2, on: .monday)
        let (_, c) = box.add("C", sets: 1, on: .monday)
        #expect(box.vm.nextRecord(in: .monday)?.id == a.id)
        box.vm.setSupersetGroup(0, for: a.id, in: .monday)
        box.vm.setSupersetGroup(0, for: b.id, in: .monday)
        box.vm.completeSet(for: a.id, in: .monday)
        #expect(box.vm.nextRecord(in: .monday)?.id == b.id, "en superserie, el que va por detrás")
        box.vm.completeSet(for: b.id, in: .monday)
        #expect(box.vm.nextRecord(in: .monday)?.id == a.id)
        #expect(box.vm.nextRecord(in: .monday, skipping: [a.id, b.id])?.id == c.id, "saltados quedan para el final")
        box.vm.completeSet(for: a.id, in: .monday)
        box.vm.completeSet(for: b.id, in: .monday)
        box.vm.completeSet(for: c.id, in: .monday)
        #expect(box.vm.nextRecord(in: .monday) == nil)
        #expect(box.vm.nextRecord(in: .monday, skipping: [c.id]) == nil)
        box.vm.stopTimer(silent: true)
    }

    @Test func skippedComeBackWhenNothingElse() {
        let box = TestBox(); defer { box.tearDown() }
        let (_, a) = box.add("A", sets: 1, on: .monday)
        #expect(box.vm.nextRecord(in: .monday, skipping: [a.id])?.id == a.id)
    }

    @Test func summaryWithRecordsAndPrevious() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, rec) = box.add("Press", sets: 3, weight: 60, reps: 8, on: .monday)
        // La última vez que se hizo el lunes: 2 series de 60.
        var old = WorkoutExercise(exerciseId: ex.id)
        let oldDate = TestBox.daysAgo(7)
        old.setLogs = [SetLog(reps: 8, weight: 60, date: oldDate.addingTimeInterval(3600)),
                       SetLog(reps: 8, weight: 60, date: oldDate.addingTimeInterval(3600 + 1500))]
        old.completedSets = 2
        box.vm.workoutHistory[oldDate] = [.monday: [old]]
        box.vm.completeSet(for: rec.id, in: .monday, weight: 65, reps: 8)
        box.vm.completeSet(for: rec.id, in: .monday, weight: 65, reps: 8)
        box.vm.completeSet(for: rec.id, in: .monday, weight: 65, reps: 6)
        box.vm.stopTimer(silent: true)
        let s = box.vm.sessionSummary(for: .monday, endedAt: Date())
        #expect(s.sets == 3 && s.totalSets == 3 && s.exercisesDone == 1)
        #expect(abs(s.volume - (65 * 8 * 2 + 65 * 6)) < 0.01)
        #expect(s.records == [.init(name: "Press", weight: 65)])
        #expect(s.previous?.sets == 2)
        #expect(abs((s.previous?.volume ?? 0) - 960) < 0.01)
        #expect(abs((s.previous?.duration ?? 0) - 1500) < 1)
        #expect(s.start != nil && s.duration >= 0)
    }

    @Test func firstEverSessionHasNoRecordsNorPrevious() {
        let box = TestBox(); defer { box.tearDown() }
        let (_, rec) = box.add("Press", sets: 3, weight: 60, on: .monday)
        box.vm.completeSet(for: rec.id, in: .monday)
        box.vm.stopTimer(silent: true)
        let s = box.vm.sessionSummary(for: .monday)
        #expect(s.records.isEmpty && s.previous == nil)
    }

    @Test func nextUpTextAndFormatting() {
        let box = TestBox(); defer { box.tearDown() }
        box.add("Press militar", sets: 3, weight: 40, reps: 8, on: .monday)
        #expect(box.vm.nextUpText(in: .monday) == "Press militar, 40 kilos por 8")
        #expect(box.vm.nextUpText(in: .sunday) == nil)
        #expect(WorkoutViewModel.durationText(42 * 60) == "42 min")
        #expect(WorkoutViewModel.durationText(65 * 60) == "1 h 05 min")
        #expect(WorkoutViewModel.durationText(10) == "1 min")
        #expect(WorkoutViewModel.tonnageText(840) == "840 kg")
        #expect(WorkoutViewModel.tonnageText(1250) == "1,2 t" || WorkoutViewModel.tonnageText(1250) == "1,3 t")
    }

    @Test func finishingCallsTheHook() {
        let box = TestBox(); defer { box.tearDown() }
        var got: SessionSummary? = nil
        box.vm.onSessionFinished = { got = $0 }
        box.vm.sessionFinished(box.vm.sessionSummary(for: .monday))
        #expect(got?.day == .monday)
    }
}

// MARK: - Fase 3: acciones de Siri, Atajos y Botón de Acción

@Suite(.serialized) @MainActor
struct IntentActionTests {

    @Test func markUndoAndToday() {
        let box = TestBox(); defer { box.tearDown() }
        let today = WeeklyCalendarView.getCurrentDay()
        box.vm.trainingDay = today
        #expect(box.vm.handle(.markSet) == "Hoy no tienes ejercicios en la rutina.")
        #expect(box.vm.handle(.today) == "Hoy es día libre. ¡A descansar!")
        let (ex, _) = box.add("Press", sets: 2, weight: 50, reps: 8, rest: 90, on: today)
        box.vm.setLabel("Pecho", for: today)
        let t = box.vm.handle(.today)
        #expect(t.contains("Pecho") && t.contains("1 ejercicio y 2 series") && t.contains("Siguiente: Press, 50 kilos por 8"))
        let m = box.vm.handle(.markSet)
        #expect(m == "Serie 1 de 2 de Press: 50 kilos por 8. Descanso de 1:30.")
        #expect(box.vm.timerActive)
        #expect(box.vm.handle(.extendRest).hasPrefix("Treinta segundos más"))
        #expect(box.vm.handle(.stopRest) == "Descanso terminado.")
        #expect(box.vm.handle(.stopRest) == "No había ningún descanso en marcha.")
        #expect(box.vm.handle(.undoSet) == "Quitada la serie 1 de Press.")
        #expect(box.vm.handle(.undoSet) == "No hay ninguna serie que deshacer.")
        _ = box.vm.handle(.markSet); box.vm.stopTimer(silent: true)
        _ = box.vm.handle(.markSet); box.vm.stopTimer(silent: true)
        #expect(box.vm.handle(.markSet) == "¡Ya has hecho todas las series de hoy!")
        #expect(box.vm.allSetLogs(for: ex.id).count == 2)
    }

    @Test func restAndWeightAndOpen() {
        let box = TestBox(); defer { box.tearDown() }
        #expect(box.vm.handle(.extendRest) == "No hay ningún descanso en marcha.")
        #expect(box.vm.handle(.startRest) == "Descanso de 2:00.")
        #expect(box.vm.timerActive)
        box.vm.stopTimer(silent: true)
        #expect(box.vm.handle(.logWeight(80.5)) == "Apuntado: 80,5 kg.")
        #expect(box.vm.bodyWeightForDate(Date()) == 80.5)
        #expect(box.vm.handle(.openWorkout) == "Abriendo el modo entreno.")
        #expect(box.vm.pendingWorkoutOpen)
    }

    @Test func activeTrainingDayFollowsWhatYouTrain() {
        let box = TestBox(); defer { box.tearDown() }
        let today = WeeklyCalendarView.getCurrentDay()
        let other: WorkoutDay = today == .monday ? .tuesday : .monday
        box.vm.trainingDay = today
        let (_, rec) = box.add("Sentadilla", sets: 3, on: other)
        #expect(box.vm.activeTrainingDay == today)
        box.vm.completeSet(for: rec.id, in: other)
        box.vm.stopTimer(silent: true)
        #expect(box.vm.activeTrainingDay == other, "si hoy entrenas otro día de rutina, Siri sigue ese")
        #expect(box.vm.handle(.markSet).hasPrefix("Serie 2 de 3 de Sentadilla"))
        box.vm.stopTimer(silent: true)
    }
}

// MARK: - Fase 4: recuperación, objetivos, avisos y mapa muscular

@Suite(.serialized) @MainActor
struct HealthGoalsRemindersTests {

    @Test func recoveryLevels() {
        #expect(Recovery().level == nil)
        #expect(Recovery(sleepHours: 7.5, restingHR: 55, restingHRAvg: 56, hrv: 60, hrvAvg: 58).level == .good)
        #expect(Recovery(sleepHours: 6.5, restingHR: 59, restingHRAvg: 55).level == .normal, "dos avisos")
        #expect(Recovery(sleepHours: 5.2).level == .normal, "una señal mala sola")
        #expect(Recovery(sleepHours: 5.2, restingHR: 62, restingHRAvg: 55).level == .easy)
        #expect(Recovery(sleepHours: 8, hrv: 40, hrvAvg: 60).level == .normal, "VFC muy baja")
        #expect(Recovery(sleepHours: 8).headline == "Día para apretar")
    }

    @Test func etaFromTrend() {
        let now = Date()
        let week: Double = 7 * 86_400
        func point(_ i: Int, _ step: Double) -> (Date, Double) {
            let d: Double = Double(i - 4) * week
            return (now.addingTimeInterval(d), 60 + Double(i) * step)
        }
        let pts: [(Date, Double)] = (0..<5).map { point($0, 2.5) }
        let eta = WorkoutViewModel.linearETA(points: pts, target: 80, now: now)
        #expect(eta != nil)
        // 2,5 kg por semana: de 70 a 80 son unas 4 semanas.
        let weeks: Double = (eta?.timeIntervalSince(now) ?? 0) / week
        #expect(weeks > 3.5 && weeks < 4.5)
        let flat: [(Date, Double)] = (0..<5).map { point($0, 0) }
        #expect(WorkoutViewModel.linearETA(points: flat, target: 80, now: now) == nil)
        #expect(WorkoutViewModel.linearETA(points: Array(pts.prefix(2)), target: 80, now: now) == nil)
        let slow: [(Date, Double)] = (0..<5).map { point($0, 0.1) }
        #expect(WorkoutViewModel.linearETA(points: slow, target: 100, now: now) == nil, "más de un año: sin fecha")
    }

    @Test func goalProgressAndWeeklyGoal() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, rec) = box.add("Press", sets: 3, weight: 60, on: .monday)
        #expect(box.vm.goalProgress(for: ex) == nil)
        box.vm.setGoalWeight(80, for: ex.id)
        box.vm.completeSet(for: rec.id, in: .monday, weight: 70, reps: 5)
        box.vm.stopTimer(silent: true)
        let g = box.vm.goalProgress(for: box.vm.getExercise(by: ex.id)!)
        #expect(g?.goal == 80 && g?.best == 70 && g?.reached == false)
        #expect(abs((g?.fraction ?? 0) - 0.875) < 0.001)
        box.vm.setGoalWeight(65, for: ex.id)
        #expect(box.vm.goalProgress(for: box.vm.getExercise(by: ex.id)!)?.reached == true)
        box.vm.setGoalWeight(nil, for: ex.id)
        #expect(box.vm.getExercise(by: ex.id)?.goalWeight == nil)
        #expect(box.vm.weeklySessionGoal == 3)
        box.vm.weeklySessionGoal = 12
        #expect(box.vm.weeklySessionGoal == 7)
        box.vm.weeklySessionGoal = 0
        #expect(box.vm.weeklySessionGoal == 1)
        #expect(GoalCard.startDraft(72) == 80)
    }

    @Test func importedWeightDoesNotOverwrite() {
        let box = TestBox(); defer { box.tearDown() }
        box.vm.importBodyWeight(81.2, date: Date())
        #expect(box.vm.bodyWeightForDate(Date()) == 81.2)
        box.vm.importBodyWeight(90, date: Date())
        #expect(box.vm.bodyWeightForDate(Date()) == 81.2, "lo apuntado manda")
    }

    @Test func reminderPlan() {
        let box = TestBox(); defer { box.tearDown() }
        let keys = ["reminderEnabled", "weeklySummaryEnabled", "reminderMinutes"]
        let saved = keys.map { AppDefaults.store.object(forKey: $0) }
        defer { for (k, v) in zip(keys, saved) { AppDefaults.store.set(v, forKey: k) } }

        let cal = Calendar.current
        // Un lunes a las 10:00, con rutina lunes y miércoles.
        var comps = DateComponents(); comps.weekday = 2; comps.hour = 10
        let monday = cal.nextDate(after: Date(), matching: comps, matchingPolicy: .nextTime)!
        box.add("Press", sets: 3, on: .monday)
        box.add("Remo", sets: 4, on: .wednesday)
        Reminders.enabled = true
        Reminders.weeklyEnabled = false
        Reminders.minutes = 18 * 60
        var plan = Reminders.plan(for: box.vm, now: monday)
        #expect(plan.count == 2, "lunes y miércoles")
        #expect(plan.first?.title == "Hoy toca Lunes")
        #expect(cal.component(.hour, from: plan[0].date) == 18)
        Reminders.minutes = 8 * 60
        plan = Reminders.plan(for: box.vm, now: monday)
        #expect(plan.map { cal.component(.weekday, from: $0.date) } == [4], "hoy ya pasó la hora: solo el miércoles")
        Reminders.enabled = false
        Reminders.weeklyEnabled = true
        plan = Reminders.plan(for: box.vm, now: monday)
        #expect(plan.count == 1 && plan[0].title == "Tu semana en ChamaFit")
        #expect(cal.component(.weekday, from: plan[0].date) == 2 && cal.component(.hour, from: plan[0].date) == 9)
        #expect(plan[0].body.contains("Semana sin entrenos"))
    }

    @Test func muscleVerdicts() {
        #expect(MuscleZone.verdict(0) == "sin trabajar esta semana")
        #expect(MuscleZone.verdict(6).hasPrefix("por debajo"))
        #expect(MuscleZone.verdict(14).hasPrefix("en el rango"))
        #expect(MuscleZone.verdict(25).hasPrefix("por encima"))
    }
}

// MARK: - Fase 5: IA y técnica

import UIKit

@Suite(.serialized) @MainActor
struct AITests {

    @Test func sseParsing() {
        #expect(AICoachManager.parseSSE("event: content_block_delta") == .none)
        #expect(AICoachManager.parseSSE(#"data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hola"}}"#) == .text("Hola"))
        #expect(AICoachManager.parseSSE(#"data: {"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"..."}}"#) == .none)
        #expect(AICoachManager.parseSSE(#"data: {"type":"message_stop"}"#) == .stop)
        #expect(AICoachManager.parseSSE(#"data: {"type":"error","error":{"type":"overloaded_error","message":"Overloaded"}}"#) == .error("Overloaded"))
        #expect(AICoachManager.parseSSE("data: [basura") == .none)
    }

    @Test func structuredRoutineDecoding() throws {
        let routine = #"{"name":"Fuerza 3 días","notes":"Básicos.","days":[{"day":"Lunes","label":"Pierna","exercises":[{"name":"Sentadilla","sets":5,"reps":5,"restSeconds":180}]}]}"#
        let body: [String: Any] = ["content": [["type": "thinking", "thinking": "x"], ["type": "text", "text": routine]], "stop_reason": "end_turn"]
        let g = try AICoachManager.decodeRoutine(from: JSONSerialization.data(withJSONObject: body))
        #expect(g.days.first?.exercises.first?.name == "Sentadilla")
        let refusal: [String: Any] = ["content": [], "stop_reason": "refusal"]
        #expect(throws: NSError.self) { try AICoachManager.decodeRoutine(from: JSONSerialization.data(withJSONObject: refusal)) }
        let schema = AICoachManager.routineSchema
        let props = ((((schema["properties"] as? [String: Any])?["days"] as? [String: Any])?["items"] as? [String: Any])?["properties"] as? [String: Any])
        let items = ((props?["exercises"] as? [String: Any])?["items"] as? [String: Any])?["properties"] as? [String: Any]
        #expect(((items?["name"] as? [String: Any])?["enum"] as? [String])?.count == ExerciseCatalog.all.count)
        #expect(RoutineRequest().prompt.contains("Press de banca"))
    }

    @Test func applyGeneratedRoutine() {
        let box = TestBox(); defer { box.tearDown() }
        let (bench, _) = box.add("Press de banca", sets: 3, weight: 60, on: .monday)
        let g = GeneratedRoutine(name: "IA", notes: "", days: [
            .init(day: "Martes", label: "Torso", exercises: [.init(name: "press de banca", sets: 4, reps: 8, restSeconds: 120),
                                                             .init(name: "Remo con barra", sets: 4, reps: 10, restSeconds: 90),
                                                             .init(name: "Inventado", sets: 3, reps: 10, restSeconds: 60)]),
            .init(day: "Martes", label: "Repetido", exercises: [.init(name: "Crunch", sets: 3, reps: 20, restSeconds: 30)]),
            .init(day: "Jueves", label: "Core", exercises: [.init(name: "Plancha", sets: 3, reps: 45, restSeconds: 60)]),
            .init(day: "Funday", label: "x", exercises: []),
        ])
        let added = box.vm.applyGeneratedRoutine(g, named: "  Mi IA ")
        #expect(added == 3)
        #expect(box.vm.activeRoutineName == "Mi IA")
        #expect(box.vm.savedRoutines.count == 1, "la anterior queda guardada")
        #expect(box.vm.dailyWorkoutRecords[.tuesday]?.count == 2)
        #expect(box.vm.dailyWorkoutRecords[.tuesday]?.first?.exerciseId == bench.id, "reutiliza el ejercicio por nombre")
        #expect(box.vm.label(for: .tuesday) == "Torso")
        let plank = box.vm.availableExercises.first { $0.name == "Plancha" }
        #expect(plank?.segundos == 45 && plank?.repetitions == 0, "por tiempo: reps como segundos")
        #expect(box.vm.availableExercises.first { $0.name == "Remo con barra" }?.restDuration == 90)
        #expect(box.vm.activeDays == [.tuesday, .thursday])
        #expect(box.vm.dailyWorkoutRecords[.monday]?.isEmpty == true)
    }

    @Test func coachContextHasTheEssentials() {
        let box = TestBox(); defer { box.tearDown() }
        let (_, rec) = box.add("Press de banca", sets: 3, weight: 60, on: .monday, group: "Pecho")
        box.vm.completeSet(for: rec.id, in: .monday, weight: 62.5, reps: 8)
        box.vm.stopTimer(silent: true)
        let full = box.vm.coachContext(recovery: Recovery(sleepHours: 5, restingHR: 62, restingHRAvg: 55))
        #expect(full.contains("Press de banca") && full.contains("[Pecho]") && full.contains("récord 62,5 kg"))
        #expect(full.contains("de 3 sesiones objetivo"))
        #expect(full.contains("RECUPERACIÓN HOY: Mejor suave hoy"))
        let compact = box.vm.coachContext(compact: true)
        #expect(compact.count < full.count && !compact.contains("descanso"))
    }

    @Test func techniqueForEveryCatalogExercise() {
        for c in ExerciseCatalog.all {
            let t = TechniqueGuide.entry(for: c.name)
            #expect(t != nil && (t?.cues.count ?? 0) >= 3, "\(c.name) sin técnica")
        }
        #expect(TechniqueGuide.entry(for: "PRESS DE BANCA") != nil, "sin mirar mayúsculas")
        #expect(TechniqueGuide.entry(for: "Mi ejercicio raro") == nil)
        #expect(TechniquePhotos.byName.count >= 30)
        for (name, photo) in TechniquePhotos.byName {
            #expect(UIImage(named: photo.asset) != nil, "falta la foto de \(name)")
            #expect(!photo.license.isEmpty)
        }
    }
}

// MARK: - Fase 6: compartir rutinas y copia automática

@Suite(.serialized) @MainActor
struct SharingBackupTests {

    @Test func shareAndImportRoutine() throws {
        let a = TestBox(); defer { a.tearDown() }
        let (_, pb) = a.add("Press de banca", sets: 4, weight: 60, reps: 8, rest: 120, on: .monday, group: "Pecho")
        let (_, ap) = a.add("Aperturas", sets: 3, weight: 12, reps: 12, on: .monday)
        a.vm.setSupersetGroup(0, for: pb.id, in: .monday)
        a.vm.setSupersetGroup(0, for: ap.id, in: .monday)
        a.vm.completeSet(for: pb.id, in: .monday)
        a.vm.stopTimer(silent: true)
        a.vm.setLabel("Pecho", for: .monday)
        a.vm.renameActiveRoutine("Torso de Jordi")
        let data = try a.vm.routineFileData(author: "Jordi")
        let shared = try WorkoutViewModel.readSharedRoutine(from: data)
        #expect(shared.name == "Torso de Jordi" && shared.author == "Jordi")
        #expect(shared.summary == "1 días · 2 ejercicios" || shared.summary.contains("2 ejercicios"))
        #expect(!String(decoding: data, as: UTF8.self).contains("setLogs"), "sin progreso ni historial")

        let b = TestBox(); defer { b.tearDown() }
        let (existing, _) = b.add("Press de banca", sets: 5, weight: 80, on: .friday)
        let added = b.vm.importSharedRoutine(shared)
        #expect(added == 2)
        #expect(b.vm.activeRoutineName == "Torso de Jordi")
        #expect(b.vm.savedRoutines.count == 1, "la suya queda guardada")
        let monday = b.vm.dailyWorkoutRecords[.monday] ?? []
        #expect(monday.count == 2 && monday.allSatisfy { $0.supersetGroup == 0 })
        #expect(monday.first?.exerciseId == existing.id, "enlaza por nombre")
        #expect(b.vm.availableExercises.first { $0.name == "Aperturas" }?.repetitions == 12)
        #expect(b.vm.label(for: .monday) == "Pecho")
        #expect(monday.allSatisfy { $0.completedSets == 0 })
        // Importar otra vez con el mismo nombre no pisa: añade el autor.
        b.vm.importSharedRoutine(shared)
        #expect(b.vm.activeRoutineName == "Torso de Jordi (Jordi)")

        #expect(throws: WorkoutViewModel.RestoreError.self) { try WorkoutViewModel.readSharedRoutine(from: Data("{}".utf8)) }
        #expect(throws: WorkoutViewModel.RestoreError.self) {
            try WorkoutViewModel.readSharedRoutine(from: Data(#"{"version":3,"name":"x","labels":{},"days":{}}"#.utf8))
        }
        #expect(UTType.chamafitRoutine.identifier == "mauri.chamafit.routine")
    }

    @Test func autoBackupWeeklyAndPrunes() throws {
        let box = TestBox(); defer { box.tearDown() }
        let saved = AutoBackup.lastDate
        defer { AutoBackup.lastDate = saved }
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("chamafit-backup-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        AutoBackup.lastDate = nil
        #expect(AutoBackup.runIfDue(box.vm, in: dir) == nil, "sin datos no hay copia")
        box.add("Press", on: .monday)
        let start = Date()
        let first = AutoBackup.runIfDue(box.vm, now: start, in: dir)
        #expect(first != nil)
        #expect(AutoBackup.runIfDue(box.vm, now: start.addingTimeInterval(3 * 86_400), in: dir) == nil, "aún no toca")
        for w in 1...10 {
            #expect(AutoBackup.runIfDue(box.vm, now: start.addingTimeInterval(Double(w) * 7 * 86_400 + 60), in: dir) != nil)
        }
        let files = try FileManager.default.contentsOfDirectory(atPath: dir.path).filter { $0.hasSuffix(".json") }
        #expect(files.count == AutoBackup.keep)
        // Lo escrito es una copia restaurable.
        let latest = files.sorted().last!
        let other = TestBox(); defer { other.tearDown() }
        try other.vm.restore(from: Data(contentsOf: dir.appendingPathComponent(latest)))
        #expect(other.vm.availableExercises.first?.name == "Press")
    }
}

import UniformTypeIdentifiers

// MARK: - Tramo 0: fallos de la propuesta de producto

@Suite(.serialized) @MainActor
struct Tramo0Tests {

    /// Deja una sesión del ejercicio hace `daysAgo` días y devuelve su referencia.
    func pastSession(_ box: TestBox, _ ex: Exercise, daysAgo: Int, weights: [Double]) -> HistoryRef {
        let date = TestBox.daysAgo(daysAgo)
        var rec = WorkoutExercise(exerciseId: ex.id)
        rec.setLogs = weights.enumerated().map { SetLog(reps: 8, weight: $0.element, date: date.addingTimeInterval(3600 + Double($0.offset) * 200)) }
        rec.completedSets = weights.count
        box.vm.workoutHistory[date] = [.monday: [rec]]
        return box.vm.historyRef(for: ex.id, on: date)!
    }

    @Test func editPastSetsRecomputesRecords() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, _) = box.add("Press", sets: 3, weight: 60, on: .monday)
        let ref = pastSession(box, ex, daysAgo: 3, weights: [60, 60, 60])
        #expect(box.vm.personalRecord(for: ex.id)?.weight == 60)
        var log = box.vm.historyRecord(ref)!.setLogs[1]
        log.weight = 65; log.rpe = 9
        box.vm.updatePastSet(log, ref)
        #expect(box.vm.personalRecord(for: ex.id)?.weight == 65, "el récord se recalcula")
        #expect(box.vm.exportCSV().contains(",65,8,9"))
        box.vm.addPastSet(ref, weight: 62.5, reps: 6)
        #expect(box.vm.historyRecord(ref)?.completedSets == 4)
        box.vm.deletePastSet(log.id, ref)
        #expect(box.vm.personalRecord(for: ex.id)?.weight == 62.5)
        for l in box.vm.historyRecord(ref)!.setLogs { box.vm.deletePastSet(l.id, ref) }
        #expect(!box.vm.hasWorkoutForDate(TestBox.daysAgo(3)), "sin series el día deja de contar")
        // Persistió.
        let again = WorkoutViewModel(defaults: box.defaults)
        #expect(again.workoutHistory[TestBox.daysAgo(3)] == nil)
    }

    @Test func editTodayGoesThroughTheSession() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, rec) = box.add("Press", sets: 4, weight: 50, on: .monday)
        box.vm.completeSet(for: rec.id, in: .monday, weight: 50, reps: 8)
        box.vm.completeSet(for: rec.id, in: .monday, weight: 55, reps: 8)
        box.vm.completeSet(for: rec.id, in: .monday, weight: 60, reps: 8)
        box.vm.stopTimer(silent: true)
        let ref = box.vm.historyRef(for: ex.id, on: Date())!
        let middle = box.vm.historyRecord(ref)!.setLogs[1]
        box.vm.deletePastSet(middle.id, ref)
        let today = box.vm.dailyWorkoutRecords[.monday]!.first!
        #expect(today.completedSets == 2 && today.setLogs.map(\.weight) == [50, 60], "borrar una del medio")
        #expect(box.vm.workoutHistory[TestBox.today]?[.monday]?.first?.setLogs.count == 2)
        box.vm.addPastSet(ref, weight: 57.5, reps: 5)
        box.vm.stopTimer(silent: true)
        #expect(box.vm.dailyWorkoutRecords[.monday]!.first!.completedSets == 3)
    }

    @Test func restTimerSurvivesRelaunch() {
        let box = TestBox(); defer { box.tearDown() }
        box.vm.timerLabel = "Press · siguiente serie 2 de 4"
        box.vm.startTimer(duration: 120)
        let end = box.vm.timerEndDate!
        let again = WorkoutViewModel(defaults: box.defaults)
        #expect(again.timerActive && again.timerEndDate == end)
        #expect(again.timerLabel == "Press · siguiente serie 2 de 4" && again.currentTimerDuration == 120)
        again.stopTimer(silent: true)
        box.vm.stopTimer(silent: true)
        let third = WorkoutViewModel(defaults: box.defaults)
        #expect(!third.timerActive, "parado a mano no vuelve")
        // Uno que ya venció mientras la app estaba cerrada tampoco.
        box.defaults.set(Date().addingTimeInterval(-5), forKey: "RestTimerEnd")
        let fourth = WorkoutViewModel(defaults: box.defaults)
        #expect(!fourth.timerActive && box.defaults.object(forKey: "RestTimerEnd") == nil)
    }

    @Test func suggestionRespectsRecovery() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, _) = box.add("Press", sets: 3, weight: 60, reps: 8, on: .monday)
        var rec = WorkoutExercise(exerciseId: ex.id)
        let d = TestBox.daysAgo(3)
        rec.setLogs = (0..<3).map { SetLog(reps: 8, weight: 60, rpe: $0 == 2 ? 8 : nil, date: d.addingTimeInterval(Double($0) * 200)) }
        rec.completedSets = 3
        box.vm.workoutHistory[d] = [.monday: [rec]]
        #expect(box.vm.suggestion(for: ex, recovery: .good)?.weight == 62.5)
        #expect(box.vm.suggestion(for: ex, recovery: nil)?.weight == 62.5)
        let red = box.vm.suggestion(for: ex, recovery: .easy)
        #expect(red?.trend == .same && red?.weight == 60 && red?.reason.contains("Recuperación baja") == true)
        #expect(box.vm.suggestion(for: ex, recovery: .normal)?.trend == .same, "ámbar con RPE 8: no sube")
        // Con RPE 7 en ámbar, sí.
        rec.setLogs[2].rpe = 7
        box.vm.workoutHistory[d] = [.monday: [rec]]
        #expect(box.vm.suggestion(for: ex, recovery: .normal)?.weight == 62.5)
    }

    @Test func mergeRestoreKeepsMineAndAddsTheRest() throws {
        let a = TestBox(); defer { a.tearDown() }
        let (press, _) = a.add("Press", sets: 3, weight: 60, on: .monday)
        a.vm.workoutHistory[TestBox.daysAgo(10)] = [.monday: [WorkoutExercise(exerciseId: press.id, completedSets: 2,
                                                                               setLogs: [SetLog(reps: 8, weight: 60), SetLog(reps: 8, weight: 60)])]]
        a.vm.updateBodyWeight(for: TestBox.daysAgo(10), weight: 80)
        let backup = try a.vm.backupData()

        let b = TestBox(); defer { b.tearDown() }
        let (myPress, _) = b.add("press", sets: 5, weight: 70, on: .friday)       // mismo nombre, otro id
        let (squat, _) = b.add("Sentadilla", sets: 3, weight: 90, on: .monday)
        b.vm.workoutHistory[TestBox.daysAgo(2)] = [.friday: [WorkoutExercise(exerciseId: squat.id, completedSets: 1,
                                                                             setLogs: [SetLog(reps: 5, weight: 90)])]]
        b.vm.updateBodyWeight(for: TestBox.daysAgo(10), weight: 78)
        b.vm.renameActiveRoutine("La mía")
        try b.vm.restore(from: backup, mode: .merge)
        #expect(b.vm.availableExercises.count == 2, "el Press de la copia se enlaza al tuyo por nombre")
        #expect(b.vm.workoutHistory[TestBox.daysAgo(10)]?[.monday]?.first?.exerciseId == myPress.id)
        #expect(b.vm.workoutHistory[TestBox.daysAgo(2)] != nil, "lo tuyo se queda")
        #expect(b.vm.bodyWeightForDate(TestBox.daysAgo(10)) == 78, "si choca, gana lo tuyo")
        #expect(b.vm.activeRoutineName == "La mía" && b.vm.dailyWorkoutRecords[.friday]?.count == 1)
    }

    @Test func undoCopyBeforeRestore() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("chamafit-undo-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let a = TestBox(); defer { a.tearDown() }
        a.add("De la copia", on: .monday)
        let other = try a.vm.backupData()
        let b = TestBox(); defer { b.tearDown() }
        b.add("Mío", on: .tuesday)
        #expect(b.vm.saveUndoCopy(in: dir) != nil)
        try b.vm.restore(from: other, mode: .replace)
        #expect(b.vm.availableExercises.map(\.name) == ["De la copia"])
        #expect(b.vm.undoRestoreFile(in: dir) != nil)
        #expect(b.vm.undoRestoreFile(in: dir, now: Date().addingTimeInterval(8 * 86_400)) == nil, "caduca a los 7 días")
        try b.vm.undoLastRestore(in: dir)
        #expect(b.vm.availableExercises.map(\.name) == ["Mío"])
        #expect(b.vm.undoRestoreFile(in: dir) == nil)
    }

    @Test func coachContextWithoutHealth() {
        let box = TestBox(); defer { box.tearDown() }
        box.add("Press", on: .monday)
        let without = box.vm.coachContext(recovery: nil)
        let with = box.vm.coachContext(recovery: Recovery(sleepHours: 6, restingHR: 60, restingHRAvg: 55))
        #expect(!without.contains("RECUPERACIÓN") && with.contains("RECUPERACIÓN"))
    }
}

// MARK: - Tramo 1: perfil de entreno y material

@Suite(.serialized) @MainActor
struct Tramo1Tests {

    @Test func profilePersistsAndDrivesWeeklyGoal() {
        let box = TestBox(); defer { box.tearDown() }
        #expect(!box.vm.trainingProfile.completed, "sin onboarding, perfil por defecto")
        var p = box.vm.trainingProfile
        p.goal = .strength; p.level = .advanced; p.daysPerWeek = 5; p.minutes = 75
        p.focusGroups = ["Espalda"]; p.avoidExercises = ["Fondos"]; p.limitations = "hombro derecho"
        p.equipmentProfileId = EquipmentProfile.homeId; p.completed = true
        box.vm.trainingProfile = p
        #expect(box.vm.weeklySessionGoal == 5, "el objetivo semanal sale del perfil")
        let again = WorkoutViewModel(defaults: box.defaults)
        #expect(again.trainingProfile == p)
        #expect(again.activeEquipment.name == "Casa")
    }

    @Test func profileDecodeIsTolerant() throws {
        let json = #"{"goal":"cosa-rara","daysPerWeek":4,"futureField":true}"#
        let p = try JSONDecoder().decode(TrainingProfile.self, from: Data(json.utf8))
        #expect(p.goal == .hypertrophy && p.daysPerWeek == 4 && p.minutes == 60 && !p.completed)
        let e = try JSONDecoder().decode(EquipmentProfile.self, from: Data(#"{"name":"Hotel","items":["dumbbell","laser"]}"#.utf8))
        #expect(e.items == [.dumbbell], "material desconocido se ignora")
    }

    @Test func requestFromProfile() {
        let box = TestBox(); defer { box.tearDown() }
        var p = TrainingProfile()
        p.goal = .fatLoss; p.level = .beginner; p.daysPerWeek = 7; p.minutes = 90
        p.limitations = "rodilla"; p.equipmentProfileId = EquipmentProfile.bodyweightId; p.completed = true
        box.vm.trainingProfile = p
        let r = box.vm.routineRequestFromProfile()
        #expect(r.goal == "Perder grasa" && r.level == "Principiante")
        #expect(r.daysPerWeek == 6, "el generador llega hasta 6")
        #expect(r.minutes == 75, "el valor más cercano de los que ofrece")
        #expect(r.equipment == "Peso corporal")
        #expect(r.prompt.contains("rodilla"), "las limitaciones llegan a la IA")
        #expect(box.vm.coachContext().contains("PERFIL:"), "y al coach")
    }

    @Test func editingPresetEquipmentKeepsIt() {
        let box = TestBox(); defer { box.tearDown() }
        var home = box.vm.equipmentProfiles.first { $0.id == EquipmentProfile.homeId }!
        home.items.insert(.kettlebell)
        box.vm.saveEquipmentProfile(home)
        let list = box.vm.equipmentProfiles
        #expect(list.filter { $0.id == EquipmentProfile.homeId }.count == 1, "no se duplica")
        #expect(list.first { $0.id == EquipmentProfile.homeId }!.items.contains(.kettlebell))
        box.vm.saveEquipmentProfile(EquipmentProfile(name: "Hotel", items: [.dumbbell, .cardio]))
        #expect(box.vm.equipmentProfiles.count == 4)
    }

    @Test func profileTravelsInBackup() throws {
        let box = TestBox(); defer { box.tearDown() }
        _ = box.add("Press", sets: 3, weight: 60, on: .monday)
        var p = TrainingProfile(); p.goal = .endurance; p.completed = true
        box.vm.trainingProfile = p
        box.vm.saveEquipmentProfile(EquipmentProfile(name: "Hotel", items: [.dumbbell]))
        let data = try box.vm.backupData()

        let other = TestBox(); defer { other.tearDown() }
        try other.vm.restore(from: data, mode: .replace)
        #expect(other.vm.trainingProfile.goal == .endurance)
        #expect(other.vm.equipmentProfiles.contains { $0.name == "Hotel" })

        // Fusionar no pisa un perfil ya hecho.
        let third = TestBox(); defer { third.tearDown() }
        var mine = TrainingProfile(); mine.goal = .strength; mine.completed = true
        third.vm.trainingProfile = mine
        try third.vm.restore(from: data, mode: .merge)
        #expect(third.vm.trainingProfile.goal == .strength)
        #expect(third.vm.equipmentProfiles.contains { $0.name == "Hotel" })
    }
}

// MARK: - Tramo 2: tipo de carga y libras

@Suite(.serialized) @MainActor
struct Tramo2Tests {

    /// Libras solo dentro de esta tarea: las demás suites, que corren a la vez, siguen en kg.
    func withPounds(_ body: () throws -> Void) rethrows {
        try Units.$override.withValue(.lb) { try body() }
    }

    @Test func poundsRoundTripWithoutDrift() {
        withPounds {
            #expect(Units.format(100) == "220,5 lb")
            let kg = Units.parse("185")!
            #expect(Units.number(kg) == "185", "lo escrito vuelve igual")
            var w = kg
            for _ in 0..<20 { w = Units.stepped(w, by: 1) }
            for _ in 0..<20 { w = Units.stepped(w, by: -1) }
            #expect(Units.number(w) == "185", "subir y bajar no deriva")
            #expect(Units.number(Units.stepped(60, by: 1)) == "135", "60 kg = 132,3 lb → encaja en 135")
            #expect(Units.number(Units.stepped(60, by: -1)) == "130")
            #expect(Units.tonnage(10_000) == "22.046 lb" || Units.tonnage(10_000) == "22,0k lb")
        }
        #expect(Units.format(42.5) == "42,5 kg")
        #expect(Units.stepped(41, by: 1) == 42.5 && Units.stepped(40, by: 1) == 42.5)
        #expect(Units.parse("62,5") == 62.5 && Units.parse("x") == nil)
    }

    @Test func platesAndWarmupInPounds() {
        withPounds {
            let side = PlateMath.sideText(target: 225, bar: 45, plates: Units.plates)
            #expect(side == "45 + 45")
            let warm = PlateMath.warmupKg(for: Units.toKg(225), barKg: Units.toKg(45))
            #expect(warm.map { Units.number($0.weight) } == ["45", "115", "160", "190"])
        }
        #expect(PlateMath.warmupKg(for: 100, barKg: 20).map(\.weight) == [20, 50, 70, 85])
    }

    @Test func loadKindDecodesTolerant() throws {
        let old = try JSONDecoder().decode(Exercise.self, from: Data(#"{"name":"Press","repetitions":8,"weight":60}"#.utf8))
        #expect(old.loadKind == .total)
        let odd = try JSONDecoder().decode(Exercise.self, from: Data(#"{"name":"X","loadKind":"hovercraft"}"#.utf8))
        #expect(odd.loadKind == .total)
        var e = Exercise(name: "Remo", repetitions: 10, weight: 20, loadKind: .perDumbbell)
        e = try JSONDecoder().decode(Exercise.self, from: JSONEncoder().encode(e))
        #expect(e.loadKind == .perDumbbell)
    }

    @Test func volumeByLoadKind() {
        let box = TestBox(); defer { box.tearDown() }
        let (db, _) = box.add("Press mancuernas", sets: 3, weight: 20, reps: 10, on: .monday)
        let (dips, _) = box.add("Fondos lastrados", sets: 3, weight: 10, reps: 10, on: .monday)
        let (pull, _) = box.add("Dominadas asistidas", sets: 3, weight: 30, reps: 10, on: .monday)
        for (ex, kind) in [(db, LoadKind.perDumbbell), (dips, .bodyweight), (pull, .assisted)] {
            let i = box.vm.availableExercises.firstIndex { $0.id == ex.id }!
            box.vm.availableExercises[i].loadKind = kind
        }
        let log = SetLog(reps: 10, weight: 20, date: Date())
        #expect(box.vm.volume(log, kind: .perDumbbell) == 400, "dos mancuernas")
        #expect(box.vm.volume(log, kind: .assisted) == 0, "sin peso corporal no se inventa")
        box.vm.bodyWeightHistory[TestBox.daysAgo(10)] = 80
        #expect(box.vm.volume(log, kind: .assisted) == 600, "(80 − 20) × 10")
        #expect(box.vm.volume(SetLog(reps: 10, weight: 10, date: Date()), kind: .bodyweight) == 900)
        #expect(WorkoutViewModel.weightText(20, kind: .perDumbbell) == "2 × 20 kg")
        #expect(WorkoutViewModel.weightText(0, kind: .bodyweight) == "peso corporal")
    }

    @Test func assistedRecordsAndSuggestion() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, _) = box.add("Dominadas asistidas", sets: 3, weight: 30, reps: 8, on: .monday)
        let i = box.vm.availableExercises.firstIndex { $0.id == ex.id }!
        box.vm.availableExercises[i].loadKind = .assisted
        for (ago, w) in [(6, 30.0), (3, 25.0)] {
            let date = TestBox.daysAgo(ago)
            var rec = WorkoutExercise(exerciseId: ex.id)
            rec.setLogs = (0..<3).map { SetLog(reps: 8, weight: w, rpe: 7, date: date.addingTimeInterval(3600 + Double($0) * 200)) }
            rec.completedSets = 3
            box.vm.workoutHistory[date] = [.monday: [rec]]
        }
        let pr = box.vm.personalRecord(for: ex.id)
        #expect(pr?.weight == 25 && pr?.oneRepMax == 0, "récord = menos ayuda, sin 1RM")
        let s = box.vm.suggestion(for: box.vm.availableExercises[i], recovery: nil)
        #expect(s?.trend == .up && s?.weight == 22.5, "progresar es quitar ayuda")
        #expect(s?.text == "asist. 22,5 kg × 8")
        #expect(box.vm.exerciseDailyOneRepMax(for: ex.id).isEmpty)
    }
}

// MARK: - Tramo 3: biblioteca y sustituciones

@Suite(.serialized) @MainActor
struct Tramo3Tests {

    @Test func libraryIsComplete() {
        let names = ExerciseCatalog.all.map(\.name)
        #expect(names.count >= 80)
        #expect(Set(names).count == names.count, "sin nombres repetidos")
        for n in names {
            let d = ExerciseLibrary.details(for: n)
            #expect(d != nil, "\(n) sin ficha")
            #expect(TechniqueGuide.entry(for: n) != nil, "\(n) sin técnica")
            #expect(ExerciseVideos.catalogLink(for: n) != nil, "\(n) sin vídeo")
            guard let d else { continue }
            #expect(d.mistakes.count >= 2, "\(n): errores")
            #expect(!d.alternatives.isEmpty, "\(n): alternativas")
            for a in d.alternatives {
                #expect(ExerciseCatalog.entry(named: a) != nil, "\(n) → alternativa desconocida \(a)")
                #expect(ExerciseLibrary.fold(a) != ExerciseLibrary.fold(n), "\(n) se sugiere a sí mismo")
            }
        }
    }

    @Test func alternativesRespectEquipmentAndAvoid() {
        let box = TestBox(); defer { box.tearDown() }
        let gym = box.vm.alternatives(for: "Press de banca").map(\.name)
        #expect(gym.contains("Press de pecho en máquina"))
        box.vm.setActiveEquipment(EquipmentProfile.bodyweightId)
        #expect(box.vm.alternatives(for: "Press de banca").map(\.name) == ["Flexiones"], "sin material solo lo que se puede")
        var p = box.vm.trainingProfile; p.avoidExercises = ["Flexiones"]; box.vm.trainingProfile = p
        #expect(!box.vm.alternatives(for: "Press de banca").map(\.name).contains("Flexiones"))
    }

    @Test func substituteTodayRevertsNextDay() {
        let box = TestBox(); defer { box.tearDown() }
        let (bench, rec) = box.add("Press de banca", sets: 3, weight: 60, on: .monday)
        let alt = box.vm.exerciseFromCatalog(ExerciseCatalog.entry(named: "Press de banca con mancuernas")!)
        #expect(alt.loadKind == .perDumbbell, "hereda el tipo de carga del catálogo")
        box.vm.substitute(recordId: rec.id, in: .monday, with: alt, forever: false)
        #expect(box.vm.dailyWorkoutRecords[.monday]?.first?.exerciseId == alt.id)
        #expect(box.vm.temporarySwapOriginal(rec.id)?.id == bench.id)
        box.vm.completeSet(for: rec.id, in: .monday, weight: 22, reps: 10)
        // Cambio de día: lo hecho va al historial con el ejercicio que se hizo y la plantilla vuelve.
        box.vm.adoptSession(date: TestBox.daysAgo(1))
        box.vm.ensureSession()
        #expect(box.vm.dailyWorkoutRecords[.monday]?.first?.exerciseId == bench.id)
        let hist = box.vm.workoutHistory[TestBox.daysAgo(1)]?[.monday]?.first
        #expect(hist?.exerciseId == alt.id && hist?.setLogs.count == 1)
    }

    @Test func substituteForeverWithSetsDoneSplits() {
        let box = TestBox(); defer { box.tearDown() }
        let (_, rec) = box.add("Dominadas", sets: 3, weight: 0, reps: 8, on: .monday)
        box.vm.completeSet(for: rec.id, in: .monday, weight: 0, reps: 6)
        let alt = box.vm.exerciseFromCatalog(ExerciseCatalog.entry(named: "Jalón al pecho")!)
        box.vm.substitute(recordId: rec.id, in: .monday, with: alt, forever: true)
        let today = box.vm.dailyWorkoutRecords[.monday] ?? []
        #expect(today.count == 2 && today[0].setLogs.count == 1 && today[1].exerciseId == alt.id,
                "la serie hecha se queda en dominadas y el jalón entra detrás")
        box.vm.adoptSession(date: TestBox.daysAgo(1))
        box.vm.ensureSession()
        #expect(box.vm.dailyWorkoutRecords[.monday]?.map(\.exerciseId) == [alt.id], "mañana solo queda el jalón")
    }

    @Test func customVideoLink() {
        #expect(ExerciseVideos.normalized("youtu.be/abc123") == "https://youtu.be/abc123")
        #expect(ExerciseVideos.normalized("no es un enlace") == nil)
        var e = Exercise(name: "Mi ejercicio raro", repetitions: 10, weight: 0)
        #expect(ExerciseVideos.url(for: e).absoluteString.contains("results?search_query="), "sin enlace: búsqueda")
        e.videoURL = "https://youtu.be/abc123"
        #expect(ExerciseVideos.url(for: e).absoluteString == "https://youtu.be/abc123")
        #expect(ExerciseVideos.url(forName: "press de BANCA").absoluteString.contains("watch?v="), "sin tildes ni mayúsculas")
    }
}

// MARK: - Tramo 4: modos de rutina y programas

@Suite(.serialized) @MainActor
struct Tramo4Tests {

    /// Lunes, miércoles y viernes con un ejercicio cada uno (sesiones A, B, C).
    func threeSessions(_ box: TestBox) -> [WorkoutDay: UUID] {
        var ids: [WorkoutDay: UUID] = [:]
        for (d, n) in [(WorkoutDay.monday, "Sentadilla"), (.wednesday, "Press de banca"), (.friday, "Peso muerto")] {
            ids[d] = box.add(n, sets: 1, weight: 60, on: d).0.id
        }
        return ids
    }

    /// Una sesión hecha en esa fecha con ese hueco.
    func done(_ box: TestBox, _ slot: WorkoutDay, on date: Date, _ exId: UUID) {
        var rec = WorkoutExercise(exerciseId: exId)
        rec.setLogs = [SetLog(reps: 5, weight: 60, date: date.addingTimeInterval(3600 * 18))]
        rec.completedSets = 1
        rec.lastSetCompletedAt = date.addingTimeInterval(3600 * 18)
        box.vm.workoutHistory[date, default: [:]][slot] = [rec]
    }

    /// Lunes a domingo de la semana pasada.
    var lastWeek: [Date] {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        let start = cal.dateInterval(of: .weekOfYear, for: Date().addingTimeInterval(-7 * 86_400))!.start
        return (0..<7).map { Calendar.current.date(byAdding: .day, value: $0, to: Calendar.current.startOfDay(for: start))! }
    }

    @Test func fixedWeekIsTheWeekday() {
        let box = TestBox(); defer { box.tearDown() }
        _ = threeSessions(box)
        let w = lastWeek
        #expect(box.vm.nextSession(on: w[0]) == .monday)
        #expect(box.vm.nextSession(on: w[1]) == nil, "martes, descanso")
        #expect(box.vm.slotName(.wednesday) == "Miércoles")
    }

    @Test func sequenceFollowsTheLastDone() {
        let box = TestBox(); defer { box.tearDown() }
        let ids = threeSessions(box)
        box.vm.scheduleMode = .sequence
        let w = lastWeek
        #expect(box.vm.nextSession(on: w[0]) == .monday, "sin historial, la A")
        #expect(box.vm.slotName(.wednesday) == "Sesión B" && box.vm.slotShort(.friday) == "C")
        done(box, .monday, on: w[0], ids[.monday]!)
        #expect(box.vm.nextSession(on: w[1]) == .wednesday, "el martes toca la B")
        done(box, .wednesday, on: w[1], ids[.wednesday]!)
        done(box, .friday, on: w[3], ids[.friday]!)
        #expect(box.vm.nextSession(on: w[4]) == .monday, "tras la C vuelve la A")
        #expect(box.vm.nextSession(on: w[3]) == .friday, "el día que se hizo, esa")
    }

    @Test func elasticWeekKeepsPending() {
        let box = TestBox(); defer { box.tearDown() }
        let ids = threeSessions(box)
        box.vm.scheduleMode = .elasticWeek
        let w = lastWeek
        #expect(box.vm.nextSession(on: w[1]) == .monday, "el martes, la del lunes sigue pendiente")
        done(box, .monday, on: w[1], ids[.monday]!)
        #expect(box.vm.nextSession(on: w[2]) == .wednesday)
        #expect(box.vm.nextSession(on: w[3]) == .wednesday, "el jueves aún está la del miércoles")
        done(box, .wednesday, on: w[3], ids[.wednesday]!)
        #expect(box.vm.nextSession(on: w[4]) == .friday)
        done(box, .friday, on: w[4], ids[.friday]!)
        #expect(box.vm.nextSession(on: w[5]) == nil, "sábado: todo hecho, descanso")
        #expect(box.vm.pendingThisWeek(on: w[6]).isEmpty)
    }

    @Test func routineKeepsItsMode() {
        let box = TestBox(); defer { box.tearDown() }
        _ = threeSessions(box)
        box.vm.scheduleMode = .sequence
        box.vm.createRoutine(named: "Otra", copyingCurrent: false)
        #expect(box.vm.scheduleMode == .fixedWeek, "la nueva empieza en semana fija")
        let old = box.vm.savedRoutines.first!
        #expect(old.mode == .sequence)
        box.vm.activate(old)
        #expect(box.vm.scheduleMode == .sequence)
    }

    @Test func streakWithoutFixedDays() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, _) = box.add("Sentadilla", sets: 1, weight: 60, on: .monday)
        box.vm.scheduleMode = .sequence
        for ago in [1, 3, 5, 9] { done(box, .monday, on: TestBox.daysAgo(ago), ex.id) }
        #expect(box.vm.consecutiveWorkoutDays() == 3, "huecos de 1 día valen; el de 3 corta")
    }

    @Test func programAdvancesDeloadsAndRestores() {
        let box = TestBox(); defer { box.tearDown() }
        let (squat, _) = box.add("Sentadilla", sets: 3, weight: 100, reps: 8, on: .monday)
        let t = ProgramTemplates.template("fivebyfive")!
        box.vm.startProgram(t, now: TestBox.daysAgo(30))
        #expect(box.vm.activeRoutineName == "5×5 fuerza" && box.vm.scheduleMode == .sequence)
        #expect(box.vm.getExercise(by: squat.id)?.totalSets == 5 && box.vm.getExercise(by: squat.id)?.repetitions == 5,
                "reutiliza tu sentadilla con las series del programa")
        #expect(box.vm.programWeek()?.index == 0)
        // Nueve sesiones = semana 4, la de descarga.
        for ago in stride(from: 27, through: 3, by: -3) {
            done(box, .monday, on: TestBox.daysAgo(ago), squat.id)
        }
        #expect(box.vm.programWeek()?.index == 3 && box.vm.programWeek()?.week.deload == true)
        box.vm.syncProgramWeek()
        #expect(box.vm.getExercise(by: squat.id)?.totalSets == 3, "descarga: dos series menos")
        let s = box.vm.suggestion(for: box.vm.getExercise(by: squat.id)!, recovery: nil)
        #expect(s?.trend == .down && s?.weight == 53.75, "90 % de 60 kg redondeado a 1,25")
        box.vm.endProgram()
        #expect(box.vm.activeProgram == nil)
        #expect(box.vm.getExercise(by: squat.id)?.totalSets == 3 && box.vm.getExercise(by: squat.id)?.repetitions == 8,
                "vuelve a como estaba")
    }

    @Test func templatesAreValid() {
        for t in ProgramTemplates.all {
            #expect(t.sessions.count == t.slots.count, "\(t.name): huecos")
            #expect(Set(t.slots).count == t.slots.count)
            for item in t.sessions.flatMap(\.items) {
                #expect(ExerciseCatalog.entry(named: item.name) != nil, "\(t.name): \(item.name) no está en el catálogo")
            }
        }
        let home = EquipmentProfile.presets.first { $0.id == EquipmentProfile.homeId }!
        var p = TrainingProfile(); p.goal = .fatLoss; p.level = .beginner; p.daysPerWeek = 3
        #expect(ProgramTemplates.recommended(for: p, equipment: home).first?.fits(home) == true)
        let none = EquipmentProfile.presets.first { $0.id == EquipmentProfile.bodyweightId }!
        #expect(ProgramTemplates.recommended(for: p, equipment: none).first?.id == "bodyweight")
    }
}

// MARK: - Tramo 4b: circuitos, AMRAP, EMOM y el reloj de intervalos

@Suite(.serialized) @MainActor
struct Tramo4bTests {

    @Test func circuitRestsAtTheEndOfTheRound() {
        let box = TestBox(); defer { box.tearDown() }
        let (_, a) = box.add("Sentadilla", sets: 3, weight: 60, rest: 30, on: .monday)
        let (_, b) = box.add("Flexiones", sets: 3, weight: 0, rest: 30, on: .monday)
        box.vm.setSupersetGroup(0, for: a.id, in: .monday)
        box.vm.setSupersetGroup(0, for: b.id, in: .monday)
        box.vm.setBlock(BlockSettings(kind: .circuit, restBetweenRounds: 120), .monday, 0)
        box.vm.completeSet(for: a.id, in: .monday)
        #expect(!box.vm.timerActive, "entre ejercicios del circuito no se descansa")
        box.vm.completeSet(for: b.id, in: .monday)
        #expect(box.vm.timerActive && box.vm.currentTimerDuration == 120, "al cerrar la vuelta, el descanso del circuito")
        box.vm.stopTimer(silent: true)
    }

    @Test func amrapLogsRoundsAndClosesTheBlock() {
        let box = TestBox(); defer { box.tearDown() }
        let (_, a) = box.add("Burpees", sets: 5, weight: 0, reps: 10, on: .monday)
        let (_, b) = box.add("Sentadilla sin peso", sets: 5, weight: 0, reps: 15, on: .monday)
        let (_, c) = box.add("Plancha", sets: 3, weight: 0, on: .monday)
        box.vm.setSupersetGroup(1, for: a.id, in: .monday)
        box.vm.setSupersetGroup(1, for: b.id, in: .monday)
        box.vm.setBlock(BlockSettings(kind: .amrap, minutes: 8), .monday, 1)
        #expect(box.vm.blockPhases(.monday, 1).map(\.seconds) == [480])
        box.vm.logRound(.monday, 1)
        box.vm.logRound(.monday, 1)
        let recs = box.vm.blockMembers(.monday, 1)
        #expect(recs.allSatisfy { $0.setLogs.count == 2 && $0.completedSets == 2 })
        #expect(recs.last?.setLogs.last?.reps == 15)
        #expect(box.vm.nextRecord(in: .monday)?.id == a.id, "sin cerrar, sigue tocando el bloque")
        box.vm.closeBlock(.monday, 1)
        #expect(box.vm.nextRecord(in: .monday)?.id == c.id, "cerrado: pasa a lo siguiente")
        #expect(box.vm.blockMembers(.monday, 1).allSatisfy { $0.completedSets == $0.setLogs.count }, "las series son las hechas")
    }

    @Test func emomRotatesExercises() {
        let box = TestBox(); defer { box.tearDown() }
        let (_, a) = box.add("Swing con kettlebell", sets: 5, weight: 16, reps: 15, on: .monday)
        let (_, b) = box.add("Flexiones", sets: 5, weight: 0, reps: 10, on: .monday)
        box.vm.setSupersetGroup(0, for: a.id, in: .monday)
        box.vm.setSupersetGroup(0, for: b.id, in: .monday)
        box.vm.setBlock(BlockSettings(kind: .emom, minutes: 5), .monday, 0)
        #expect(box.vm.blockPhases(.monday, 0).map(\.name) == ["Swing con kettlebell", "Flexiones", "Swing con kettlebell", "Flexiones", "Swing con kettlebell"])
    }

    @Test func intervalEngineFollowsTheWallClock() {
        let e = IntervalEngine()
        var changes: [Int] = []
        var ended = false
        e.onPhaseChange = { _, i in changes.append(i) }
        e.onFinish = { ended = true }
        e.load([.init(name: "Calienta", seconds: 10, kind: .warmup), .init(name: "Trabajo", seconds: 20, kind: .work),
                .init(name: "Descanso", seconds: 10, kind: .rest)])
        let t0 = Date(timeIntervalSince1970: 1_000_000)
        e.start(now: t0)
        e.tick(now: t0.addingTimeInterval(5))
        #expect(e.index == 0 && e.remaining == 5)
        // La app estuvo 25 s en el fondo: salta dos fases de golpe.
        e.tick(now: t0.addingTimeInterval(32))
        #expect(e.index == 2 && e.remaining == 8)
        e.pause(now: t0.addingTimeInterval(33))
        e.tick(now: t0.addingTimeInterval(100))
        #expect(e.index == 2 && e.remaining == 7, "en pausa no corre")
        e.start(now: t0.addingTimeInterval(100))
        e.tick(now: t0.addingTimeInterval(108))
        #expect(ended && e.finished && changes == [0, 1, 2])
        #expect(Int(e.elapsed(now: t0.addingTimeInterval(108))) == 40, "sin contar la pausa")
    }
}

// MARK: - Tramo 5: hora límite, «hoy me cuesta», experimentos

@Suite(.serialized) @MainActor
struct Tramo5Tests {

    /// Lunes: sentadilla (principal), press, curl y elevaciones; 4 series de 2 min cada una.
    func monday(_ box: TestBox) -> [String: WorkoutExercise] {
        var out: [String: WorkoutExercise] = [:]
        for n in ["Sentadilla", "Press de banca", "Curl con barra", "Elevaciones laterales"] {
            out[n] = box.add(n, sets: 4, weight: 40, reps: 10, rest: 90, on: .monday).1
        }
        return out
    }

    @Test func estimateUsesRealGaps() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, _) = box.add("Press", sets: 3, weight: 60, rest: 90, on: .monday)
        #expect(box.vm.secondsPerSet(ex) == 130, "sin historial: descanso + 10 reps × 3 s + 10")
        var rec = WorkoutExercise(exerciseId: ex.id)
        let t = TestBox.daysAgo(2).addingTimeInterval(3600 * 18)
        rec.setLogs = (0..<5).map { SetLog(reps: 8, weight: 60, date: t.addingTimeInterval(Double($0) * 200)) }
        rec.completedSets = 5
        box.vm.workoutHistory[TestBox.daysAgo(2)] = [.monday: [rec]]
        #expect(box.vm.secondsPerSet(ex) == 200, "mediana de los huecos de verdad")
    }

    @Test func deadlineTrimsByPriority() {
        let box = TestBox(); defer { box.tearDown() }
        let r = monday(box)
        let now = Date()
        let full = box.vm.remainingSeconds(.monday)
        // Con tiempo de sobra no se toca nada.
        #expect(box.vm.timePlan(for: .monday, until: now.addingTimeInterval(full + 600), now: now).cuts.isEmpty)
        // Un poco justo: primero una serie menos en los aislamientos.
        let tight = box.vm.timePlan(for: .monday, until: now.addingTimeInterval(full - 200), now: now)
        #expect(tight.fits)
        #expect(tight.cuts.allSatisfy { $0.name == "Curl con barra" || $0.name == "Elevaciones laterales" })
        #expect(tight.cuts.allSatisfy { $0.to == 3 })
        // Muy justo: fuera aislamientos, pero la sentadilla nunca se toca.
        let short = box.vm.timePlan(for: .monday, until: now.addingTimeInterval(900), now: now)
        #expect(short.cuts.contains { $0.name == "Elevaciones laterales" && $0.to == 0 })
        #expect(!short.cuts.contains { $0.name == "Sentadilla" })
        box.vm.applyTimePlan(short, day: .monday, deadline: now.addingTimeInterval(900))
        #expect(box.vm.sessionDeadline != nil)
        #expect(box.vm.dailyWorkoutRecords[.monday]?.first { $0.id == r["Elevaciones laterales"]!.id }?.targetSets == 0)
        #expect(box.vm.nextRecord(in: .monday)?.id == r["Sentadilla"]!.id)
        #expect(box.vm.totalSets(for: .monday) < 16)
        // Mañana todo vuelve.
        box.vm.adoptSession(date: TestBox.daysAgo(1))
        box.vm.ensureSession()
        #expect(box.vm.dailyWorkoutRecords[.monday]?.allSatisfy { $0.targetSets == nil } == true)
        #expect(box.vm.totalSets(for: .monday) == 16)
    }

    @Test func lightSessionKeepsWhatIsDone() {
        let box = TestBox(); defer { box.tearDown() }
        let r = monday(box)
        box.vm.completeSet(for: r["Curl con barra"]!.id, in: .monday)
        box.vm.stopTimer(silent: true)
        box.vm.lightenSession(.monday)
        let recs = box.vm.dailyWorkoutRecords[.monday]!
        #expect(recs.first { $0.id == r["Sentadilla"]!.id }?.targetSets == 3, "una serie menos")
        #expect(recs.first { $0.id == r["Elevaciones laterales"]!.id }?.targetSets == 0, "aislamiento sin empezar, fuera")
        #expect(recs.first { $0.id == r["Curl con barra"]!.id }?.targetSets == 3, "empezado: se queda, con una menos")
        #expect(box.vm.isLightToday)
        box.vm.clearSessionTargets(.monday)
        #expect(!box.vm.isLightToday && box.vm.totalSets(for: .monday) == 16)
    }

    @Test func lightDaysDontCountAsStagnation() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, _) = box.add("Press", sets: 3, weight: 60, reps: 8, on: .monday)
        func session(_ ago: Int, reps: Int) {
            var rec = WorkoutExercise(exerciseId: ex.id)
            rec.setLogs = (0..<3).map { SetLog(reps: reps, weight: 60, rpe: 8, date: TestBox.daysAgo(ago).addingTimeInterval(3600 * 18 + Double($0) * 180)) }
            rec.completedSets = 3
            box.vm.workoutHistory[TestBox.daysAgo(ago)] = [.monday: [rec]]
        }
        session(7, reps: 5)
        session(3, reps: 5)
        #expect(box.vm.suggestion(for: ex, recovery: nil)?.trend == .down, "dos sesiones sin llegar: baja")
        UserDefaultsHelper.markLight(box, TestBox.daysAgo(3))
        #expect(box.vm.suggestion(for: ex, recovery: nil)?.trend != .down, "si una fue ligera, no cuenta")
    }

    @Test func experimentVerdictIsHonest() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, _) = box.add("Press", sets: 3, weight: 60, reps: 8, on: .monday)
        var e = ExperimentsView.newDraft(.rest, exercise: ex.id)
        e.start = TestBox.daysAgo(40)
        box.vm.startExperiment(e)
        func session(_ ago: Int, weight: Double) {
            var rec = WorkoutExercise(exerciseId: ex.id)
            rec.setLogs = [SetLog(reps: 5, weight: weight, date: TestBox.daysAgo(ago).addingTimeInterval(3600 * 18))]
            rec.completedSets = 1
            box.vm.workoutHistory[TestBox.daysAgo(ago)] = [.monday: [rec]]
        }
        session(30, weight: 100)
        session(27, weight: 90)
        #expect(box.vm.verdict(e).hasPrefix("Aún no se puede saber"))
        #expect(box.vm.condition(e, on: TestBox.daysAgo(30)) == "A" && box.vm.condition(e, on: TestBox.daysAgo(27)) == "B")
        // A: 100, 101, 99, 100 · B: 90, 91, 89, 90 → diferencia clara.
        for (i, w) in [101.0, 91, 99, 89, 100, 90].enumerated() { session(24 - i * 3, weight: w) }
        let r = box.vm.result(e)
        #expect(r.a.count == 4 && r.b.count == 4 && r.clear)
        #expect(box.vm.verdict(e).contains("Descanso de 3 min"))
        // Hoy: 8 sesiones antes → toca A, y el descanso del press es el largo.
        #expect(box.vm.condition(e, on: Date()) == "A")
        #expect(box.vm.experimentRest(for: ex) == 180)
        // Ruido: mismas medias con mucha variación → no hay ganador.
        var noisy = ExperimentsView.newDraft(.custom)
        noisy.metric = .e1rm; noisy.exerciseId = ex.id; noisy.start = TestBox.daysAgo(40)
        let rr = ExperimentResult(a: [100, 80, 120, 95], b: [98, 115, 82, 101])
        #expect(!rr.clear)
        _ = noisy
    }
}

@MainActor
enum UserDefaultsHelper {
    /// Marca un día como «ligero» como lo haría la app.
    static func markLight(_ box: TestBox, _ date: Date) {
        var days = (box.defaults.array(forKey: "LightDays") as? [Date]) ?? []
        days.append(Calendar.current.startOfDay(for: date))
        box.defaults.set(days, forKey: "LightDays")
    }
}

// MARK: - Tramo 6: voz

@MainActor
struct VoiceParserTests {
    typealias P = VoiceCommandParser

    @Test(arguments: [
        ("80 kilos por 8", VoiceCommand.set(weight: 80, unit: .kg, reps: 8, rpe: nil)),
        ("ochenta kilos por ocho", .set(weight: 80, unit: .kg, reps: 8, rpe: nil)),
        ("Ochenta y dos y medio por seis, RPE nueve", .set(weight: 82.5, unit: nil, reps: 6, rpe: 9)),
        ("8 repeticiones RPE 9", .set(weight: nil, unit: nil, reps: 8, rpe: 9)),
        ("100 libras 5 reps", .set(weight: 100, unit: .lb, reps: 5, rpe: nil)),
        ("62,5 por 10", .set(weight: 62.5, unit: nil, reps: 10, rpe: nil)),
        ("ciento veinte por cinco", .set(weight: 120, unit: nil, reps: 5, rpe: nil)),
        ("80x8", .set(weight: 80, unit: nil, reps: 8, rpe: nil)),
        ("12 reps con 20 kg", .set(weight: 20, unit: .kg, reps: 12, rpe: nil)),
        ("eighty pounds times eight", .set(weight: 80, unit: .lb, reps: 8, rpe: nil)),
        ("one hundred and five kilos for five", .set(weight: 105, unit: .kg, reps: 5, rpe: nil)),
        ("vuitanta quilos per vuit", .set(weight: 80, unit: .kg, reps: 8, rpe: nil)),
        ("vint-i-dos i mig per dotze", .set(weight: 22.5, unit: nil, reps: 12, rpe: nil)),
        ("hecho", .done), ("Hecha", .done), ("done", .done), ("Fet!", .done),
        ("siguiente", .next), ("next", .next), ("Següent", .next),
        ("deshacer", .undo), ("desfés", .undo),
        ("descanso", .rest),
        ("está ocupada", .busy), ("Està ocupada", .busy),
        ("hola qué tal", .unknown), ("", .unknown),
    ] as [(String, VoiceCommand)])
    func parses(_ input: String, _ expected: VoiceCommand) {
        #expect(P.parse(input) == expected, "«\(input)»")
    }

    @Test func languageDisambiguates() {
        #expect(P.parse("set done", language: "en") == .done, "en inglés «set» no es 7")
        #expect(P.parse("set per deu", language: "ca") == .set(weight: 7, unit: nil, reps: 10, rpe: nil), "en catalán sí")
        #expect(P.parse("once repeticiones") == .set(weight: nil, unit: nil, reps: 11, rpe: nil))
    }
}

// MARK: - Tramo 7: intervalos y movilidad

@Suite(.serialized) @MainActor
struct Tramo7Tests {

    @Test func tabataPhases() {
        let t = IntervalPlan.presets.first { $0.name == "Tabata" }!
        let ph = t.phases
        #expect(ph.filter { $0.kind == .work }.count == 8)
        #expect(ph.filter { $0.kind == .rest }.count == 7, "sin descanso tras la última")
        #expect(ph.first?.kind == .warmup && ph.last?.kind == .cooldown)
        #expect(t.totalSeconds == ph.reduce(0) { $0 + $1.seconds })
        #expect(t.workSeconds == 160)
        let blocks = IntervalPlan(name: "x", work: 40, rest: 20, rounds: 3, blocks: 2, blockRest: 90)
        #expect(blocks.phases.map(\.seconds) == [40, 20, 40, 20, 40, 90, 40, 20, 40, 20, 40])
        #expect(blocks.totalSeconds == 410)
    }

    @Test func hiitCountsTodayAndLeavesTomorrow() {
        let box = TestBox(); defer { box.tearDown() }
        _ = box.add("Press", sets: 3, weight: 60, on: .monday)
        box.vm.trainingDay = .monday
        let start = Date().addingTimeInterval(-600)
        box.vm.logTimedSession(name: "Intervalos · Tabata", group: "Cardio", icon: "timer",
                               workIntervals: Array(repeating: 20, count: 8), start: start, end: Date())
        let rec = box.vm.dailyWorkoutRecords[.monday]!.last!
        #expect(box.vm.getExercise(by: rec.exerciseId)?.name == "Intervalos · Tabata")
        #expect(rec.setLogs.count == 8 && rec.completedSets == 8)
        #expect(box.vm.hasWorkoutForDate(Date()), "cuenta como entreno de hoy")
        #expect(box.vm.nextRecord(in: .monday)?.exerciseId != rec.exerciseId, "no se propone como pendiente")
        box.vm.adoptSession(date: TestBox.daysAgo(1))
        box.vm.ensureSession()
        #expect(box.vm.dailyWorkoutRecords[.monday]!.count == 1, "mañana ya no está en la plantilla")
        #expect(box.vm.workoutHistory[TestBox.daysAgo(1)]?[.monday]?.count == 2, "pero sí en el historial")
    }

    @Test func mobilityLinks() {
        let box = TestBox(); defer { box.tearDown() }
        let r = box.vm.mobilityRoutines.first!
        #expect(r.phases.filter { $0.kind == .work }.count == r.items.count)
        box.vm.setWarmupLink(r, for: .friday)
        #expect(box.vm.warmupLink(.friday)?.id == r.id)
        box.vm.setWarmupLink(nil, for: .friday)
        #expect(box.vm.warmupLink(.friday) == nil)
        for it in MobilityRoutine.presets.flatMap(\.items) {
            #expect(ExerciseCatalog.entry(named: it.name) != nil, "\(it.name) en el catálogo")
        }
    }
}

// MARK: - Tramo 8: nutrición conectada con Dieta

/// Respuestas grabadas: el servidor de Dieta sin red.
nonisolated final class DietaStub: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var routes: [String: (Int, String)] = [:]
    nonisolated(unsafe) static var requests: [URLRequest] = []

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        var req = request
        if req.httpBody == nil, let stream = req.httpBodyStream {
            stream.open(); var data = Data(); var buf = [UInt8](repeating: 0, count: 4096)
            while stream.hasBytesAvailable { let n = stream.read(&buf, maxLength: 4096); if n <= 0 { break }; data.append(buf, count: n) }
            stream.close(); req.httpBody = data
        }
        Self.requests.append(req)
        let key = "\(request.httpMethod ?? "GET") \(request.url?.path ?? "")"
        let (code, body) = Self.routes[key] ?? (404, #"{"error":"no"}"#)
        let resp = HTTPURLResponse(url: request.url!, statusCode: code, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}

    static var session: URLSession {
        let c = URLSessionConfiguration.ephemeral
        c.protocolClasses = [DietaStub.self]
        return URLSession(configuration: c)
    }
}

@Suite(.serialized) @MainActor
struct Tramo8Tests {

    /// Un plan de la semana de hoy: desayuno y cena del día de hoy.
    func planJSON() -> String {
        var cal = Calendar(identifier: .gregorian); cal.firstWeekday = 2
        let monday = cal.dateInterval(of: .weekOfYear, for: Date())!.start
        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let wd = DietaPlan.weekday(of: Date())
        return """
        {"id":"p1","userId":"u","startDate":"\(f.string(from: monday))","createdAt":"2026-09-07T08:12:33.120Z","cost":10,
         "meals":[
          {"id":"m2","planId":"p1","recipeId":"r2","weekday":\(wd),"slot":"cena","grams":300,"eaten":false,
           "recipe":{"id":"r2","title":"Merluza con patata","kcal":100,"protein":12,"fiber":1,"photoUrl":null}},
          {"id":"m1","planId":"p1","recipeId":"r1","weekday":\(wd),"slot":"desayuno","grams":200,"eaten":true,
           "recipe":{"id":"r1","title":"Porridge","kcal":150,"protein":5,"fiber":3,"photoUrl":"p.jpg"}},
          {"id":"m3","planId":"p1","recipeId":"r3","weekday":\((wd + 1) % 7),"slot":"comida","grams":400,"eaten":false,
           "recipe":{"id":"r3","title":"Lentejas","kcal":120,"protein":8}}],
         "days":[{"weekday":\(wd),"targets":{"kcal":2100,"protein":136,"isGymDay":true},"kcal":2000,"protein":130,"fiber":30,"cobertura":0.95}]}
        """
    }

    func store() -> Nutrition {
        let suite = "nutrition-\(UUID().uuidString)"
        let n = Nutrition(defaults: UserDefaults(suiteName: suite)!)
        n.session = DietaStub.session
        n.baseURL = "https://dieta.test"
        DietaStub.requests = []
        return n
    }

    @Test func decodesThePlanAndComputesToday() throws {
        let plan = try DietaClient.decoder.decode(DietaPlan.self, from: Data(planJSON().utf8))
        let today = plan.meals(on: Date())
        #expect(today.map(\.slot) == ["desayuno", "cena"], "ordenado por comida del día")
        #expect(today[1].kcal == 300 && today[1].protein == 36, "300 g × 100 kcal/100 g")
        #expect(plan.targets(on: Date())?.kcal == 2100)
        #expect(DietaPlan.weekday(of: Date(timeIntervalSince1970: 0)) == 4, "1-ene-1970 fue jueves")
    }

    @Test func connectRefreshAndMarkEaten() async {
        let n = store()
        DietaStub.routes = ["POST /auth/login": (200, #"{"token":"t0k","userId":"u"}"#),
                            "GET /plan/current": (200, planJSON()),
                            "PATCH /plan/meals/m2": (200, #"{"id":"m2","eaten":true}"#),
                            "GET /weight": (200, #"[{"id":"w","date":"2026-09-01T00:00:00.000Z","kg":82.4}]"#)]
        #expect(await n.connect(email: "a@b.c", password: "x"))
        #expect(n.connected && n.meals().count == 2)
        #expect(n.eaten().kcal == 300, "solo el desayuno está comido")
        n.addLog(FoodLog(name: "Plátano", kcal: 105, protein: 1.3))
        n.addWater(250); n.addWater(500); n.addWater(-250)
        #expect(n.water() == 500)
        #expect(Int(n.eaten().kcal) == 405)
        await n.setEaten(n.meals()[1], true)
        #expect(n.meals()[1].eaten)
        let patch = DietaStub.requests.first { $0.httpMethod == "PATCH" }
        #expect(patch?.value(forHTTPHeaderField: "Authorization") == "Bearer t0k")
        #expect(String(data: patch?.httpBody ?? Data(), encoding: .utf8)?.contains(#""eaten":true"#) == true)
        // Peso de Dieta → ChamaFit, sin pisar lo que ya hay.
        let box = TestBox(); defer { box.tearDown() }
        let key = Calendar.current.startOfDay(for: try! DietaClient.decoder.decode([DietaWeight].self,
                     from: Data(#"[{"date":"2026-09-01T00:00:00.000Z","kg":82.4}]"#.utf8))[0].date)
        await n.pullWeights(into: box.vm)
        #expect(box.vm.bodyWeightHistory[key] == 82.4)
    }

    @Test func errorsAreUnderstandable() async {
        let n = store()
        DietaStub.routes = ["POST /auth/login": (401, #"{"error":"Credenciales incorrectas"}"#)]
        #expect(!(await n.connect(email: "a", password: "b")))
        #expect(n.lastError == DietaError.unauthorized.errorDescription)
        // Sin plan esta semana: no es un error.
        n.token = "t"
        DietaStub.routes = ["GET /plan/current": (404, #"{"error":"No hay plan para esta semana"}"#)]
        await n.refresh()
        #expect(n.plan == nil && n.lastError == nil)
    }

    @Test func productsFromDietaAndOpenFoodFacts() {
        let dieta = #"{"enCatalogo":true,"product":{"name":"Yogur natural"},"nutrition":{"brands":"Hacendado","kcal":61,"protein":3.5},"verdict":null}"#
        let d = DietaClient.parseDietaProduct(Data(dieta.utf8), ean: "848")
        #expect(d == FoodProduct(ean: "848", name: "Yogur natural", brand: "Hacendado", kcal: 61, protein: 3.5, source: "Dieta"))
        #expect(DietaClient.parseDietaProduct(Data(#"{"enCatalogo":true,"product":{"name":"x"},"nutrition":null}"#.utf8), ean: "1") == nil)
        let off = #"{"status":1,"product":{"product_name":"Galletas","brands":"X","nutriments":{"energy_100g":2092,"proteins_100g":6}}}"#
        let o = OpenFoodFacts.parse(Data(off.utf8), ean: "7")
        #expect(o?.name == "Galletas" && Int(o!.kcal) == 500, "de kJ a kcal")
        #expect(OpenFoodFacts.parse(Data(#"{"status":0}"#.utf8), ean: "7") == nil)
    }
}

// MARK: - Tramo 9: amigos y retos (lo que no depende de iCloud)

@Suite(.serialized) @MainActor
struct Tramo9Tests {

    @Test func challengeScoresFromHistory() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, _) = box.add("Press", sets: 3, weight: 50, reps: 10, on: .monday)
        for ago in [1, 2, 3, 6] {
            var rec = WorkoutExercise(exerciseId: ex.id)
            rec.setLogs = (0..<3).map { SetLog(reps: 10, weight: 50, date: TestBox.daysAgo(ago).addingTimeInterval(3600 * 18 + Double($0) * 120)) }
            rec.completedSets = 3
            box.vm.workoutHistory[TestBox.daysAgo(ago)] = [.monday: [rec]]
        }
        let start = TestBox.daysAgo(5), end = Date()
        #expect(box.vm.challengeScore(.sessions, from: start, to: end) == 3, "solo lo que cae dentro del reto")
        #expect(box.vm.challengeScore(.sets, from: start, to: end) == 9)
        #expect(box.vm.challengeScore(.volume, from: start, to: end) == 4500)
        #expect(box.vm.challengeScore(.streak, from: TestBox.daysAgo(7), to: end) == 3)
    }

    @Test func codesAndRanking() {
        let codes = (0..<200).map { _ in Social.makeCode() }
        #expect(codes.allSatisfy { $0.count == 6 && !$0.contains("0") && !$0.contains("O") && !$0.contains("1") && !$0.contains("I") })
        let ranked = Social.rank([.init(profileId: "a", name: "Ana", score: 3), .init(profileId: "b", name: "Bea", score: 5),
                                  .init(profileId: "c", name: "Alba", score: 3)])
        #expect(ranked.map(\.name) == ["Bea", "Alba", "Ana"])
    }

    @Test func summaryRespectsPrivacy() {
        let box = TestBox(); defer { box.tearDown() }
        let s = Social(defaults: box.defaults)
        let code = s.myCode
        #expect(s.myCode == code && s.myId == s.myId, "estables")
        var p = SharePrefs(); p.volume = false; p.records = false; p.streak = false
        s.prefs = p
        let mine = s.mySummary(box.vm, name: "Jordi")
        #expect(mine.weekSessions != nil && mine.weekVolume == nil && mine.streak == nil && mine.records == nil)
        #expect(!Social.available, "en pruebas iCloud no se toca")
    }
}

// MARK: - Tramo 10: calendario del iPhone

@Suite(.serialized) @MainActor
struct Tramo10Tests {

    func weekMonday() -> Date {
        var cal = Calendar(identifier: .gregorian); cal.firstWeekday = 2
        return Calendar.current.startOfDay(for: cal.dateInterval(of: .weekOfYear, for: Date().addingTimeInterval(7 * 86_400))!.start)
    }

    @Test func fixedWeekPlan() {
        let box = TestBox(); defer { box.tearDown() }
        for d in [WorkoutDay.monday, .wednesday, .friday] { _ = box.add("E\(d.rawValue)", sets: 3, weight: 40, on: d) }
        let plan = box.vm.calendarPlan(from: weekMonday(), days: 14)
        #expect(plan.count == 6, "tres por semana, dos semanas")
        #expect(plan.first?.slot == .monday && plan.first?.title == "Lunes")
        #expect(plan.allSatisfy { $0.minutes >= 10 })
    }

    @Test func sequenceSpreadsOverTrainingDays() {
        let box = TestBox(); defer { box.tearDown() }
        for d in [WorkoutDay.monday, .thursday] { _ = box.add("E\(d.rawValue)", sets: 3, weight: 40, on: d) }
        box.vm.scheduleMode = .sequence
        let plan = box.vm.calendarPlan(from: weekMonday(), days: 14)
        #expect(plan.map(\.title) == ["Sesión A", "Sesión B", "Sesión A", "Sesión B"])
    }

    @Test func estimateOfAWholeSession() {
        let box = TestBox(); defer { box.tearDown() }
        _ = box.add("Press", sets: 4, weight: 60, reps: 10, rest: 90, on: .monday)
        // 4 × 130 s − 65 + 60 = 515 s ≈ 9 min → mínimo 10.
        #expect(box.vm.estimatedSessionMinutes(.monday) == 10)
        _ = box.add("Remo", sets: 4, weight: 60, reps: 10, rest: 90, on: .monday)
        #expect(box.vm.estimatedSessionMinutes(.monday) == 17)
    }
}

// MARK: - Tramo 12: coach que actúa

@Suite(.serialized) @MainActor
struct Tramo12Tests {

    @Test func streamWithToolUseIsReassembled() {
        let lines = [
            #"data: {"type":"message_start","message":{"id":"m"}}"#,
            #"data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}"#,
            #"data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Miro tu "}}"#,
            #"data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"historial."}}"#,
            #"data: {"type":"content_block_stop","index":0}"#,
            #"data: {"type":"content_block_start","index":1,"content_block":{"type":"tool_use","id":"tu_1","name":"exercise_stats","input":{}}}"#,
            #"data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"{\"name\": \"Pr"}}"#,
            #"data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"ess\"}"}}"#,
            #"data: {"type":"content_block_stop","index":1}"#,
            #"data: {"type":"message_delta","delta":{"stop_reason":"tool_use"}}"#,
            #"data: {"type":"message_stop"}"#,
        ]
        var acc = SSEAccumulator()
        let text = lines.compactMap { acc.feed($0) }.joined()
        #expect(text == "Miro tu historial.")
        #expect(acc.stopReason == "tool_use" && acc.done)
        #expect(acc.toolCalls.count == 1 && acc.toolCalls[0].name == "exercise_stats" && acc.toolCalls[0].input["name"] as? String == "Press")
        #expect(acc.assistantContent.count == 2 && acc.assistantContent[1]["id"] as? String == "tu_1")
    }

    @Test func toolsAnswerFromData() {
        let box = TestBox(); defer { box.tearDown() }
        let (ex, _) = box.add("Press de banca", sets: 3, weight: 60, reps: 8, on: .monday)
        var ex2 = ex; ex2.setupNote = "Asiento en el 4"; box.vm.updateBaseExercise(ex2)
        var rec = WorkoutExercise(exerciseId: ex.id)
        rec.setLogs = [SetLog(reps: 8, weight: 62.5, rpe: 8, date: TestBox.daysAgo(2).addingTimeInterval(3600 * 18))]
        rec.completedSets = 1
        box.vm.workoutHistory[TestBox.daysAgo(2)] = [.monday: [rec]]
        box.vm.sessionNotes[TestBox.daysAgo(2)] = "Me molestaba el hombro"
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        let h = box.vm.runCoachTool("history", ["from": f.string(from: TestBox.daysAgo(7)), "to": f.string(from: Date())])
        #expect(h.contains("Press de banca 1 series") && h.contains("62,5 kg × 8") && h.contains("hombro"))
        #expect(box.vm.runCoachTool("exercise_stats", ["name": "press de banca"]).contains("Récord: 62,5 kg"))
        #expect(box.vm.runCoachTool("search_notes", ["query": "asiento"]).contains("Asiento en el 4"))
        #expect(box.vm.runCoachTool("search_notes", ["query": "hombro"]).contains("Me molestaba"))
        #expect(box.vm.runCoachTool("consistency_report", [:]).contains("Racha actual"))
    }

    @Test func proposalsAreValidatedAppliedAndUndone() {
        let box = TestBox(); defer { box.tearDown() }
        let (bench, _) = box.add("Press de banca", sets: 3, weight: 60, reps: 8, on: .monday)
        _ = box.add("Curl con barra", sets: 3, weight: 20, reps: 10, on: .monday)
        let answer = box.vm.runCoachTool("propose_changes", ["reason": "Más volumen de pecho", "changes": [
            ["kind": "substitute", "day": "Lunes", "exercise": "Curl con barra", "new_exercise": "Curl martillo"],
            ["kind": "sets_reps", "exercise": "Press de banca", "sets": 5, "reps": 5],
            ["kind": "add", "day": "Lunes", "exercise": "Cruce de poleas", "sets": 3, "reps": 12],
            ["kind": "remove", "exercise": "Ejercicio fantasma"],
        ]])
        #expect(answer.contains("3 cambios") && answer.contains("fantasma"))
        guard let pr = CoachProposals.shared.latest else { Issue.record("sin propuesta"); return }
        #expect(box.vm.getExercise(by: bench.id)?.totalSets == 3, "proponer no aplica nada")
        let undo = box.vm.apply(pr)
        let monday = box.vm.dailyWorkoutRecords[.monday]!.compactMap { box.vm.getExercise(by: $0.exerciseId)?.name }
        #expect(monday == ["Press de banca", "Curl martillo", "Cruce de poleas"])
        #expect(box.vm.getExercise(by: bench.id)?.totalSets == 5 && box.vm.getExercise(by: bench.id)?.repetitions == 5)
        box.vm.undoCoach(undo!)
        let back = box.vm.dailyWorkoutRecords[.monday]!.compactMap { box.vm.getExercise(by: $0.exerciseId)?.name }
        #expect(back == ["Press de banca", "Curl con barra"], "deshacer lo deja como estaba")
        #expect(box.vm.getExercise(by: bench.id)?.totalSets == 3)
        CoachProposals.shared.latest = nil
    }

    @Test func pastedRoutineCreatesWhatIsMissing() {
        let box = TestBox(); defer { box.tearDown() }
        let g = GeneratedRoutine(name: "De WhatsApp", notes: "", days: [
            .init(day: "Lunes", label: "Torso", exercises: [.init(name: "press de banca", sets: 4, reps: 8, restSeconds: 120),
                                                             .init(name: "Remo Kroc", sets: 3, reps: 12, restSeconds: 90)]),
            .init(day: "Jueves", label: "Pierna", exercises: [.init(name: "Sentadilla", sets: 5, reps: 5, restSeconds: 180)])])
        #expect(box.vm.applyParsedRoutine(g, named: "") == 3)
        #expect(box.vm.activeRoutineName == "De WhatsApp")
        let kroc = box.vm.availableExercises.first { $0.name == "Remo Kroc" }
        #expect(kroc?.totalSets == 3 && kroc?.repetitions == 12 && kroc?.restDuration == 90, "el que no está en el catálogo se crea")
        #expect(box.vm.label(for: .thursday) == "Pierna")
        #expect(box.vm.availableExercises.filter { ExerciseLibrary.fold($0.name) == "press de banca" }.count == 1)
    }
}
