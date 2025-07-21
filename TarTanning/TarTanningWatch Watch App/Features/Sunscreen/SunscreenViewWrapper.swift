//
//  SunscreenViewWrapper.swift
//  TarTanning
//
//  Created by taeni on 7/19/25.
//

import SwiftUI

struct SunscreenViewWrapper: View {
    @StateObject private var viewModel = SunscreenViewModel.shared
    @State private var currentTab = 0
    
    var body: some View {
        TabView(selection: $currentTab) {
            SunscreenStatusView()
                .tag(0)
            
            SunscreenTimerView()
                .tag(1)
        }
        .tabViewStyle(.page)
        .scrollIndicators(.hidden)
        .ignoresSafeArea()
        .onChange(of: viewModel.isActive) { _, isActive in
            if isActive {
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentTab = 1
                }
            }
        }
        .onChange(of: viewModel.isCompleted) { _, isCompleted in
            if isCompleted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentTab = 0
                    }
                }
            }
        }
        .onAppear {
            WatchConnectivityManager.shared.activateSession()
        }
    }
}

#Preview {
    SunscreenViewWrapper()
}
