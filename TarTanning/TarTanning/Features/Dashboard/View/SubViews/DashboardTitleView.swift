//
//  DashboardTitleView.swift
//  TarTanning
//
//  Created by Jun on 7/19/25.
//

import SwiftUI

struct DashboardTitleView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("대시보드")
                Text(Date().dateString)
            }
            Spacer()
        }
    }
}

#Preview {
    DashboardTitleView()
}
