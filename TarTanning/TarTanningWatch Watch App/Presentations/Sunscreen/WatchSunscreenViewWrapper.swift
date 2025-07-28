import SwiftUI

struct WatchSunscreenViewWrapper: View {
    @StateObject private var viewModel = SunscreenViewModel.shared
    @State private var currentTab = 0
    
    var body: some View {
        TabView(selection: $currentTab) {
            WatchSunscreenStatusView()
                .tag(0)
            
            WatchSunscreenTimerView()
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
    WatchSunscreenViewWrapper()
}
