//
//  UserManager.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 16/7/25.
//

import Foundation
import Combine

class UserManager: ObservableObject {
    @Published var userName: String = ""
    @Published var showingNameInput: Bool = false
    
    // Nuevas propiedades para el perfil
    @Published var userAge: String = ""
    @Published var userHeight: String = ""
    @Published var userWeight: String = ""
    @Published var profileImageData: Data?
    
    private let userNameKey = "user_name"
    private let userAgeKey = "user_age"
    private let userHeightKey = "user_height"
    private let userWeightKey = "user_weight"
    private let profileImageKey = "profile_image"
    
    // Computed property para compatibilidad
    var currentUserName: String {
        get { userName }
        set { 
            userName = newValue
            UserDefaults.standard.set(userName, forKey: userNameKey)
        }
    }
    
    init() {
        loadUserData()
    }
    
    private func loadUserData() {
        userName = UserDefaults.standard.string(forKey: userNameKey) ?? ""
        userAge = UserDefaults.standard.string(forKey: userAgeKey) ?? ""
        userHeight = UserDefaults.standard.string(forKey: userHeightKey) ?? ""
        userWeight = UserDefaults.standard.string(forKey: userWeightKey) ?? ""
        profileImageData = UserDefaults.standard.data(forKey: profileImageKey)
        showingNameInput = userName.isEmpty
    }
    
    private func loadUserName() {
        // Método mantenido para compatibilidad
        loadUserData()
    }
    
    func saveUserProfile(name: String, age: String, height: String, weight: String, imageData: Data? = nil) {
        userName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        userAge = age.trimmingCharacters(in: .whitespacesAndNewlines)
        userHeight = height.trimmingCharacters(in: .whitespacesAndNewlines)
        userWeight = weight.trimmingCharacters(in: .whitespacesAndNewlines)
        
        UserDefaults.standard.set(userName, forKey: userNameKey)
        UserDefaults.standard.set(userAge, forKey: userAgeKey)
        UserDefaults.standard.set(userHeight, forKey: userHeightKey)
        UserDefaults.standard.set(userWeight, forKey: userWeightKey)
        
        if let imageData = imageData {
            profileImageData = imageData
            UserDefaults.standard.set(imageData, forKey: profileImageKey)
        }
        
        showingNameInput = false
    }
    
    func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String
        
        switch hour {
        case 6..<12:
            greeting = "Buenos días"
        case 12..<18:
            greeting = "Buenas tardes"
        case 18..<22:
            greeting = "Buenas tardes"
        default:
            greeting = "Buenas noches"
        }
        
        return userName.isEmpty ? greeting : "\(greeting), \(userName)"
    }
    
    static let motivationalQuotes = [
        "El único entrenamiento malo es el que no se hizo.",
        "No se trata de ser perfecto, se trata de ser mejor que ayer.",
        "Tu único límite eres tú mismo.",
        "El dolor es temporal, el orgullo es para siempre.",
        "No pares cuando estés cansado, para cuando hayas terminado.",
        "El éxito comienza cuando sales de tu zona de confort.",
        "Cada día es una nueva oportunidad para ser mejor.",
        "La disciplina es elegir entre lo que quieres ahora y lo que quieres más."
    ]
    
    func getMotivationalQuote() -> String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % UserManager.motivationalQuotes.count
        return UserManager.motivationalQuotes[index]
    }
}
