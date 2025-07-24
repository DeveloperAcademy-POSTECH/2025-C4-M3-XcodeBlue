//
//  HealthKitTestView.swift
//  TarTanning
//
//  Created by taeni on 7/15/25.
//

import HealthKit
import SwiftUI

struct HealthKitTestView: View {
    @StateObject private var viewModel = HealthKitTestViewModel()
    
    var body: some View {
        NavigationView {
            List {
                // 상태 섹션
                Section("상태") {
                    Text(viewModel.statusMessage)
                        .font(.caption)
                    
                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                            Text("로딩 중...")
                        }
                    }
                }
                
                // 권한 섹션
                Section("권한 관리") {
                    HStack {
                        Text("권한 상태")
                        Spacer()
                        Text(viewModel.currentAuthStatus.description)
                            .foregroundColor(viewModel.isAuthorized ? .green : .red)
                    }
                    
                    HStack {
                        Text("HealthKit 사용 가능")
                        Spacer()
                        Text(viewModel.isHealthKitAvailable ? "가능" : "불가능")
                            .foregroundColor(viewModel.isHealthKitAvailable ? .green : .red)
                    }
                    
                    Button("권한 상태 확인") {
                        viewModel.checkAuthorizationStatus()
                    }
                    
                    Button("권한 요청") {
                        viewModel.testAuthorization()
                    }
                }
                
                // 백그라운드 섹션
                Section("백그라운드 관리") {
                    HStack {
                        Text("백그라운드 전송")
                        Spacer()
                        Text(viewModel.isBackgroundEnabled ? "활성화됨" : "비활성화됨")
                            .foregroundColor(viewModel.isBackgroundEnabled ? .green : .red)
                    }
                    
                    Button("백그라운드 활성화") {
                        viewModel.testBackgroundDelivery()
                    }
                    
                    Button("관찰자 설정") {
                        viewModel.setupObserver()
                    }
                    
                    Button("백그라운드 비활성화") {
                        viewModel.disableBackgroundDelivery()
                    }
                    
                    Button("관찰자 중지") {
                        viewModel.stopObservers()
                    }
                }
                
                // 쿼리 비교 섹션
                Section("쿼리 매니저 비교") {
                    Button("오늘 데이터 (DataQueryManager)") {
                        viewModel.testTodaysDataFromDataManager()
                    }
                    
                    Button("오늘 데이터 (QueryManager)") {
                        viewModel.testTodaysDataFromQueryManager()
                    }
                    
                    Button("주간 트렌드 (DataQueryManager)") {
                        viewModel.testWeeklyTrendFromDataManager()
                    }
                    
                    Button("주간 트렌드 (QueryManager)") {
                        viewModel.testWeeklyTrendFromQueryManager()
                    }
                }
                
                // 고급 쿼리 섹션
                Section("고급 쿼리") {
                    Button("월간 트렌드") {
                        viewModel.testMonthlyTrend()
                    }
                    
                    Button("최신 샘플") {
                        viewModel.testLatestSample()
                    }
                    
                    Button("사용자 정의 기간 (최근 3일)") {
                        viewModel.testCustomDateRange()
                    }
                }
                
                // 결과 섹션
                Section("결과") {
                    HStack {
                        Text("오늘의 일광 노출")
                        Spacer()
                        Text("\(String(format: "%.1f", viewModel.todaysDaylight)) 분")
                    }
                    
                    HStack {
                        Text("사용자 정의 기간")
                        Spacer()
                        Text("\(String(format: "%.1f", viewModel.customRangeMinutes)) 분")
                    }
                    
                    HStack {
                        Text("주간 트렌드")
                        Spacer()
                        Text("\(viewModel.weeklyTrend.count) 일")
                    }
                    
                    HStack {
                        Text("월간 트렌드")
                        Spacer()
                        Text("\(viewModel.monthlyTrend.count) 일")
                    }
                    
                    if let sample = viewModel.latestSample {
                        let minutes = sample.quantity.doubleValue(for: HKUnit.minute())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("최신 샘플")
                                .font(.headline)
                            Text("\(String(format: "%.1f", minutes)) 분")
                                .font(.subheadline)
                            Text(DateFormatter.shortDateTime.string(from: sample.startDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        HStack {
                            Text("최신 샘플")
                            Spacer()
                            Text("데이터 없음")
                        }
                    }
                }
                
                // 주간 트렌드 상세
                if !viewModel.weeklyTrend.isEmpty {
                    Section("주간 트렌드 상세") {
                        ForEach(viewModel.weeklyTrend.indices, id: \.self) { index in
                            let stat = viewModel.weeklyTrend[index]
                            
                            HStack {
                                Text(DateFormatter.shortDate.string(from: stat.date))
                                Spacer()
                                Text("\(String(format: "%.1f", stat.minutes)) 분")
                            }
                        }
                    }
                }
                
                // 월간 트렌드 요약
                if !viewModel.monthlyTrend.isEmpty {
                    Section("월간 트렌드 요약") {
                        let totalMinutes = viewModel.monthlyTrend.reduce(0) { $0 + $1.minutes }
                        let averageMinutes = totalMinutes / Double(viewModel.monthlyTrend.count)
                        let maxDay = viewModel.monthlyTrend.max { $0.minutes < $1.minutes }
                        
                        HStack {
                            Text("총합")
                            Spacer()
                            Text("\(String(format: "%.0f", totalMinutes)) 분")
                        }
                        
                        HStack {
                            Text("평균")
                            Spacer()
                            Text("\(String(format: "%.1f", averageMinutes)) 분")
                        }
                        
                        HStack {
                            Text("최고 기록일")
                            Spacer()
                            Text("\(String(format: "%.0f", maxDay?.minutes ?? 0)) 분")
                        }
                        
                        HStack {
                            Text("총 일수")
                            Spacer()
                            Text("\(viewModel.monthlyTrend.count) 일")
                        }
                    }
                }
                
                // 결과 초기화
                Section {
                    Button("모든 결과 초기화") {
                        viewModel.clearResults()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("HealthKit 테스트")
            .disabled(viewModel.isLoading)
        }
    }
}

#Preview {
    HealthKitTestView()
}

// 임시
extension DateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}
