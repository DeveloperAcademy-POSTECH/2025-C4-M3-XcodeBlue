//
//  WatchUvDoseView.swift
//  TarTanningWatch Watch App
//
//  Created by taeni on 7/18/25.
//

import SwiftUI

struct WatchUvDoseView: View {
    
    @State private var viewModel = WatchUvDoseViewModel.mock

    var body: some View {
        ZStack {
            viewModel.uvLevel.color
                .ignoresSafeArea()
            VStack(spacing: 24) {
                UvDoseValueView(percentage: viewModel.percentage,
                                uvLevel: viewModel.uvLevelText)

                UvIndexAndLocationView(uvIndex: viewModel.uvIndex,
                                       location: viewModel.location)
            }
        }
    }

    struct UvDoseValueView: View {
        let percentage: Int
        let uvLevel: String
        
        var body: some View {
            VStack(spacing: 9) {
                Text("현재 MED")
                    .font(.caption2)
                    .foregroundColor(.white)
                Text("\(percentage)%")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                Text(uvLevel)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }

    struct UvIndexAndLocationView: View {
        let uvIndex: Int
        let location: String
        
        var body: some View {
            HStack(alignment: .center) {
                VStack(alignment: .center) {
                    Text("자외선 지수")
                    Text("\(uvIndex)")
                }
                .font(.caption2)
                .foregroundColor(.white)

                Spacer()

                Text(location)
                    .font(.caption2)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    WatchUvDoseView()
}
