//
//  HomeViewController.swift
//  surf
//
//  Created by uBack on 6/6/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit
import CoreLocation

class HomeViewController: UIViewController {

    @IBOutlet weak var proximalCollectionView: UICollectionView!
    private var proximalData = [Station]()
    private var proximalSelectedIndex = Int()
    private var selectedSnapshot = Snapshot()
    private var userLongitude = 0.0
    private var userLatitude = 0.0
    private var locationManager = CLLocationManager()

    private let imageArray = [#imageLiteral(resourceName: "crash.png"), #imageLiteral(resourceName: "wave.png"), #imageLiteral(resourceName: "flat.png"), #imageLiteral(resourceName: "wave.png"), #imageLiteral(resourceName: "flat.png")]
    override func viewDidLoad() {
        startActivityIndicator("Loading")
        super.viewDidLoad()
        parseStationList()
        setTableOrGetUserLocation()
    }
    
    
    
    // MARK: - Inital Load Logic
    
    private func setTableOrGetUserLocation(){
        let defaults = UserDefaults.standard
        userLongitude = defaults.object(forKey: "userLongitude") as? Double ?? 0.0
        userLatitude = defaults.object(forKey: "userLatitude") as? Double ?? 0.0
        
        if userLongitude != 0.0 && userLatitude != 0.0 {
            findDistancesFromUserLocation()
        }else{
            isAuthorizedtoGetUserLocation()
            
            if CLLocationManager.locationServicesEnabled() {
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            }
            
            if CLLocationManager.locationServicesEnabled() {
                locationManager.requestLocation();
            }
        }
    }
    
    //
    //MARK: - Location Services
    //
    
    private func findDistancesFromUserLocation(){
        
        // Used to convert latitude and longitude into miles
        // both numbers are approximate. One longitude at 40 degrees is about 53 miles however the true
        // number of miles is up to 69 at the equator and down to zero at the poles
        let approxMilesToLon = 53
        let approxMilesToLat = 69
        
        if (userLatitude != 0 && userLongitude != 0) {
            for index in 0..<proximalData.count{
                let station = proximalData[index]
                let absoluteLonDiff = Int(abs(station.lon - userLongitude).rounded())
                let absoluteLatDiff = Int(abs(station.lat - userLatitude).rounded())
                let distanceInMiles = (absoluteLatDiff * approxMilesToLat) + (absoluteLonDiff * approxMilesToLon)
                proximalData[index].distanceInMiles = distanceInMiles
            }
        }
        sortTableObjectsByDistance()
    }
    
    //if we have no permission to access user location, then ask user for permission.
    private func isAuthorizedtoGetUserLocation() {
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse     {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    
    //this method will be called each time when a user change his location access preference.
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            print("User allowed us to access location")
            locationManager.requestLocation();
        }
    }
    
    
    //this method is called by the framework on         locationManager.requestLocation();
    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Did location updates is called")
        print(locations)
        setLocationDataFromResponse()
    }
    
    internal func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Did location updates is called but failed getting location \(error)")
    }
    
    private func setLocationDataFromResponse(){
        if  let currentLocation = locationManager.location{
            userLatitude = currentLocation.coordinate.latitude
            userLongitude = currentLocation.coordinate.longitude
            findDistancesFromUserLocation()
            
            let defaults = UserDefaults.standard
            defaults.set(userLatitude, forKey: "userLatitude")
            defaults.set(userLongitude, forKey: "userLongitude")
            
        }
    }
    
    func sortTableObjectsByDistance(){
        proximalData = proximalData.sorted(by: {$0.distanceInMiles < $1.distanceInMiles })
        proximalCollectionView.reloadData()
        stopActivityIndicator()
    }
    
    //
    //MARK: - Buoy List for regional data station ids
    //
    
    private func parseStationList(){
        if let path = Bundle.main.path(forResource: "regionalBuoyList", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let metaData = jsonResult as? [[String : AnyObject]]{
                    for station in metaData {
                        guard let stationId = station["station"] else {return}
                        guard let lon = station["longitude"] as? Double else {return}
                        guard let lat = station["latitude"] as? Double else {return}
                        addStationWithIdLatLon(id: "\(stationId)", lat: lat, lon: lon, name: station["name"] as? String ?? "" )
                        stopActivityIndicator()
                    }
                }
            } catch {
                // handle error
            }
        }
    }
    
    private func addStationWithIdLatLon(id :String, lat : Double, lon : Double, name: String){
        let station : Station = Station(id: id, lat: lat, lon: lon, owner: nil, name: name, distance: 10000.0, distanceInMiles: 10000)
        proximalData.append(station)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let selectedStation = proximalData[proximalSelectedIndex]
        
        if let destinationVC = segue.destination as? ViewController {
            destinationVC.stationId = selectedStation.id
            destinationVC.currentSnapShot = selectedSnapshot
            if destinationVC.currentSnapShot != nil {
                destinationVC.snapshotComponents = ["wave" : true, "tide" : false, "wind" : false, "air" : false]
            }
        }
    }
    
    
    //
    //MARK: - Activty Indicator Controllers
    //
    
    func startActivityIndicator(_ message : String){
        let activityIndicatorView = ActivityIndicatorView().setupActivityIndicator(view: self.view, widthView: nil, backgroundColor:UIColor.black.withAlphaComponent(0.1), textColor: UIColor.gray, message: message)
        self.view.addSubview(activityIndicatorView)
    }
    
    func stopActivityIndicator(){
        for view in self.view.subviews {
            if view.isKind(of: ActivityIndicatorView.self){
                view.removeFromSuperview()
            }
        }
    }
    
}


extension HomeViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate{
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        proximalSelectedIndex = indexPath.row
        let selectedId = proximalData[proximalSelectedIndex].id
        
        startActivityIndicator("Loading")
        
        DispatchQueue.main.async{
            let data = createSnapshot(stationId: selectedId, finished: {})
            //remove spinner for response:
            if data.waveHgt != nil && data.waterTemp != nil {
                self.stopActivityIndicator()
                self.selectedSnapshot = data
                self.selectedSnapshot.stationName = self.proximalData[indexPath.row].name
                self.performSegue(withIdentifier: "showStationDetail", sender: self)
            }else{
                //if no data respond with alertview
                self.stopActivityIndicator()
                let alert = UIAlertController.init(title: "Not enough Data", message: "This bouy is not providing much data at the moment", preferredStyle: .alert)
                let doneAction = UIAlertAction(title: "Cancel", style: .destructive)
                alert.addAction(doneAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = proximalCollectionView.dequeueReusableCell(withReuseIdentifier: "ProximalCollectionViewCell", for: indexPath) as! ProxCollectionViewCell
        cell.imageView.image = imageArray[indexPath.row]
        cell.titleLabel.textColor = .black
        cell.titleLabel.text = self.proximalData[indexPath.row].name
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 140)
    }
    

}
