//
//  WatchNavigationCoordinator.swift
//  TarTanningWatch Watch App
//
//  Created by taeni on 7/19/25.
//

import Foundation

class WatchNavigationCoordinator: ObservableObject {

    @Published var path: [WatchRoute] = []

    func push(_ path: WatchRoute) {
        self.path.append(path)
    }

    func pop() {
        self.path.removeLast()
    }

    func popToRoot() {
        self.path.removeAll()
    }
}
