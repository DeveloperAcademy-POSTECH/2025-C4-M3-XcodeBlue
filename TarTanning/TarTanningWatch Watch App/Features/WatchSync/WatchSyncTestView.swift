//
//  WatchSyncTestView.swift
//  TarTanningWatch Watch App
//
//  Created by Jun on 7/15/25.
//

import Combine
import SwiftUI
import WatchKit

@MainActor
class WatchSyncTestViewModel: ObservableObject {
    @Published var receivedUVIndex: Double = 0.0
    @Published var receivedMEDValue: Double = 0.0
    @Published var statusMessage: String = "iPhone에서 데이터를 기다리는 중..."
    
    private var cancellables = Set<AnyCancellable>()

    init() {
        WatchConnectivityManager.shared.receivedContextPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] context in
                if let uvIndex = context["uvIndex"] as? Double {
                    self?.receivedUVIndex = uvIndex
                }
                if let medValue = context["medValue"] as? Double {
                    self?.receivedMEDValue = medValue
                }
                self?.statusMessage = "데이터 수신 완료: \(Date().formatted(date: .omitted, time: .standard))"
            }
            .store(in: &cancellables)
    }
}

struct WatchSyncTestView: View {
    @StateObject private var viewModel = WatchSyncTestViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("수신된 데이터")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack {
                    Text("UV 지수")
                        .font(.footnote)
                    Text(String(format: "%.1f", viewModel.receivedUVIndex))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.blue)
                }
                
                VStack {
                    Text("MED 값")
                        .font(.footnote)
                    Text(String(format: "%.1f", viewModel.receivedMEDValue))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.orange)
                }
                
                Text(viewModel.statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Watch 테스트")
        .onAppear {
            WatchConnectivityManager.shared.activateSession()
        }
    }
}
