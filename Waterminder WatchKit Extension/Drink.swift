//
//  Drink.swift
//  Waterminder WatchKit Extension
//
//  Created by Arian Nasr on 2021-09-21.
//

import Foundation

// The record of a single drink.
struct Drink: Hashable, Codable {
    
    // The amount of caffeine in the drink.
    let mlWater: Double
    
    // The date when the drink was consumed.
    let date: Date
    
    // A globally unique identifier for the drink.
    let uuid: UUID
    
    // The drink initializer.
    init(mlWater: Double, onDate date: Date, uuid: UUID = UUID()) {
        self.mlWater = mlWater
        self.date = date
        self.uuid = uuid
    }
    
    // Calculate the amount of caffeine remaining at the provided time,
    // based on a 5-hour half life.
//    public func caffeineRemaining(at targetDate: Date) -> Double {
//        // Calculate the number of half-life time periods (5-hour increments)
//        let intervals = targetDate.timeIntervalSince(date) / (60.0 * 60.0 * 5.0)
//        return mgCaffeine * pow(0.5, intervals)
//    }
}
