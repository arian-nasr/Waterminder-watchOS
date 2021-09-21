//
//  WaterData.swift
//  Waterminder WatchKit Extension
//
//  Created by Arian Nasr on 2021-09-21.
//

import SwiftUI
import ClockKit

// The data model for the Coffee Tracker app.
class WaterData: ObservableObject {
        
    // The data model needs to be accessed both from the app extension
    // and from the complication controller.
    static let shared = WaterData()
    lazy var healthKitController = HealthKitController(withModel: self)
    
    // A background queue used to save and load the model data.
    private var background = DispatchQueue(label: "Background Queue",
    qos: .userInitiated)
    
    // The list of drinks consumed.
    // Because this is @Published property,
    // Combine notifies any observers when a change occurs.
    @Published public var currentDrinks = [Drink]() {
        didSet {
            // Update any complications on active watch faces.
            let server = CLKComplicationServer.sharedInstance()
            for complication in server.activeComplications ?? [] {
                server.reloadTimeline(for: complication)
            }
            
            // Begin saving the data.
            self.save()
        }
    }
    
    // Use this value to determine whether you have changes that can be saved to disk.
    private var savedValue = [Drink]()
    
    // The current level of caffeine in milligrams.
    // This property is calculated based on the currentDrinks array.
    public var currentMLWater: Double {
        mlWater(atDate: Date())
    }
    
    // Calculate the amount of caffeine in the user's system at the specified date.
    // The amount of caffeine is calculated from the currentDrinks array.
    public func mlWater(atDate date: Date) -> Double {
        
        var total = 0.0
        
        for drink in currentDrinks {
            total += drink.mlWater
        }
        
        return total
    }
    
    // Return the total number of drinks consumed today.
    // The value is in the equivalent number of 8 oz. cups of coffee.
    public var totalCupsToday: Double {
        
        // Calculate midnight this morning.
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: Date())
        
        // Filter the drinks.
        let drinks = currentDrinks.filter { midnight.compare($0.date) == .orderedAscending }
        
        // Get the total caffeine dose.
        let totalMG = drinks.reduce(0.0) { $0 + $1.mlWater }
        
        // Convert mg caffeine to equivalent cups.
        return totalMG / DrinkType.cup.mlWaterPerServing
    }
    
    // Return green, yellow, or red depending on the caffeine dose.
    //WORK NEEDED HERE
    public func color(forWaterDose dose: Double) -> UIColor {
        if dose < 200.0 {
            return .green
        } else if dose < 400.0 {
            return .yellow
        } else {
            return .red
        }
    }
    
    // Return green, yellow, or red depending on the total daily cups of  coffee.
    public func color(forTotalCups cups: Double) -> UIColor {
        if cups < 3.0 {
            return .green
        } else if cups < 5.0 {
            return .yellow
        } else {
            return .red
        }
    }
    
    // Add a drink to the list of drinks.
    public func addDrink(mlWater: Double, onDate date: Date) {
        
        // Create a local array to hold the changes.
        var drinks = currentDrinks
        
        // Create a new drink and add it to the array.
        let drink = Drink(mlWater: mlWater, onDate: date)
        drinks.append(drink)
        
        // Filter the array to get rid of any drinks that are 24 hours old.
        drinks = filterDrinks(drinks: drinks)
        
        // Update the current drinks property.
        currentDrinks = drinks
        
        // Save drink information to HealthKit.
        healthKitController.save(drink: drink)
    }
    
    // MARK: - Private Methods
    
    // The model's initializer. Do not call this method.
    // Use the shared instance instead.
    private init() {
        
        // Begin loading the data from disk.
        load()
    }
    
    // Begin saving the drink data to disk.
    private func save() {
        
        // Don't save the data if there haven't been any changes.
        if currentDrinks == savedValue {
            return
        }
        
        // Save as a binary plist file.
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        let data: Data
        
        do {
            // Encode the currentDrinks array.
            data = try encoder.encode(currentDrinks)
        } catch {
            return
        }
        
        // Save the data to disk as a binary plist file.
        let saveAction = { [unowned self] in
            do {
                // Write the data to disk
                try data.write(to: self.getDataURL(), options: [.atomic])
    
                // Update the saved value.
                self.savedValue = currentDrinks
                
            } catch {
            }
        }
        
        // If the app is running in the background, save synchronously.
        if WKExtension.shared().applicationState == .background {
            saveAction()
        } else {
            // Otherwise save the data on a background queue.
            background.async { [unowned self] in
                saveAction()
            }
        }
    }
    
    // Begin loading the data from disk.
    private func load() {
        // Read the data from a background queue.
        background.async { [unowned self] in
        
            var drinks: [Drink]
            
            do {
                // Load the drink data from a binary plist file.
                let data = try Data(contentsOf: self.getDataURL())
                
                // Decode the data.
                let decoder = PropertyListDecoder()
                drinks = try decoder.decode([Drink].self, from: data)
            } catch CocoaError.fileReadNoSuchFile {
                drinks = []
            } catch {
                fatalError("*** An unexpected error occurred while loading the drink list: \(error.localizedDescription) ***")
            }
            
            // Update the entires on the main queue.
            DispatchQueue.main.async { [unowned self] in
                
                // Update the saved value.
                savedValue = drinks
                
                // Filter the drinks.
                currentDrinks = filterDrinks(drinks: drinks)
                
                // Load new data from HealthKit.
                self.healthKitController.requestAuthorization { (success) in
                    guard success else {
                        return
                    }
                    
                    self.healthKitController.loadNewDataFromHealthKit()
                }
            }
        }
    }
    
    // Returns the URL for the plist file that stores the drink data.
    private func getDataURL() throws -> URL {
        // Get the URL for the app's document directory.
        let fileManager = FileManager.default
        let documentDirectory = try fileManager.url(for: .documentDirectory,
                                                    in: .userDomainMask,
                                                    appropriateFor: nil,
                                                    create: false)
        
        // Append the file name to the directory.
        return documentDirectory.appendingPathComponent("WaterTracker.plist")
    }
}

// Filter array to only the drinks in the last 24 hours.
private func filterDrinks(drinks: [Drink]) -> [Drink] {
    // The current date and time.
    let endDate = Date()
    
    // The date and time 24 hours ago.
    let startDate = endDate.addingTimeInterval(-24.0 * 60.0 * 60.0)
    
    // Return an array of drinks with a date parameter between
    // the start and end dates.
    return drinks.filter { (drink) -> Bool in
        (startDate.compare(drink.date) != .orderedDescending) &&
            (endDate.compare(drink.date) != .orderedAscending)
    }
}
