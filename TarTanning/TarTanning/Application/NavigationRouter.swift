//
//  NavigationRouter.swift
//  TarTanning
//
//  Created by J on 7/15/25.
//

import SwiftUI

class NavigationRouter: ObservableObject {
    @Published var path = NavigationPath()
    
    func push(_ route: Route) {
      path.append(route)
    }

    func pop() {
      if !path.isEmpty {
        path.removeLast()
      }
    }

    func reset() {
      path = NavigationPath()
    }
}
