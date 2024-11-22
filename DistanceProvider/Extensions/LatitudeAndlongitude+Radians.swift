import CoreLocation

extension CLLocationDegrees {
    func toRadians() -> CLLocationDegrees {
        return self * .pi / 180
    }
}
