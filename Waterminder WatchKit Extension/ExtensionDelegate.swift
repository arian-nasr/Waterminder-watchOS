//
//  ExtensionDelegate.swift
//  Waterminder WatchKit Extension
//
//  Created by Arian Nasr on 2021-09-22.
//

import WatchKit
import os

// The app's extension delegate.
class ExtensionDelegate: NSObject, WKExtensionDelegate {
    // MARK: - Delegate Methods
    // Called when a background task occurs.
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        
        for task in backgroundTasks {
            
            switch task {
            // Handle background refresh tasks.
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                
                // Check for updates from HealthKit.
                let model = WaterData.shared
                
                model.healthKitController.loadNewDataFromHealthKit { [unowned self] (success) in
                    
                    if success {
                        // Schedule the next background update.
                        scheduleBackgroundRefreshTasks()
                    }
                    
                    // Mark the task as ended, and request an updated snapshot, if necessary.
                    backgroundTask.setTaskCompletedWithSnapshot(success)
                }
                
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}

// Schedule the next background refresh task.
func scheduleBackgroundRefreshTasks() {
    // Get the shared extension object.
    let watchExtension = WKExtension.shared()
    
    // If there is a complication on the watch face, the app should get at least four
    // updates an hour. So calculate a target date 15 minutes in the future.
    let targetDate = Date().addingTimeInterval(15.0 * 60.0)
    
    // Schedule the background refresh task.
    watchExtension.scheduleBackgroundRefresh(withPreferredDate: targetDate, userInfo: nil) { (error) in
        
        // Check for errors.
        if let error = error {
            return
        }
        
    }
}

