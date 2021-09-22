//
//  CustomMLView.swift
//  Waterminder WatchKit Extension
//
//  Created by Arian Nasr on 2021-09-22.
//

import SwiftUI

// Display a list of drinks.
// Users can select drinks from the list.
struct CustomMLView: View {
    
    @EnvironmentObject var waterData: WaterData
    @Environment(\.presentationMode) var presentationMode
    
    // Layout the view's body.
    var body: some View {
        List {
            // Add a tappable row for each drink.
            ForEach(DrinkType.allCases) { drinkType in
                Button(action: { self.addDrink(type: drinkType) }) {
                    Text(drinkType.name)
                }
            }
        }
    }
    
    // Update the model when the user taps a drink.
    func addDrink(type: DrinkType) {
        // Add a drink to the model.
        waterData.addDrink(mlWater: type.mlWaterPerServing,
                            onDate: Date())
        
        // Dismiss the view.
        presentationMode.wrappedValue.dismiss()
    }
}

// Configure a preview of the drink list view.
struct CustomMLView_Previews: PreviewProvider {
    static var previews: some View {
        CustomMLView()
    }
}
