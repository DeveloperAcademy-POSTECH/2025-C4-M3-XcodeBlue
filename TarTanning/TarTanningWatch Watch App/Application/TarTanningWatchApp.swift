//
//  TarTanningWatchApp.swift
//  TarTanningWatch Watch App
//
//  Created by J on 7/11/25.
//

import SwiftUI
import WatchKit

@main
struct TarTanningWatchWatchApp: App {
    @WKExtensionDelegateAdaptor(WatchAppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
