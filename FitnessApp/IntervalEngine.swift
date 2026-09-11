//
//  IntervalEngine.swift
//  ChamaFit
//
//  Reloj por fases (calentamiento, trabajo, descanso, vuelta a la calma)
//  para AMRAP, EMOM y los intervalos HIIT. Va contra el reloj de pared: si
//  la app se va al fondo y vuelve, sigue donde toca.
//

import Foundation
import Combine

@MainActor
final class IntervalEngine: ObservableObject {

    struct Phase: Equatable {
        enum Kind: String { case warmup, work, rest, cooldown }
        var name: String
        var seconds: Int
        var kind: Kind
    }

    @Published private(set) var phases: [Phase] = []
    @Published private(set) var index = 0
    @Published private(set) var running = false
    @Published private(set) var finished = false
    /// Segundos que quedan de la fase (se actualiza con `tick`).
    @Published private(set) var remaining = 0

    private var phaseEnd: Date? = nil
    private var startedAt: Date? = nil
    private var pausedAt: Date? = nil
    private var pausedTotal: TimeInterval = 0
    private var finishedAt: Date? = nil

    /// Cambio de fase (incluida la primera). El segundo parámetro es el índice.
    var onPhaseChange: ((Phase, Int) -> Void)? = nil
    /// Últimos tres segundos de una fase.
    var onCountdown: ((Int) -> Void)? = nil
    var onFinish: (() -> Void)? = nil

    var current: Phase? { phases.indices.contains(index) ? phases[index] : nil }
    var next: Phase? { phases.indices.contains(index + 1) ? phases[index + 1] : nil }
    var totalSeconds: Int { phases.reduce(0) { $0 + $1.seconds } }

    /// Tiempo en marcha (sin pausas).
    func elapsed(now: Date = Date()) -> TimeInterval {
        guard let startedAt else { return 0 }
        let end = finishedAt ?? pausedAt ?? now
        return max(0, end.timeIntervalSince(startedAt) - pausedTotal)
    }

    func load(_ phases: [Phase]) {
        self.phases = phases.filter { $0.seconds > 0 }
        index = 0
        running = false
        finished = false
        phaseEnd = nil
        startedAt = nil
        pausedAt = nil
        pausedTotal = 0
        finishedAt = nil
        remaining = self.phases.first?.seconds ?? 0
    }

    func start(now: Date = Date()) {
        guard !phases.isEmpty, !running, !finished else { return }
        if let pausedAt {
            // Reanudar.
            pausedTotal += now.timeIntervalSince(pausedAt)
            phaseEnd = now.addingTimeInterval(TimeInterval(remaining))
            self.pausedAt = nil
        } else {
            startedAt = now
            phaseEnd = now.addingTimeInterval(TimeInterval(phases[index].seconds))
            onPhaseChange?(phases[index], index)
        }
        running = true
    }

    func pause(now: Date = Date()) {
        guard running else { return }
        tick(now: now)
        running = false
        pausedAt = now
        phaseEnd = nil
    }

    /// Pasa a la siguiente fase ya.
    func skip(now: Date = Date()) {
        guard !finished else { return }
        advance(from: now)
    }

    func stop(now: Date = Date()) {
        if finishedAt == nil { finishedAt = pausedAt ?? now }
        running = false
        finished = true
        phaseEnd = nil
    }

    /// Llamar a menudo (4 veces por segundo): avanza fases y avisa.
    func tick(now: Date = Date()) {
        guard running, let end = phaseEnd else { return }
        var left = Int(ceil(end.timeIntervalSince(now)))
        // Si la app estuvo en el fondo, puede que hayan pasado varias fases.
        var guardCount = 0
        while left <= 0 && running && guardCount < phases.count + 1 {
            let overshoot = now.timeIntervalSince(phaseEnd ?? now)
            advance(from: now.addingTimeInterval(-overshoot))
            guard let e = phaseEnd else { break }
            left = Int(ceil(e.timeIntervalSince(now)))
            guardCount += 1
        }
        if running, left != remaining {
            remaining = max(0, left)
            if (1...3).contains(remaining) { onCountdown?(remaining) }
        }
    }

    private func advance(from moment: Date) {
        if index + 1 < phases.count {
            index += 1
            remaining = phases[index].seconds
            if running || pausedAt == nil {
                phaseEnd = moment.addingTimeInterval(TimeInterval(phases[index].seconds))
            }
            onPhaseChange?(phases[index], index)
        } else {
            remaining = 0
            running = false
            finished = true
            finishedAt = moment
            phaseEnd = nil
            onFinish?()
        }
    }
}
