import SwiftUI

struct WatchSunscreenViewWrapper: View {
    @StateObject private var viewModel = SunscreenViewModel.shared
    @State private var currentTab = 0

    var body: some View {
        ZStack {
            Color(.suncreenBackground)
                .ignoresSafeArea()
            
            // currentTab 값에 따라 뷰 분기 (애니메이션/전환 효과 없음)
            if currentTab == 0 {
                WatchSunscreenStatusView()
            } else if currentTab == 1 {
                WatchSunscreenTimerView(currentTab: .constant(1))
            }
            
        }
        .onChange(of: viewModel.isActive) { _, isActive in
            if isActive {
                currentTab = 1
            }
        }
        .onChange(of: viewModel.isCompleted) { _, isCompleted in
            if isCompleted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    currentTab = 0
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
