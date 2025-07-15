//
//  WatchSyncTestView.swift
//  TarTanningWatch Watch App
//
//  Created by Jun on 7/15/25.
//

import Combine
import SwiftUI

class WatchSyncTestViewModel: ObservableObject {
    @Published var receivedUVIndex: Double = 0.0
    @Published var receivedMEDValue: Double = 0.0

    private var cancellables = Set<AnyCancellable>()

    init() {
        WatchConnectivityManager.shared.receivedContextPublisher
            .receive(on: DispatchQueue.main)
            .sink { context in
                if let uvIndex = context["uvIndex"] as? Double {
                    self.receivedUVIndex = uvIndex
                }
                if let medValue = context["medValue"] as? Double {
                    self.receivedMEDValue = medValue
                }
            }
            .store(in: &cancellables)
    }
}

struct WatchSyncTestView: View {
    @StateObject private var viewModel = WatchSyncTestViewModel()

    var body: some View {
        VStack {
            HStack {
                Text("UV 지수")
                Text(String(format: "%.1f", viewModel.receivedUVIndex))
            }

            HStack {
                Text("MED 값")
                Text(String(format: "%.1f", viewModel.receivedMEDValue))
            }

        }
        .onAppear {
            WatchConnectivityManager.shared.activateSession()
        }
    }
}
