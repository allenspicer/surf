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
    
    var tableData = [Station]()
    var selectedStationIndex = Int()
    var selectedSnapshot = Snapshot()
    private var locationManager = CLLocationManager()
    private var userLongitude = 0.0
    private var userLatitude = 0.0
    private var latitudeLongitudeArray = [(Double,Double)]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        isAuthorizedtoGetUserLocation()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        }
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestLocation();
        }
        
        parseStationList()
    }
    
    
    func addStationWithId(id :String){
        let station : Station = Station(id: id, lat: "", lon: "", owner: "", name: "")
        tableData.append(station)
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
        return cell
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        selectedStationIndex = indexPath.row
        let selectedId = tableData[selectedStationIndex].id
        
        //display spinner here
        
        DispatchQueue.main.async{
            let data = bouyDataServiceRequest(stationId: selectedId, finished: {})
            
            //remove spinner for response:
            if data.waveHgt != nil && data.waterTemp != nil {
                self.selectedSnapshot = data
                self.performSegue(withIdentifier: "showStationDetail", sender: self)
            }else{
                //if no data respond with alertview
                let alert = UIAlertController.init(title: "Not enough Data", message: "This bouy is not providing much data at the moment", preferredStyle: .alert)
                let doneAction = UIAlertAction(title: "Cancel", style: .destructive)
                alert.addAction(doneAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let selectedStation = tableData[selectedStationIndex]
        
        if let destinationVC = segue.destination as? ViewController {
            destinationVC.stationId = selectedStation.id
            destinationVC.stationName = selectedStation.name
            destinationVC.currentSnapShot = selectedSnapshot
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
//                            if let stationId = station["-id"]{
//                                addStationWithId(id: stationId)
//                            }
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
                        if let stationId = station["station"]{
                            addStationWithId(id: "\(stationId)")
                        }
                    }
                }
            } catch {
                // handle error
            }
        }
    }
    
    // MARK: - User Location

    func findDataWithUserLocation(){
        var minDistance = 0.0
        var coordAtMinDistance = (0.0,0.0)
        
        if (userLatitude != 0 && userLongitude != 0) {
            for coord in latitudeLongitudeArray{
                
                guard let distanceFromNewPoint = pow((coord.0 - userLatitude), 2) + pow((coord.1 - userLongitude), 2) as Double? else {
                    return
                }
                
                
                //calculate distance from point to user and previous point to user
                //if new point is closer than previous point
                if (minDistance == 0.0 || minDistance > distanceFromNewPoint){
                    //save coorindates of new point over top
                    minDistance = distanceFromNewPoint
                    coordAtMinDistance = coord
                }
            }
        }
    }
    
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
            userLongitude = currentLocation.coordinate.latitude
            findDataWithUserLocation()
            //user location is available now, can modify or trigger here with it
        }
    }
    
    
}
