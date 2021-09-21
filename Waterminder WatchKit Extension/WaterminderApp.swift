//
//  WaterminderApp.swift
//  Waterminder WatchKit Extension
//
//  Created by Arian Nasr on 2021-09-21.
//

import SwiftUI

@main
struct WaterminderApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
