//
//  TarTanningApp.swift
//  TarTanning
//
//  Created by J on 7/11/25.
//

import SwiftUI

@main
struct TarTanningApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
