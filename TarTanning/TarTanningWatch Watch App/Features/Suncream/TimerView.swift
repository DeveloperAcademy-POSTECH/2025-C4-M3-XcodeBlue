//
//  TimerView.swift
//  TarTanning
//
//  Created by taeni on 7/17/25.
//

import SwiftUI

struct TimerView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var duration: Double = 60

    var body: some View {
        VStack {
            if viewModel.isRunning {
                Text("남은 시간: \(Int(viewModel.session?.remainingTime ?? 0))초")
            } else {
                Picker("시간 선택", selection: $duration) {
                    ForEach(Array(stride(from: 20.0, through: 100.0, by: 5)), id: \.self) {
                        Text("\(Int($0))초").tag($0)
                    }
                }
                .labelsHidden()
                .frame(height: 80)

                Button("타이머 시작") {
                    viewModel.start(duration: duration)
                }
            }

            if viewModel.isCompleted {
                Text("✅ 타이머 완료")
            }
        }
        .padding()
    }
}

#Preview {
    TimerView(viewModel: TimerViewModel())
}
