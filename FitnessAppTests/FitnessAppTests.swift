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
