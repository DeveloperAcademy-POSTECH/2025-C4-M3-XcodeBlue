//
//  TestLocationView.swift
//  TarTanning
//
//  Created by J on 7/19/25.
//

import SwiftUI

struct TestLocationView: View {
    @StateObject private var viewModel = TestLocationViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("위치 권한 상태: \(viewModel.authStatus.description)")
                .font(.headline)

            if let location = viewModel.locationInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Text("도시: \(location.city)")
                    Text("위도: \(location.latitude)")
                    Text("경도: \(location.longitude)")
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                Text("위치 정보가 없습니다.")
                    .foregroundColor(.secondary)
            }

            if let error = viewModel.errorMessage {
                Text("에러: \(error)")
                    .foregroundColor(.red)
            }

            Button("권한 요청") {
                viewModel.requestAuthorization()
            }
            .padding(.top, 20)

            Button("위치 수동 업데이트") {
                viewModel.startLocationUpdate()
            }

            Button("위치 업데이트 중지") {
                viewModel.stopLocationUpdate()
            }
        }
        .padding()
    }
}

#Preview {
    TestLocationView()
}
