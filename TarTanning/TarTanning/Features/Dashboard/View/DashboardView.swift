//
//  DashboardView.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import SwiftUI

struct DashboardView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                DashboardTitleView()
                DashboardUVDoseView()
                DashboardSummaryMetricsView()
                DashboardWeeklySummaryView()
            }
            .padding(20)
        }
    }
}

#Preview {
    DashboardView()
}
