//
//  HostingController.swift
//  Waterminder WatchKit Extension
//
//  Created by Arian Nasr on 2021-09-22.
//

import SwiftUI

// A controller that hosts SwiftUI views.
class HostingController: WKHostingController<ContentView> {
    
    // MARK: - Body Method
    
    override var body: ContentView {
        // Creates and displays the content wrapper.
        return ContentView()
    }
}
