//
//  DashboardView.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: DashboardViewModel

    @State private var showingTimer = false

    @State private var showingDebugSheet = false

    init(modelContext: ModelContext) {
        _viewModel = StateObject(
            wrappedValue: DashboardViewModel(modelContext: modelContext)
        )
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: true) {
                VStack(spacing: 20) {
                    VStack {
                    }
                }
                .padding(.horizontal, 20)
            }
            .background(Color.white01)
            .navigationTitle("대시보드")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            viewModel.loadAllDashboardData()
        }
    }
}
