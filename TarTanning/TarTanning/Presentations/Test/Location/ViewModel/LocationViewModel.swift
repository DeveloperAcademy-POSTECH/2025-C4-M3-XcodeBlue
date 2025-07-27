////
////  LocationViewModel.swift
////  TarTanning
////
////  Created by 강진 on 7/14/25.
////
//
//import Foundation
//import CoreLocation
//import Combine
//
//class LocationViewModel: ObservableObject {
//    @Published var latitude: Double = 0.0
//    @Published var longitude: Double = 0.0
//    @Published var locality: String = ""
//  
//    private var locationManager = LocationManager.shared
//
//    init() {
//        locationManager.$latitude.assign(to: &$latitude)
//        locationManager.$longitude.assign(to: &$longitude)
//        locationManager.$locality.assign(to: &$locality)
//    }
//}
