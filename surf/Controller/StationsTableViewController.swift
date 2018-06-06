//
//  StationsTableViewController.swift
//  surf
//
//  Created by Allen Spicer on 5/14/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit
import CoreLocation

class StationsTableViewController: UITableViewController, CLLocationManagerDelegate{
    
    var navBar: UINavigationBar?
    var tableData = [Station]()
    var selectedStationIndex = Int()
    var selectedSnapshot = Snapshot()
    var activityIndicatorView = ActivityIndicatorView()
    private var locationManager = CLLocationManager()
    private var userLongitude = 0.0
    private var userLatitude = 0.0
    private var latitudeLongitudeArray = [(Double,Double)]()

    override func viewDidLoad() {
                        
        super.viewDidLoad()
        startActivityIndicator("Getting Your Location")
        tableView.delegate = self
        tableView.dataSource = self
        parseStationList()
        setTableOrGetUserLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return tableData.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        cell.textLabel?.text = "\(tableData[indexPath.row].id)"
        if tableData[indexPath.row].distanceInMiles == 10000 {
            cell.detailTextLabel?.text = "calculating..."
        }else{
            let miles = tableData[indexPath.row].distanceInMiles
                cell.detailTextLabel?.text = "\(miles) mi."
        }
        return cell
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        selectedStationIndex = indexPath.row
        let selectedId = tableData[selectedStationIndex].id
        
        startActivityIndicator("Loading")
        
        DispatchQueue.main.async{
            let data = createSnapshot(stationId: selectedId, finished: {})
            //remove spinner for response:
            if data.waveHgt != nil && data.waterTemp != nil {
                self.stopActivityIndicator()
                self.selectedSnapshot = data
                self.selectedSnapshot.stationName = self.tableData[indexPath.row].name
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
    
    // MARK: - Inital Load Logic
    
    func setTableOrGetUserLocation(){
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
    

    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let selectedStation = tableData[selectedStationIndex]
        
        if let destinationVC = segue.destination as? ViewController {
            destinationVC.stationId = selectedStation.id
            destinationVC.currentSnapShot = selectedSnapshot
            if destinationVC.currentSnapShot != nil {
                destinationVC.snapshotComponents = ["wave" : true, "tide" : false, "wind" : false]
            }
        }
    }
 
    // MARK: - Parse Data from JSON

//    Parsing for full data set: bouys.json
//    func parseStationList(){
//        if let path = Bundle.main.path(forResource: "staticStationList", ofType: "json") {
//            do {
//                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
//                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
//                if let metaData = jsonResult as? Dictionary<String, AnyObject>{
//                    if let stationDataArray = metaData["station"] as? [[String : String]]{
//                        for station in stationDataArray{
//                            guard let stationId = station["station"] else {return}
//                            guard let lon = station["longitude"] as? Double else {return}
//                            guard let lat = station["latitude"] as? Double else {return}
//                            addStationWithIdLatLon(id: "\(stationId)", lat: lat, lon: lon)
//
//                        }
//                    }
//
//                }
//            } catch {
//                // handle error
//            }
//        }
//    }
    
    func parseStationList(){
        if let path = Bundle.main.path(forResource: "staticStationList", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let metaData = jsonResult as? [[String : AnyObject]]{
                    for station in metaData {
                        guard let stationId = station["station"] else {return}
                        guard let lon = station["longitude"] as? Double else {return}
                        guard let lat = station["latitude"] as? Double else {return}
                        addStationWithIdLatLon(id: "\(stationId)", lat: lat, lon: lon, name: station["name"] as? String ?? "" )
                    }
                }
            } catch {
                // handle error
            }
        }
    }
    
    func addStationWithIdLatLon(id :String, lat : Double, lon : Double, name: String){
        let station : Station = Station(id: id, lat: lat, lon: lon, owner: nil, name: name, distance: 10000.0, distanceInMiles: 10000)
        tableData.append(station)
    }
    

    // MARK: - User Location
    
    //if we have no permission to access user location, then ask user for permission.
    func isAuthorizedtoGetUserLocation() {
        
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse     {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    
    //this method will be called each time when a user change his location access preference.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            print("User allowed us to access location")
            locationManager.requestLocation();
        }
    }
    
    
    //this method is called by the framework on         locationManager.requestLocation();
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Did location updates is called")
        print(locations)
        setLocationDataFromResponse()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Did location updates is called but failed getting location \(error)")
    }
    
    
    func setLocationDataFromResponse(){
        if  let currentLocation = locationManager.location{
            userLatitude = currentLocation.coordinate.latitude
            userLongitude = currentLocation.coordinate.longitude
            findDistancesFromUserLocation()
            
            let defaults = UserDefaults.standard
            defaults.set(userLatitude, forKey: "userLatitude")
            defaults.set(userLongitude, forKey: "userLongitude")

        }
    }
    
    func findDistancesFromUserLocation(){
        
        // Used to convert latitude and longitude into miles
        // both numbers are approximate. One longitude at 40 degrees is about 53 miles however the true
        // number of miles is up to 69 at the equator and down to zero at the poles
        let approxMilesToLon = 53
        let approxMilesToLat = 69
        
        if (userLatitude != 0 && userLongitude != 0) {
            for index in 0..<tableData.count{
                let station = tableData[index]
                let absoluteLonDiff = Int(abs(station.lon - userLongitude).rounded())
                let absoluteLatDiff = Int(abs(station.lat - userLatitude).rounded())
                let distanceInMiles = (absoluteLatDiff * approxMilesToLat) + (absoluteLonDiff * approxMilesToLon)
                tableData[index].distanceInMiles = distanceInMiles
            }
        }
        sortTableObjectsByDistance()
    }
    
    func sortTableObjectsByDistance(){
        tableData = tableData.sorted(by: {$0.distanceInMiles < $1.distanceInMiles })
        self.tableView.reloadData()
        stopActivityIndicator()
    }
    
    func startActivityIndicator(_ message : String){
        activityIndicatorView = ActivityIndicatorView().setupActivityIndicator(view: self.view, widthView: nil, backgroundColor:UIColor.black.withAlphaComponent(0.1), textColor: UIColor.gray, message: message)
        self.view.addSubview(activityIndicatorView)
        self.tableView.alwaysBounceVertical = false
    }

    func stopActivityIndicator(){
        for view in self.view.subviews {
            if view.isKind(of: ActivityIndicatorView.self){
                view.removeFromSuperview()
                self.tableView.alwaysBounceVertical = true
            }
        }
    }

    
}
