//
//  HourlyWeather.swift
//  TarTanning
//
//  Created by Jun on 7/17/25.
//

import Foundation

struct HourlyWeather: Codable {
    var date: Date // 실제 날짜/시간
    var uvIndex: Double // UV 지수 값
    var temperature: Double // 기온 (섭씨)
    
    // 시간대별 접근을 위한 computed property
    var hour: Int {
        Calendar.current.component(.hour, from: date)
    }
}

extension HourlyWeather {
    /// 24시간 UV 지수 Mock 데이터 (7월 20일 기준)
    static let mockHourlyWeather: [HourlyWeather] = {
        let calendar = Calendar.current
        let july20 = calendar.date(from: DateComponents(year: 2025, month: 7, day: 20))!
        
        return [
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 0, to: july20)!, uvIndex: 0.0, temperature: 22.0),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 1, to: july20)!, uvIndex: 0.0, temperature: 21.5),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 2, to: july20)!, uvIndex: 0.0, temperature: 21.0),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 3, to: july20)!, uvIndex: 0.0, temperature: 20.5),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 4, to: july20)!, uvIndex: 0.0, temperature: 20.0),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 5, to: july20)!, uvIndex: 0.0, temperature: 21.0),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 6, to: july20)!, uvIndex: 0.5, temperature: 22.5),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 7, to: july20)!, uvIndex: 1.5, temperature: 24.0),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 8, to: july20)!, uvIndex: 3.0, temperature: 26.0),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 9, to: july20)!, uvIndex: 5.0, temperature: 28.0),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 10, to: july20)!, uvIndex: 7.0, temperature: 30.0),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 11, to: july20)!, uvIndex: 8.5, temperature: 31.5),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 12, to: july20)!, uvIndex: 9.0, temperature: 32.0),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 13, to: july20)!, uvIndex: 8.5, temperature: 31.5),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 14, to: july20)!, uvIndex: 7.5, temperature: 30.5),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 15, to: july20)!, uvIndex: 6.0, temperature: 29.0),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 16, to: july20)!, uvIndex: 4.5, temperature: 27.5),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 17, to: july20)!, uvIndex: 3.0, temperature: 26.0),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 18, to: july20)!, uvIndex: 1.5, temperature: 24.5),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 19, to: july20)!, uvIndex: 0.5, temperature: 23.0),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 20, to: july20)!, uvIndex: 0.0, temperature: 22.0),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 21, to: july20)!, uvIndex: 0.0, temperature: 21.5),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 22, to: july20)!, uvIndex: 0.0, temperature: 21.0),
            HourlyWeather(date: calendar.date(byAdding: .hour, value: 23, to: july20)!, uvIndex: 0.0, temperature: 20.5)
        ]
    }()
}
