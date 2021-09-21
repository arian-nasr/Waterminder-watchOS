//
//  HealthKitController.swift
//  Waterminder WatchKit Extension
//
//  Created by Arian Nasr on 2021-09-21.
//

import Foundation
import HealthKit

class HealthKitController {
    private let anchorKey = "anchorKey"
    private weak var model: WaterData?
    private lazy var store = HKHealthStore()
    private lazy var isAvailable = HKHealthStore.isHealthDataAvailable()
    private lazy var isAuthorized = false
    private lazy var waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater)!
    private lazy var types: Set<HKSampleType> = [waterType]
    private lazy var mililiters = HKUnit.literUnit(with: .milli)
    
    private var anchor: HKQueryAnchor? {
        get {
            // If user defaults returns nil, just return it.
            guard let data = UserDefaults.standard.object(forKey: anchorKey) as? Data else {
                return nil
            }
            
            // Otherwise, unarchive and return the data object.
            do {
                return try NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
            } catch {
                // If an error occurs while unarchiving, log the error and return nil.
                return nil
            }
        }
        set(newAnchor) {
            // If the new value is nil, save it.
            guard let newAnchor = newAnchor else {
                UserDefaults.standard.set(nil, forKey: anchorKey)
                return
            }
            
            // Otherwise convert the anchor object to Data, and save it in user defaults.
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: newAnchor, requiringSecureCoding: true)
                UserDefaults.standard.set(data, forKey: anchorKey)
            } catch {
                // If an error occurs while archiving the anchor, just log the error.
                // the value stored in user defaults is not changed.
            }
        }
    }
    
    init(withModel model: WaterData) {
        self.model = model
    }
    
    public func requestAuthorization(handler: @escaping (Bool) -> Void ) {
        guard isAvailable else { return }
        
        store.requestAuthorization(toShare: types, read: types) { [unowned self ](success, error) in
            
            // Check for any errors.
            guard error == nil else {
                return
            }
            
            // Set the authorization property, and call the handler.
            self.isAuthorized = success
            handler(success)
        }
    }
    
    public func loadNewDataFromHealthKit( completionHandler: @escaping (Bool) -> Void = { _ in }) {
        
        guard isAvailable else {
            completionHandler(false)
            return
        }
        
        
        // Create a predicate that only returns samples created within the last 24 hours.
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-24.0 * 60.0 * 60.0)
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictStartDate, .strictEndDate])
        
        // Create the query.
        let query = HKAnchoredObjectQuery(
            type: waterType,
            predicate: datePredicate,
            anchor: anchor,
            limit: HKObjectQueryNoLimit) { [unowned self] (query, samples, deletedSamples, newAnchor, error) in
            
            // When the query ends, check for errors.
            if let error = error {
                completionHandler(false)
                return
            }
            
            // Update the anchor.
            self.anchor = newAnchor
            
            // Convert new caffeine samples into Drink instances.
            var newDrinks = [Drink]()
            if let samples = samples {
                newDrinks = self.process(waterSamples: samples)
            }
            
            // Update the data on the main queue.
            DispatchQueue.main.async {
                
                // Create drink instances for any samples deleted from HealthKit.
                var deletedDrinks = [Drink]()
                if let deletedSamples = deletedSamples {
                    deletedDrinks = self.process(deletedWaterSamples: deletedSamples)
                }
                
                // Update the model.
                self.updateModel(newDrinks: newDrinks, deletedDrinks: deletedDrinks)
                completionHandler(true)
            }
        }
        
        store.execute(query)
    }
    
    public func save(drink: Drink) {
        
        // Make sure HealthKit is available and authorized.
        guard isAvailable else { return }
        guard store.authorizationStatus(for: waterType) == .sharingAuthorized else { return }
        
        // Create metadata to hold the drink's UUID.
        // Use the sync identifier to remove drinks if they are deleted from
        // HealthKit.
        let metadata: [String: Any] = [HKMetadataKeySyncIdentifier: drink.uuid.uuidString,
                                       HKMetadataKeySyncVersion: 1]
        
        // Create a quantity object for the amount of caffeine in the drink.
        let mlWater = HKQuantity(unit: mililiters, doubleValue: drink.mlWater)
        
        // Create the caffeine sample.
        let waterSample = HKQuantitySample(type: waterType,
                                              quantity: mlWater,
                                              start: drink.date,
                                              end: drink.date,
                                              metadata: metadata)
        
        // Save the sample to the HealthKit store.
        store.save(waterSample) { [unowned self] (success, error) in
            guard success else {
                return
            }
            
        }
    }
    
    private func process(waterSamples: [HKSample]) -> [Drink] {
        
        // Filter out any samples saved by this app.
        let newSamples = waterSamples.filter { (sample) -> Bool in
            sample.sourceRevision.source != HKSource.default()
        }
        
        
        // Create an array to store the new drinks.
        var newDrinks = [Drink]()
        
        // Convert each sample into a drink, and add it to the array.
        for sample in newSamples {
            guard let sample = sample as? HKQuantitySample else { continue }
            let drink = Drink(mlWater: sample.quantity.doubleValue(for: mililiters),
                              onDate: sample.startDate,
                              uuid: sample.uuid)
            
            newDrinks.append(drink)
        }
        
        // Return the array.
        return newDrinks
    }
    
    private func process(deletedWaterSamples: [HKDeletedObject]) -> [Drink] {
        assert(Thread.main == Thread.current, "Must be run on the main queue because it accesses currentDrinks.")
        
        // Get an array of drinks to delete.
        var drinksToDelete = [Drink]()
        
        // Find the UUID for each deleted drink. Use this to find the drink in the app's data.
        for deletedDrink in deletedWaterSamples {
            let uuidString = (deletedDrink.metadata?[HKMetadataKeySyncIdentifier] as? String)
            let uuid = UUID(uuidString: uuidString ?? "") ?? deletedDrink.uuid
            let uuids = model?.currentDrinks.map({ $0.uuid })
            guard let index = uuids?.firstIndex(of: uuid) else { continue }
            guard let drink = model?.currentDrinks[index] else { continue }
            drinksToDelete.append(drink)
        }
        
        
        return drinksToDelete
    }
    
    // Update the model.
    private func updateModel(newDrinks: [Drink], deletedDrinks: [Drink]) {
        assert(Thread.main == Thread.current, "Must be run on the main queue because it accesses currentDrinks.")
        
        // Get a copy of the current drink data.
        guard let oldDrinks = model?.currentDrinks else { return }
        
        // Remove the deleted drinks.
        var drinks = oldDrinks.filter { !deletedDrinks.contains($0) }
        
        // Add the new drinks.
        drinks.append(contentsOf: newDrinks)
        
        // Sort the array by date.
        drinks.sort { (lhs, rhs) -> Bool in
            lhs.date.compare(rhs.date) == .orderedAscending
        }
        
        model?.currentDrinks = drinks
    }
    
}
