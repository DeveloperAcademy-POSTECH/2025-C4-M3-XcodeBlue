//
//  MainView.swift
//  TarTanning
//
//  Created by Jun on 7/28/25.
//

import SwiftUI

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView {
            DashboardView(modelContext: modelContext)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("대시보드")
                }
            
            SettingView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("설정")
                }
        }
    }
}

#Preview {
    MainView()
}
