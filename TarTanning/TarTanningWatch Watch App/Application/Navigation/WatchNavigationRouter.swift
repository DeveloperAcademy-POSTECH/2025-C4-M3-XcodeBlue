//
//  WatchNavigationRouter.swift
//  TarTanningWatch Watch App
//
//  Created by taeni on 7/19/25.
//

import SwiftUI

struct WatchNavigationView: View {
    
    @StateObject private var coordinator = WatchNavigationCoordinator()
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            WatchRootView()
                .navigationDestination(for: WatchRoute.self) { route in
                    switch route {
                    case .status:
                        WatchUvDoseView()
                    case .sunscreen:
                        WatchSunscreenViewWrapper()
                    }
                }
        }
        .environmentObject(coordinator)
    }
}
