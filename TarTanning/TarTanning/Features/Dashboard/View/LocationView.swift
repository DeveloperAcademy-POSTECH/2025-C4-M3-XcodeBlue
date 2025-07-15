import SwiftUI
import CoreLocation

struct LocationView: View {
    @StateObject private var locationViewModel = LocationViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text("위도: \(locationViewModel.latitude)")
            Text("경도: \(locationViewModel.longitude)")
            Text("지역: \(locationViewModel.locality)")
            Text("세부지역: \(locationViewModel.subLocality)")
        }
        .padding()
    }
}

struct LocationView_Previews: PreviewProvider {
    static var previews: some View {
        LocationView()
    }
}
