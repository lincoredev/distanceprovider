import Foundation

struct PersonData: Codable {
    let name: String
    var locations: PersonLocation
    let image: String
}

struct PersonLocation: Codable {
    var latitude: Double
    var longitude: Double
}
