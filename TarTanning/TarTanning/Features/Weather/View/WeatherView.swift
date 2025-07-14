//
//  WeatherView.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import SwiftUI

struct WeatherView: View {
    @StateObject private var viewModel = WeatherViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("Weather Test")
                .font(.title)
                .fontWeight(.bold)

            Button("포항 UV 지수 로그 확인") {
                viewModel.fetchSydneyUVIndex()
            }
            .buttonStyle(.borderedProminent)
            .padding()

            if viewModel.isLoading {
                ProgressView("UV 지수 가져오는 중...")
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .navigationTitle("Weather")
    }
}

#Preview {
    WeatherView()
}
