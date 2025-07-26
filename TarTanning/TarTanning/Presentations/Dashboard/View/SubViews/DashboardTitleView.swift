//
//  DashboardTitleView.swift
//  TarTanning
//
//  Created by Jun on 7/19/25.
//

import SwiftUI

struct DashboardTitleView: View {
    @ObservedObject var viewModel: DashboardViewModel
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(Date().dateString)
                Text(viewModel.currentCityName)
            }
            Spacer()
        }
    }
}
