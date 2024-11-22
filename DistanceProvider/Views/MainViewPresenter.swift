import UIKit
import CoreLocation


protocol MainPresenterProtocol: AnyObject {
    func success()
    func failure(error: Error)
    func showAlert(title: String, message: String, actions: [UIAlertAction]?)
}

protocol MainViewPresenterProtocol: AnyObject {
    init(view: MainPresenterProtocol, networkService: NetworkManagerProtocol)
    // Location Methods
    func getUserAddress(fromLocation location: CLLocation,
                        result: @escaping (_ location: CLLocation?, _ error: Error?) -> ())
    func updateLocation()
    var location: CLLocation? { get set }
    
    // TableViewCell Methods
    func getPersonData()
    func configureCell(_ cell: MainTableViewCell, forRowAt indexPath: IndexPath)
    func moveSelectedRowToTop(in tableView: UITableView, at indexPath: IndexPath)
    func coordinateText(_ latitude: Double, _ longitude: Double) -> String
    var persons: [PersonData]? { get set }
    var selectedPerson: PersonData? { get set }
}

protocol LocationPermissionProtocol: AnyObject {
    init(viewLocation: MainPresenterProtocol)
    func setUpLocationManager(delegate: CLLocationManagerDelegate)
    func checkLocationPermission()
    var clLocationManager: CLLocationManager! { get set }
}

final class MainViewPresenter: MainViewPresenterProtocol {
    var persons: [PersonData]?
    var selectedPerson: PersonData?
    var location: CLLocation?
    let networkService: NetworkManagerProtocol?
    
    weak var view: MainPresenterProtocol?
    
    required init(view: MainPresenterProtocol, networkService: NetworkManagerProtocol) {
        self.view = view
        self.networkService = networkService
        getPersonData()
    }
    
    // MARK: - Location methods
    
    func getUserAddress(fromLocation location: CLLocation,
                        result: @escaping (_ location: CLLocation?, _ error: Error?) -> ()) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            guard let location = placemarks?.first?.location else {
                result(nil, error)
                return
            }
            result(location, nil)
        }
    }
    
    func updateLocation() {
        for i in 0 ..< (persons?.count ?? 0) {
            if persons?[i].name == "User" {
                if let location = location {
                    self.persons?[i].locations.latitude = location.coordinate.latitude
                    self.persons?[i].locations.longitude = location.coordinate.longitude
                }
            } else {
                self.persons?[i].locations.latitude += Double.random(in: -5...5)
                self.persons?[i].locations.longitude += Double.random(in: -5...5)
                self.selectedPerson?.locations.latitude += Double.random(in: -5...5)
                self.selectedPerson?.locations.longitude += Double.random(in: -5...5)
            }
            self.view?.success()
        }
    }
    
    // MARK: - TableViewCell Methods
    
    func getPersonData() {
        networkService?.getPersonsData { [weak self] (persons, error) in
            if let persons = persons {
                self?.persons = persons
                self?.view?.success()
            } else if let error = error {
                self?.view?.failure(error: error)
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func configureCell(_ cell: MainTableViewCell, forRowAt indexPath: IndexPath) {
        guard let persons = persons else { return }
        var coordinates: String
        let person = selectedPerson != nil ? persons[indexPath.row + 1] : persons[indexPath.row]
        if let selectedPerson {
            coordinates = getDistanceBetweenTwoCoordinates(from: selectedPerson.locations, to: person.locations)
        } else if person.name == "User", let location = location {
            coordinates = coordinateText(location.coordinate.latitude, location.coordinate.longitude)
        } else {
            coordinates = coordinateText(person.locations.latitude, person.locations.longitude)
        }
        cell.configureText(person.name, coordinates, person.image)
    }
    
    func moveSelectedRowToTop(in tableView: UITableView, at indexPath: IndexPath) {
        let index = selectedPerson != nil ? indexPath.row + 1 : indexPath.row
        selectedPerson = persons?[index]
        persons?.remove(at: index)
        persons?.insert(selectedPerson!, at: 0)
        tableView.reloadData()
    }
    
    func coordinateText(_ latitude: Double, _ longitude: Double) -> String {
        "Coordinates - (\(latitude.rounded(toPlaces: 2))) - (\(longitude.rounded(toPlaces: 2)))"
    }
    
    private func getDistanceBetweenTwoCoordinates(from source: PersonLocation,
                                                  to destination: PersonLocation) -> String {
        let selectedLocation = CLLocationCoordinate2D(latitude: source.latitude,
                                                      longitude: source.longitude)
        let location = CLLocationCoordinate2D(latitude: destination.latitude,
                                              longitude: destination.longitude)
        let distanceInMeters = distanceBetweenToPoints(from: selectedLocation, to: location)
        let distanceInKm = distanceInMeters.distanceInKmString()
        return distanceInKm
    }
    
    //  Haversine formula for calculating the distance between two points on the earth's surface
    private func distanceBetweenToPoints(from location1: CLLocationCoordinate2D,
                                         to location2: CLLocationCoordinate2D) -> CLLocationDistance {
        let earthRadiusMeters: CLLocationDistance = 6_371_000
        
        // Convert latitude and longitude to radians
        let latitude1 = location1.latitude.toRadians()
        let latitude2 = location2.latitude.toRadians()
        let deltaLatitude = (location2.latitude - location1.latitude).toRadians()
        let deltaLongitude = (location2.longitude - location1.longitude).toRadians()
        
        // Calculating the angular distance between points on a sphere
        let a = sin(deltaLatitude / 2) * sin(deltaLatitude / 2) +
        cos(latitude1) * cos(latitude2) *
        sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
        
        // Calculating the actual distance between points
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        // Multiply by the radius of the earth to get the distance in meters
        return earthRadiusMeters * c
    }
}

final class LocationPermissionPresenter: LocationPermissionProtocol {
    var clLocationManager: CLLocationManager!
    
    weak var viewLocation: MainPresenterProtocol?
    
    required init(viewLocation: MainPresenterProtocol) {
        self.viewLocation = viewLocation
    }
    
    func setUpLocationManager(delegate: CLLocationManagerDelegate) {
        clLocationManager = CLLocationManager()
        clLocationManager?.delegate = delegate
        clLocationManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    
    func checkLocationPermission() {
        switch clLocationManager.authorizationStatus {
        case .notDetermined:
            clLocationManager.requestWhenInUseAuthorization()
        case .restricted:
            viewLocation?.showAlert(title: "Error",
                                    message: "Location access restricted from parent control",
                                    actions: nil)
        case .denied:
            let settingsAction = UIAlertAction(title: "Settings", style: .default) { (action) in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [ : ], completionHandler: nil)
                }
            }
            viewLocation?.showAlert(title: "Error",
                                    message: "Location access denied. Please allow it from Settings",
                                    actions: [settingsAction])
        case .authorizedAlways, .authorizedWhenInUse:
            clLocationManager.startUpdatingLocation()
        @unknown default:
            viewLocation?.showAlert(title: "Error",
                                    message: "Ooops. Something went wrong",
                                    actions: nil)
        }
    }
}
