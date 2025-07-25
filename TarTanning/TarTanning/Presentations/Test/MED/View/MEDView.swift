//
//  MEDView.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import SwiftUI

struct MEDView: View {
    @StateObject private var viewModel = MEDViewModel()

    var body: some View {
        VStack {
            Button("MED 계산 테스트 (SPF 15 적용)") {
                viewModel.testMEDCalculationWithSPF()
            }
            .buttonStyle(.borderedProminent)

            Button("MED 계산 테스트 (SPF 없음)") {
                viewModel.testMEDCalculationWithoutSPF()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()

    }
}

#Preview {
    MEDView()
}
