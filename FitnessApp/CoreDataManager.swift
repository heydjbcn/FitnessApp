//
//  CoreDataManager.swift - VERSIÓN CORREGIDA SIN WARNINGS
//  FitnessApp
//

import CoreData
import Foundation
import CloudKit
import Combine

/// Maneja todas las operaciones de Core Data con soporte para CloudKit - OPTIMIZADO Y CORREGIDO
class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    @Published var isReady = false
    @Published var migrationProgress: Double = 0.0
    @Published var migrationStatus: String = ""
    
    // ✅ Container con CloudKit OPTIMIZADO
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "FitnessApp")
        
        // Configurar CloudKit
        guard let storeDescription = container.persistentStoreDescriptions.first else {
            fatalError("No store description found")
        }
        
        storeDescription.setOption(true as NSNumber,
                                 forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber,
                                 forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        storeDescription.setOption(true as NSNumber,
                                 forKey: NSPersistentStoreFileProtectionKey)
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ Core Data error: \(error)")
                Task { @MainActor [weak self] in
                    self?.isReady = true
                }
            } else {
                print("✅ Core Data container loaded successfully")
                Task { @MainActor [weak self] in
                    self?.isReady = true
                }
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.stalenessInterval = 0.0
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    var container: NSPersistentCloudKitContainer {
        return persistentContainer
    }
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?
    
    private init() {
        setupCloudKitObservers()
    }
    
    /// Guarda contexto principal de forma segura
    func saveContext() async {
        await MainActor.run {
            guard context.hasChanges else { return }
            
            do {
                try context.save()
                print("✅ Context saved successfully")
            } catch {
                print("❌ Failed to save context: \(error)")
                context.rollback()
            }
        }
    }
    
    /// Esperar hasta que Core Data esté listo
    func waitForReady() async {
        while !isReady {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
    }
    
    private func setupCloudKitObservers() {
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleRemoteChange()
            }
        }
    }
    
    @MainActor
    private func handleRemoteChange() {
        print("📡 Remote change detected")
        lastSyncDate = Date()
        context.refreshAllObjects()
    }
}
