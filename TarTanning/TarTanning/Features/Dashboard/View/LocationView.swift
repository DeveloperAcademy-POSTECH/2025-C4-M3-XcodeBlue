import SwiftUI
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()

    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    @Published var locality: String = ""
    @Published var subLocality: String = ""

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude

        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else { return }
            self.locality = placemark.locality ?? ""
            self.subLocality = placemark.subLocality ?? ""
        }
    }
}

struct LocationView: View {
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        VStack(spacing: 16) {
            Text("위도: \(locationManager.latitude)")
            Text("경도: \(locationManager.longitude)")
            Text("지역: \(locationManager.locality)")
            Text("세부지역: \(locationManager.subLocality)")
        }
        .padding()
    }
}

struct LocationView_Previews: PreviewProvider {
    static var previews: some View {
        LocationView()
    }
}

