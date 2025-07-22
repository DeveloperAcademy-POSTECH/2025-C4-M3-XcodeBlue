//
//  RootView.swift
//  TarTanning
//
//  Created by J on 7/15/25.
//

import SwiftUI

struct RootView: View {
    @StateObject private var router = NavigationRouter()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            OnboardingView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .onBoarding:
                        OnboardingView()
                    case .dashboard:
                        DashboardView()
                            .navigationBarBackButtonHidden(true)
                    }
                }
        }
        .environmentObject(router)
    }
}

#Preview {
    RootView()
}
