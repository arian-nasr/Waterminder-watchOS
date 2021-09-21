//
//  DrinkType.swift
//  Waterminder WatchKit Extension
//
//  Created by Arian Nasr on 2021-09-21.
//

import Foundation

// Define the types of drinks supported by Coffee Tracker.
enum DrinkType: Int, CaseIterable, Identifiable {
    
    case cup
    case bottle
    case liter
    case other
    
    // A unique ID for each drink.
    var id: Int {
        self.rawValue
    }
    
    // The name of the drink as a user-readable string.
    var name: String {
        switch self {
        case .cup:
            return "250 mL"
        case .bottle:
            return "500 mL"
        case .liter:
            return "1000 mL"
        case .other:
            return "Other"
        }
    }
    
    // The amount of caffeine in the drink.
    var mlWaterPerServing: Double {
        switch self {
        case .cup:
            return 250.0
        case .bottle:
            return 500.0
        case .liter:
            return 1000.0
        case .other:
            //WORK NEEDED HERE
            return 64.0
        }
    }
}
