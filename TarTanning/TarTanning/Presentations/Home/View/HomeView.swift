//
//  HomeView.swift
//  TarTanning
//
//  Created by taeni on 7/25/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @Environment(\.modelContext) private var modelContext
    
    init(modelContext: ModelContext) {
        self._viewModel = StateObject(wrappedValue: HomeViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 헤더
                    headerSection
                    
                    // 로딩 상태
                    if viewModel.isLoading {
                        loadingSection
                    }
                    
                    // 에러 상태
                    if let errorMessage = viewModel.errorMessage {
                        errorSection(errorMessage)
                    }
                    
                    // 날씨 정보
                    if let weather = viewModel.locationWeather {
                        weatherInfoSection(weather)
                    }
                    
                    // SwiftData 저장 상태
                    dataStatusSection
                    
                    // 테스트 버튼들
                    testButtonsSection
                }
                .padding()
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.loadWeatherData()
            }
        }
        .task {
            await viewModel.loadWeatherData()
        }
    }
    
    // MARK: - UI Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SwiftData 저장 테스트")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("실제 WeatherKit을 통해 mockSeoul의 날씨 정보가 SwiftData에 제대로 저장되는지 확인합니다.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var loadingSection: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("WeatherKit에서 날씨 데이터를 불러오는 중...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func errorSection(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundColor(.red)
            
            Text("오류 발생")
                .font(.headline)
                .foregroundColor(.red)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemRed).opacity(0.1))
        .cornerRadius(12)
    }
    
    private func weatherInfoSection(_ weather: LocationWeather) -> some View {
        VStack(spacing: 16) {
            // 기본 정보
            VStack(spacing: 8) {
                Text(weather.city)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(weather.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 일출/일몰 정보
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Image(systemName: "sunrise.fill")
                        .foregroundColor(.orange)
                    Text("일출")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(weather.sunriseTime?.formatted(date: .omitted, time: .shortened) ?? "N/A")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(spacing: 4) {
                    Image(systemName: "sunset.fill")
                        .foregroundColor(.orange)
                    Text("일몰")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(weather.sunsetTime?.formatted(date: .omitted, time: .shortened) ?? "N/A")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            Divider()
            
            // 시간별 예보 개수
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                
                Text("시간별 예보 (4AM-11PM)")
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(weather.hourlyWeathers.count)개")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            // 시간별 UV 지수 미리보기 (처음 6개)
            if !weather.hourlyWeathers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("UV 지수 미리보기")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(weather.hourlyWeathers.prefix(6), id: \.date) { hourly in
                            VStack(spacing: 4) {
                                Text("\(hourly.hour)시")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Text(String(format: "%.1f", hourly.uvIndex))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(uvColor(hourly.uvIndex))
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var dataStatusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "database.fill")
                    .foregroundColor(.green)
                
                Text("SwiftData 저장 상태")
                    .font(.headline)
                
                Spacer()
                
                Text("\(viewModel.savedDataCount)개")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            Text("총 저장된 LocationWeather 데이터 개수")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGreen).opacity(0.1))
        .cornerRadius(12)
    }
    
    private var testButtonsSection: some View {
        VStack(spacing: 12) {
            Text("테스트 기능")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                Button("새로고침") {
                    Task {
                        await viewModel.loadWeatherData()
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                
                Button("오늘 데이터 조회") {
                    Task {
                        let todayData = await viewModel.getTodayData()
                        print("📅 오늘 데이터: \(todayData.count)개")
                        for data in todayData {
                            print("  - \(data.city) (\(data.date.formatted()))")
                        }
                    }
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("모든 데이터 조회") {
                    Task {
                        let allData = await viewModel.getAllSavedData()
                        print("📊 모든 데이터: \(allData.count)개")
                        for data in allData {
                            print("  - \(data.city) (\(data.date.formatted()))")
                        }
                    }
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("모든 데이터 삭제") {
                    Task {
                        await viewModel.clearAllData()
                    }
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func uvColor(_ uvIndex: Double) -> Color {
        switch uvIndex {
        case 0..<3:
            return .green
        case 3..<6:
            return .yellow
        case 6..<8:
            return .orange
        case 8..<11:
            return .red
        default:
            return .purple
        }
    }
}

#Preview {
    HomeView(modelContext: try ModelContainer(for: LocationWeather.self).mainContext)
} 