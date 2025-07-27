//
//  FocusModeManager.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 18/7/25.
//

import SwiftUI
import UIKit
import Combine

class FocusModeManager: ObservableObject {
    @Published var isActive: Bool = false {
        didSet {
            if isActive {
                activateFocusMode()
            } else {
                deactivateFocusMode()
            }
        }
    }
    @Published var keepScreenOn: Bool = true {
        didSet {
            updateScreenSettings()
        }
    }
    @Published var hideTabBar: Bool = true
    @Published var dimUI: Bool = false
    @Published var simplifyInterface: Bool = true
    @Published var preventAccidentalTouches: Bool = true
    @Published var showWorkoutTimer: Bool = true
    @Published var hideSecondaryElements: Bool = true
    @Published var lockOrientation: Bool = true
    @Published var increaseButtonSize: Bool = true
    @Published var showOnlyActiveExercise: Bool = false
    @Published var adjustBrightness: Bool = true
    @Published var brightnessSetting: CGFloat = 0.8
    @Published var hapticFeedback: Bool = true
    
    private var originalBrightness: CGFloat?
    private var originalIdleTimerState: Bool = false
    
    init() {
        loadSettings()
    }
    
    func activateFocusMode() {
        isActive = true
        
        // Haptic feedback
        HapticManager.shared.focusModeActivated()
        
        // Save original settings
        originalBrightness = UIScreen.main.brightness
        originalIdleTimerState = UIApplication.shared.isIdleTimerDisabled
        
        // Apply screen settings
        if keepScreenOn {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
        if adjustBrightness {
            UIScreen.main.brightness = brightnessSetting
        }
        
        saveSettings()
    }
    
    // MARK: - Individual Screen Settings
    private func updateScreenSettings() {
        if keepScreenOn {
            UIApplication.shared.isIdleTimerDisabled = true
            print("✅ Pantalla mantenida encendida - No se bloqueará automáticamente")
        } else {
            UIApplication.shared.isIdleTimerDisabled = false
            print("❌ Pantalla normal - Se bloqueará según configuración del sistema")
        }
        saveSettings()
    }
    
    func deactivateFocusMode() {
        isActive = false
        
        // Restore original settings
        if let originalBrightness = originalBrightness {
            UIScreen.main.brightness = originalBrightness
        }
        
        UIApplication.shared.isIdleTimerDisabled = originalIdleTimerState
        
        // Haptic feedback
        HapticManager.shared.focusModeDeactivated()
        
        saveSettings()
    }
    
    func toggleFocusMode() {
        if isActive {
            deactivateFocusMode()
        } else {
            activateFocusMode()
        }
    }
    
    // MARK: - Settings Management
    private func loadSettings() {
        keepScreenOn = UserDefaults.standard.bool(forKey: "FocusMode.keepScreenOn", defaultValue: true)
        hideTabBar = UserDefaults.standard.bool(forKey: "FocusMode.hideTabBar", defaultValue: true)
        dimUI = UserDefaults.standard.bool(forKey: "FocusMode.dimUI", defaultValue: false)
        simplifyInterface = UserDefaults.standard.bool(forKey: "FocusMode.simplifyInterface", defaultValue: true)
        preventAccidentalTouches = UserDefaults.standard.bool(forKey: "FocusMode.preventAccidentalTouches", defaultValue: true)
        showWorkoutTimer = UserDefaults.standard.bool(forKey: "FocusMode.showWorkoutTimer", defaultValue: true)
        hideSecondaryElements = UserDefaults.standard.bool(forKey: "FocusMode.hideSecondaryElements", defaultValue: true)
        lockOrientation = UserDefaults.standard.bool(forKey: "FocusMode.lockOrientation", defaultValue: true)
        increaseButtonSize = UserDefaults.standard.bool(forKey: "FocusMode.increaseButtonSize", defaultValue: true)
        showOnlyActiveExercise = UserDefaults.standard.bool(forKey: "FocusMode.showOnlyActiveExercise", defaultValue: false)
        adjustBrightness = UserDefaults.standard.bool(forKey: "FocusMode.adjustBrightness", defaultValue: true)
        brightnessSetting = UserDefaults.standard.double(forKey: "FocusMode.brightnessSetting", defaultValue: 0.8)
        hapticFeedback = UserDefaults.standard.bool(forKey: "FocusMode.hapticFeedback", defaultValue: true)
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(keepScreenOn, forKey: "FocusMode.keepScreenOn")
        UserDefaults.standard.set(hideTabBar, forKey: "FocusMode.hideTabBar")
        UserDefaults.standard.set(dimUI, forKey: "FocusMode.dimUI")
        UserDefaults.standard.set(simplifyInterface, forKey: "FocusMode.simplifyInterface")
        UserDefaults.standard.set(preventAccidentalTouches, forKey: "FocusMode.preventAccidentalTouches")
        UserDefaults.standard.set(showWorkoutTimer, forKey: "FocusMode.showWorkoutTimer")
        UserDefaults.standard.set(hideSecondaryElements, forKey: "FocusMode.hideSecondaryElements")
        UserDefaults.standard.set(lockOrientation, forKey: "FocusMode.lockOrientation")
        UserDefaults.standard.set(increaseButtonSize, forKey: "FocusMode.increaseButtonSize")
        UserDefaults.standard.set(showOnlyActiveExercise, forKey: "FocusMode.showOnlyActiveExercise")
        UserDefaults.standard.set(adjustBrightness, forKey: "FocusMode.adjustBrightness")
        UserDefaults.standard.set(brightnessSetting, forKey: "FocusMode.brightnessSetting")
        UserDefaults.standard.set(hapticFeedback, forKey: "FocusMode.hapticFeedback")
    }
}

// MARK: - UserDefaults Extension
extension UserDefaults {
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        if object(forKey: key) == nil {
            set(defaultValue, forKey: key)
            return defaultValue
        }
        return bool(forKey: key)
    }
    
    func double(forKey key: String, defaultValue: Double) -> Double {
        if object(forKey: key) == nil {
            set(defaultValue, forKey: key)
            return defaultValue
        }
        return double(forKey: key)
    }
}