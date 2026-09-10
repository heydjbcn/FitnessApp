//
//  AutoBackup.swift
//  ChamaFit
//
//  Copia de seguridad automática una vez por semana en Documentos/Copias
//  (se ven en Archivos › En mi iPhone › ChamaFit). Se guardan las 8 últimas.
//

import Foundation

enum AutoBackup {
    static let keep = 8
    static let interval: TimeInterval = 7 * 86_400

    static var folder: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Copias", isDirectory: true)
    }

    static var lastDate: Date? {
        get { AppDefaults.store.object(forKey: "lastAutoBackup") as? Date }
        set { AppDefaults.store.set(newValue, forKey: "lastAutoBackup") }
    }

    /// Hace la copia si toca (o si `force`). Devuelve el fichero escrito.
    @MainActor @discardableResult
    static func runIfDue(_ vm: WorkoutViewModel, force: Bool = false, now: Date = Date(), in dir: URL? = nil) -> URL? {
        guard force || !AppDefaults.isTesting || dir != nil else { return nil }
        if !force, let last = lastDate, now.timeIntervalSince(last) < interval { return nil }
        guard !vm.availableExercises.isEmpty || !vm.workoutHistory.isEmpty else { return nil }
        let target = dir ?? folder
        do {
            try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
            let url = target.appendingPathComponent("ChamaFit-copia-\(f.string(from: now)).json")
            try vm.backupData().write(to: url, options: .atomic)
            lastDate = now
            prune(target)
            return url
        } catch {
            return nil
        }
    }

    /// Deja solo las `keep` copias más recientes.
    static func prune(_ dir: URL) {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .filter({ $0.lastPathComponent.hasPrefix("ChamaFit-copia-") && $0.pathExtension == "json" }) else { return }
        for old in files.sorted(by: { $0.lastPathComponent > $1.lastPathComponent }).dropFirst(keep) {
            try? fm.removeItem(at: old)
        }
    }
}
