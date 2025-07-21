//
//  HomeView.swift
//  TarTanningWatch Watch App
//
//  Created by Jun on 7/14/25.
//

import SwiftUI

struct WatchRootView: View {
    var body: some View {
        TabView {
            UvDoseView()
            SunscreenViewWrapper()
        }
        .tabViewStyle(.verticalPage)
        .ignoresSafeArea()
    }
}

#Preview {
    WatchRootView()
}
