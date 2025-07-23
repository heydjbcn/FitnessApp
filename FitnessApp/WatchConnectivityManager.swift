import WatchConnectivity
import Foundation
import SwiftUI
import Combine

class WatchConnectivityManager: NSObject, ObservableObject {
    static let instance = WatchConnectivityManager()
    
    @Published var isWatchConnected = false
    @Published var isWatchAppInstalled = false
    
    private override init() {
        super.init()
        
        #if targetEnvironment(simulator)
        print("📱 Simulador detectado - Apple Watch no disponible")
        return
        #endif
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        } else {
            print("⌚️ WCSession no es compatible con este dispositivo")
        }
    }
    
    func sendWorkoutDataToWatch(exercise: String, duration: TimeInterval, calories: Double) {
        guard WCSession.default.isReachable else {
            print("⌚️ Apple Watch no es alcanzable")
            return
        }
        
        let workoutData: [String: Any] = [
            "type": "workout",
            "exercise": exercise,
            "duration": duration,
            "calories": calories,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        WCSession.default.sendMessage(workoutData, replyHandler: nil) { error in
            print("❌ Error enviando entrenamiento al Watch: \(error.localizedDescription)")
        }
    }
    
    func requestHealthDataFromWatch() {
        guard WCSession.default.isReachable else {
            print("⌚️ Apple Watch no es alcanzable")
            return
        }
        
        let request: [String: Any] = [
            "type": "requestHealthData",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        WCSession.default.sendMessage(request, replyHandler: { response in
            DispatchQueue.main.async {
                // Procesar respuesta del Apple Watch
                if let steps = response["steps"] as? Int {
                    print("👣 Pasos del Watch: \(steps)")
                }
                if let heartRate = response["heartRate"] as? Double {
                    print("❤️ Frecuencia cardíaca del Watch: \(heartRate)")
                }
            }
        }) { error in
            print("❌ Error solicitando datos del Watch: \(error.localizedDescription)")
        }
    }
    
    func startWorkoutOnWatch() {
        guard WCSession.default.isReachable else {
            print("⌚️ Apple Watch no es alcanzable")
            return
        }
        
        let workoutStart: [String: Any] = [
            "type": "startWorkout",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        WCSession.default.sendMessage(workoutStart, replyHandler: nil) { error in
            print("❌ Error iniciando entrenamiento en Watch: \(error.localizedDescription)")
        }
    }
    
    func endWorkoutOnWatch() {
        guard WCSession.default.isReachable else {
            print("⌚️ Apple Watch no es alcanzable")
            return
        }
        
        let workoutEnd: [String: Any] = [
            "type": "endWorkout",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        WCSession.default.sendMessage(workoutEnd, replyHandler: nil) { error in
            print("❌ Error finalizando entrenamiento en Watch: \(error.localizedDescription)")
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            switch activationState {
            case .activated:
                self.isWatchConnected = session.isPaired
                self.isWatchAppInstalled = session.isWatchAppInstalled
                print("⌚️ Apple Watch activado - Conectado: \(self.isWatchConnected), App instalada: \(self.isWatchAppInstalled)")
            case .inactive:
                self.isWatchConnected = false
                print("⌚️ Apple Watch sesión inactiva")
            case .notActivated:
                self.isWatchConnected = false
                print("⌚️ Apple Watch sesión no activada")
            @unknown default:
                self.isWatchConnected = false
                print("⌚️ Apple Watch estado desconocido")
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = false
            print("⌚️ Apple Watch se volvió inactivo")
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = false
            print("⌚️ Apple Watch desactivado")
        }
        
        // Reactivar la sesión
        session.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("📱 Mensaje recibido del Apple Watch: \(message)")
        
        DispatchQueue.main.async {
            // Procesar diferentes tipos de mensajes del Watch
            guard let messageType = message["type"] as? String else { return }
            
            switch messageType {
            case "healthData":
                self.processHealthDataFromWatch(message)
            case "workoutUpdate":
                self.processWorkoutUpdateFromWatch(message)
            case "workoutCompleted":
                self.processWorkoutCompletedFromWatch(message)
            default:
                print("⌚️ Tipo de mensaje desconocido: \(messageType)")
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("📱 Mensaje con respuesta recibido del Apple Watch: \(message)")
        
        // Responder al Apple Watch con datos solicitados
        guard let messageType = message["type"] as? String else {
            replyHandler(["error": "Tipo de mensaje no válido"])
            return
        }
        
        switch messageType {
        case "requestUserData":
            // Enviar datos del usuario al Watch
            let userData: [String: Any] = [
                "userName": UserManager().userName,
                "timestamp": Date().timeIntervalSince1970
            ]
            replyHandler(userData)
            
        case "requestWorkoutList":
            // Acceder al WorkoutViewModel compartido del App
            DispatchQueue.main.async {
                // Como no podemos acceder directamente al EnvironmentObject aquí,
                // necesitaríamos una referencia compartida o usar NotificationCenter
                let workoutData: [String: Any] = [
                    "workouts": [], // Por ahora vacío, se puede mejorar más tarde
                    "timestamp": Date().timeIntervalSince1970
                ]
                replyHandler(workoutData)
            }
            
        default:
            replyHandler(["error": "Tipo de solicitud no soportado"])
        }
    }
    
    private func processHealthDataFromWatch(_ message: [String: Any]) {
        // Procesar datos de salud recibidos del Watch
        if let steps = message["steps"] as? Int {
            NotificationCenter.default.post(name: .watchStepsUpdate, object: steps)
        }
        
        if let heartRate = message["heartRate"] as? Double {
            NotificationCenter.default.post(name: .watchHeartRateUpdate, object: heartRate)
        }
        
        if let calories = message["calories"] as? Double {
            NotificationCenter.default.post(name: .watchCaloriesUpdate, object: calories)
        }
    }
    
    private func processWorkoutUpdateFromWatch(_ message: [String: Any]) {
        // Procesar actualizaciones de entrenamiento del Watch
        if let duration = message["duration"] as? TimeInterval,
           let calories = message["calories"] as? Double,
           let heartRate = message["heartRate"] as? Double {
            
            let workoutUpdate = [
                "duration": duration,
                "calories": calories,
                "heartRate": heartRate
            ]
            
            NotificationCenter.default.post(name: .watchWorkoutUpdate, object: workoutUpdate)
        }
    }
    
    private func processWorkoutCompletedFromWatch(_ message: [String: Any]) {
        // Procesar entrenamiento completado desde el Watch
        if let workoutData = message["workoutData"] as? [String: Any] {
            NotificationCenter.default.post(name: .watchWorkoutCompleted, object: workoutData)
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let watchStepsUpdate = Notification.Name("watchStepsUpdate")
    static let watchHeartRateUpdate = Notification.Name("watchHeartRateUpdate")
    static let watchCaloriesUpdate = Notification.Name("watchCaloriesUpdate")
    static let watchWorkoutUpdate = Notification.Name("watchWorkoutUpdate")
    static let watchWorkoutCompleted = Notification.Name("watchWorkoutCompleted")
}
