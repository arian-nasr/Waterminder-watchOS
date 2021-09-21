//
//  WaterTrackerView.swift
//  Waterminder WatchKit Extension
//
//  Created by Arian Nasr on 2021-09-21.
//

import SwiftUI

// The Coffee Tracker app's main view.
struct WaterTrackerView: View {
    
    @EnvironmentObject var waterData: WaterData
    @State var showDrinkList = false
    
    // Lay out the view's body.
    var body: some View {
        VStack {
            
            // Display the current amount of caffeine in the user's body.
            Text(String(waterData.currentMLWater) + " mL")
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(colorForWaterDose())
            Text("Current Hydration")
                .font(.footnote)
            Divider()
            
            // Display how much the user has drunk today,
            // using the equivalent number of 8 oz. cups of coffee.
            Text(String(waterData.totalCupsToday) + " cups")
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(colorForDailyDrinkCount())
            Text("Equivalent Drinks Today")
                .font(.footnote)
            Spacer()
            
            // Display a button that lets the user record new drinks.
            Button(action: { self.showDrinkList.toggle() }) {
                Image("add-coffee")
                    .renderingMode(.template)
            }
        }
        .sheet(isPresented: $showDrinkList) {
            DrinkListView().environmentObject(self.waterData)
        }
    }
    
    // MARK: - Private Methods
    // Calculate the color based on the amount of caffeine currently in the user's body.
    private func colorForWaterDose() -> Color {
        // Get the current amount of caffeine in the system.
        let currentDose = waterData.currentMLWater
        return Color(waterData.color(forWaterDose: currentDose))
    }
    
    // Calculate the color based on the number of drinks consumed today.
    private func colorForDailyDrinkCount() -> Color {
        // Get the number of cups drank today
        let cups = waterData.totalCupsToday
        return Color(waterData.color(forTotalCups: cups))
    }
}

// Configure a preview of the coffee tracker view.
struct WaterTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        WaterTrackerView()
            .environmentObject(WaterData.shared)
    }
}
