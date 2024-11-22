import UIKit
import CoreLocation

final class MainViewController: UIViewController {
    var presenter: MainViewPresenterProtocol!
    let networkManager = PersonNetworkManager()
    var locationPresenter: LocationPermissionProtocol!
    let tableViewHeight: CGFloat = 100
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(MainTableViewCell.self,
                           forCellReuseIdentifier: MainTableViewCell.identifier)
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationController()
        configureTableView()
        
        presenter = MainViewPresenter(view: self, networkService: networkManager)
        locationPresenter = LocationPermissionPresenter(viewLocation: self)
        locationPresenter.setUpLocationManager(delegate: self)
        
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self]_ in
            self?.presenter.updateLocation()
        }
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(appMovedToBackground),
                                       name: UIApplication.didBecomeActiveNotification,
                                       object: nil)
    }
    
    @objc func appMovedToBackground() {
        locationPresenter.checkLocationPermission()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locationPresenter.checkLocationPermission()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    private func setUpNavigationController() {
        navigationItem.title = "Persons"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func configureTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
    }
}

// MARK: - TableViewDelegate

extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        tableViewHeight
    }
}

// MARK: - TableViewDataSource

extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        presenter.selectedPerson != nil
        ? ((presenter.persons?.count ?? 1) - 1) // -1 when cell goes to header
        : (presenter.persons?.count ?? 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MainTableViewCell.identifier,
                                                       for: indexPath) as? MainTableViewCell else {
            return UITableViewCell()
        }
        presenter.configureCell(cell, forRowAt: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presenter.moveSelectedRowToTop(in: tableView, at: indexPath)
    }
}

// MARK: - Header TableView

extension MainViewController {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        presenter.selectedPerson != nil ? tableViewHeight : 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let selectedPerson = presenter.selectedPerson else { return nil }
        let coordinates = presenter.coordinateText(selectedPerson.locations.latitude,
                                                   selectedPerson.locations.longitude)
        let tap = UITapGestureRecognizer(target: self, action:#selector(self.tapOnHeader(_:)))
        let header = tableView.dequeueReusableCell(withIdentifier: MainTableViewCell.identifier) as? MainTableViewCell
        header?.addGestureRecognizer(tap)
        header?.backgroundColor = .systemGray3
        header?.configureText(selectedPerson.name, coordinates, selectedPerson.image)
        return header
    }
    
    @objc func tapOnHeader(_ sender: UITapGestureRecognizer) {
        presenter.selectedPerson = nil
        tableView.reloadData()
    }
}

// MARK: - LocationManagerDelegate

extension MainViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(" didFailWithError - \(error.localizedDescription)")
        showAlert(withTitle: "Error", andMessage: error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            presenter.getUserAddress(fromLocation: location) { (addressLocation, error) in
                if let error = error {
                    print("Error getting address: \(error.localizedDescription)")
                }
            }
            presenter.location = location
            self.tableView.reloadData()
        }
    }
}

// MARK: - MainPresenterProtocol

extension MainViewController: MainPresenterProtocol {
    func success() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func failure(error: Error) {
        print(error.localizedDescription)
    }
    
    func showAlert(title: String, message: String, actions: [UIAlertAction]?) {
        guard let actions else {
            showAlert(withTitle: title, andMessage: message)
            return
        }
        showAlert(withTitle: title, andMessage: message, andActions: actions)
    }
}
