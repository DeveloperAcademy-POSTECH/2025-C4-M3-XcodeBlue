//
//  Date+Extension.swift
//  TarTanning
//
//  Created by Jun on 7/19/25.
//

import Foundation

extension Date {
    var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일, EEEE"
        return formatter.string(from: self)
    }
}
