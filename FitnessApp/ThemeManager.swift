import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = false {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    init() {
        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
    }
}
