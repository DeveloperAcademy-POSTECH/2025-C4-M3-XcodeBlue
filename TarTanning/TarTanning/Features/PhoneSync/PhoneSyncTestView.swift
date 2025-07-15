//
//  PhoneSyncTestView.swift
//  TarTanning
//
//  Created by Jun on 7/15/25.
//

import Combine
import Foundation
import SwiftUI

class PhoneSyncTestViewModel: ObservableObject {
    @Published var uvIndexInput: Double = 6.0
    @Published var medValueInput = 150.5

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupDataSendingDebounce()
    }

    private func setupDataSendingDebounce() {
        Publishers.CombineLatest($uvIndexInput, $medValueInput)
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] (uvIndex, medValue) in
                self?.sendDataToWatch(uvIndex: uvIndex, medValue: medValue)
            }
            .store(in: &cancellables)
    }

    private func sendDataToWatch(uvIndex: Double, medValue: Double) {
        let context: [String: Any] = [
            "uvIndex": uvIndex,
            "medValue": medValue,
        ]
        WatchConnectivityManager.shared.sendContext(context)
    }
}

struct PhoneSyncTestView: View {
    @StateObject private var viewModel = PhoneSyncTestViewModel()

    var body: some View {
        VStack {
            Text("Watch Connectivity 테스트")

            VStack {
                HStack {
                    Text("UV 지수")
                    Spacer()
                    Text(String(format: "%.1f", viewModel.uvIndexInput))
                }

                Slider(value: $viewModel.uvIndexInput, in: 0...12, step: 1)
            }

            VStack {
                HStack {
                    Text("MED 값")
                    Spacer()
                    Text(String(format: "%.1f", viewModel.medValueInput))
                }
                Slider(value: $viewModel.medValueInput, in: 0...1000, step: 50)
            }
        }
        .onAppear {
            WatchConnectivityManager.shared.activateSession()
        }
    }
}
