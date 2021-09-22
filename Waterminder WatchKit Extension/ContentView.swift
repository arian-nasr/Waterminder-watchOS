//
//  ContentView.swift
//  Waterminder WatchKit Extension
//
//  Created by Arian Nasr on 2021-09-21.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    
    let data = WaterData.shared
    
    var body: some View {
        WaterTrackerView()
            .environmentObject(data)
            .onChange(of: scenePhase) { (phase) in
                switch phase {
                    
                case .inactive:
                    print("did nothing")
                case .active:
                    let model = WaterData.shared
                    model.healthKitController.requestAuthorization { (success) in
                        if !success { fatalError("*** Unable to authenticate HealthKit ***") }
                        model.healthKitController.loadNewDataFromHealthKit { _ in }
                    }
                case .background:
                    print("did nothing")
                @unknown default:
                    print("did nothing")
                }
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
