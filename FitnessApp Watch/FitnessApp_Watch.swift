//
//  FitnessApp_Watch.swift
//  FitnessApp Watch
//
//  Created by Jordi Mauri on 22/7/25.
//

import AppIntents

struct FitnessApp_Watch: AppIntent {
    static var title: LocalizedStringResource { "FitnessApp Watch" }
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
