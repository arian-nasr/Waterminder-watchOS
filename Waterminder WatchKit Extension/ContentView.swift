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
        Text("Hello, World!")
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
