//
//  RootView.swift
//  TarTanning
//
//  Created by J on 7/15/25.
//

import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var router = NavigationRouter()
    @AppStorage("isOnboardingCompleted") private var didFinishOnboarding: Bool = false
    
    var body: some View {
        NavigationStack(path: $router.path) {
            Group {
                if didFinishOnboarding {
                    MainView()
                        .navigationBarBackButtonHidden(true)
                } else {
                    OnboardingView()
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .onBoarding:
                    OnboardingView()
                case .dashboard:
                    MainView()
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
