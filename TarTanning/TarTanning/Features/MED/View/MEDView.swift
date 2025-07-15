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
            Button("MED 계산 테스트") {
                viewModel.testMEDCalculation()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .navigationTitle("MED Test")
    }
}

#Preview {
    MEDView()
}
