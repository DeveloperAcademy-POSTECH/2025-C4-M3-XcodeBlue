//
//  ButtonStyleTypew.swift
//  TarTanning
//
//  Created by J on 7/14/25.
//

import Foundation
import SwiftUI

enum ButtonStyleType {
    case primary
    case secondary
    
    var backgroundColor: Color {
        switch self {
        case .primary: return .blue
        case .secondary: return .gray
        }
    }
    
    var textColor: Color {
        return .white
    }
}
