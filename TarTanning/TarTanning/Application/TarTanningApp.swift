//
//  TarTanningApp.swift
//  TarTanning
//
//  Created by J on 7/11/25.
//

import SwiftUI
import SwiftData

@main
struct TarTanningApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // SwiftData ModelContainer 설정
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            LocationWeather.self,
            HourlyWeather.self,
            DailyUVExpose.self,
            UVExposeRecord.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(sharedModelContainer) // ModelContainer 주입
        }
    }
}
