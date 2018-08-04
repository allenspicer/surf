//
//  ViewController.swift
//  surfbreak
//
//  Created by Allen Spicer on 7/26/18.
//  Copyright © 2018 surfbreak. All rights reserved.
//

import UIKit
import CoreLocation

final class InitialViewController: UIViewController {
    
    private var locationManager = CLLocationManager()
    private var userLocation = (0.0,0.0)
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private var componentsChecklist = [Int : SnapshotComponents]()

    private var buoyClient : BuoyClient?
    private var tideClient : TideClient?
    private var windClient : WindClient?
    private var airTempClient : AirTempClient?
    private var surfQuality : SurfQuality?
    
    var allStations : [Station]? = nil
    var favoriteSnapshots : [Snapshot]? = nil


    override func viewDidLoad() {
        //set up activity indicator
        displayActivityIndicator()
        
        DispatchQueue.global(qos:.utility).async{

            //trigger user location process
            self.getUserLocation()
            
            //get all stations from local file
            self.loadStationDataFromFile()
            
            //check persistence for user favorites
            //if none segue
            
            //for each favorite create a component in the checklist and make data requests
            self.componentsChecklist[100] = SnapshotComponents()
            guard let stations = self.allStations else {return}
            self.setDataClientsForStation(snapshotId: 100, allStations: stations)

            // load series of data points (clients)
        }
    }
    
    //
    //MARK: - Activity Indicator
    //
    
    
    func displayActivityIndicator(){
        let activityIndicatorView = ActivityIndicatorView().setupActivityIndicator(view: self.view, widthView: nil, backgroundColor:UIColor.black.withAlphaComponent(0.1), textColor: UIColor.gray, message: "loading...")
        self.view.addSubview(activityIndicatorView)
    }
    
    //
    //MARK: - location services
    //

    private func getUserLocation (){
        var locationArray = [UserLocation]()
        do {
            locationArray = try context.fetch(UserLocation.fetchRequest())
        }
        catch {
            print("Failed to retrieve UserLocation Entity from context.")
        }
        for location in locationArray {
            userLocation.0 = location.latitude
            userLocation.1 = location.longitude
        }

        if userLocation.0 != 0.0 && userLocation.1 != 0.0 {
            print("User location available from persistence: \(userLocation)")

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
    //MARK: - station list handling
    //
    
    func loadStationDataFromFile(){
        let fileName = "regionalBuoyList"
        guard let stations = loadJson(fileName) else {return}
        allStations = stations
    }
    
    func loadJson(_ fileName: String) -> [Station]? {
        if let url = Bundle.main.url(forResource: fileName, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let jsonData = try decoder.decode([Station].self, from: data)
                return jsonData
            } catch {
                print("error:\(error)")
            }
        }
        return nil
    }
    
    //
    //MARK: - Init networking handlers
    //
    
    
    func setDataClientsForStation(snapshotId : Int, allStations : [Station]){
        buoyClient = BuoyClient(snapshotId: snapshotId, allStations : allStations)
        buoyClient?.delegate = self
        buoyClient?.createBuoyData()
    }
    
    func setDataClientsFor(snapshot : Snapshot){
        
        tideClient = TideClient(currentSnapshot: snapshot)
        tideClient?.delegate = self
        tideClient?.createTideData()

        windClient = WindClient(currentSnapshot: snapshot)
        windClient?.delegate = self
        windClient?.createWindData()

        airTempClient = AirTempClient(currentSnapshot: snapshot)
        airTempClient?.delegate = self
        airTempClient?.createAirTempData()
    }

}

extension InitialViewController : CLLocationManagerDelegate{
    //if we have no permission to access user location, then ask user for permission.
    private func isAuthorizedtoGetUserLocation() {
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse     {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    
    //this method will be called each time a user changes his location access preference.
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            print("User allowed us to access location")
            locationManager.requestLocation()
        }
    }
    
    
    //this method is called by the framework on         locationManager.requestLocation();
    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Did location updates called")
        setLocationDataFromResponse()
    }
    
    internal func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Did location updates called but failed getting location \(error)")
    }
    
    private func setLocationDataFromResponse(){
        if  let currentLocation = locationManager.location{
            userLocation.0 = currentLocation.coordinate.latitude
            userLocation.1 = currentLocation.coordinate.longitude
            print("User location available from gps: \(userLocation)")

            //save user location to persistence
            DispatchQueue.main.async {
                //add to persistent container
                let location = UserLocation(context: self.context)
                location.timestamp = Date()
                location.latitude = self.userLocation.0
                location.longitude = self.userLocation.1
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
                self.checkComponentsThenSegue()
            }
        }
    }
}

extension InitialViewController : BuoyClientDelegate{
    func didFinishBuoyTask(sender: BuoyClient, snapshot: Snapshot, stations: [Station]) {
        print("The Buoy Client has returned a populated snapshot. Contents are: \(snapshot)")
        if (allStations == nil) { allStations = stations }
        componentsChecklist[100]?.bouy = true
        componentsChecklist[100]?.bouyTimeStamp = Date()
        componentsChecklist[100]?.snapshot = snapshot
        setDataClientsFor(snapshot: snapshot)
    }
}

extension InitialViewController : TideClientDelegate{
    func didFinishTideTask(sender: TideClient, tides: [Tide]) {
        print("The Tide Client has returned an array of tides.")
        componentsChecklist[100]?.tide = true
        componentsChecklist[100]?.tideTimeStamp = Date()
        guard let currentSnapshot = componentsChecklist[100]?.snapshot else {return}
        componentsChecklist[100]?.snapshot = tideClient?.addTideDataToSnapshot(currentSnapshot, tideArray: tides)
        checkComponentsThenSegue()
    }
}

extension InitialViewController : WindClientDelegate{
    func didFinishWindTask(sender: WindClient, winds: [Wind]) {
        print("The Wind Client has returned an array of winds.")
        componentsChecklist[100]?.wind = true
        componentsChecklist[100]?.windTimeStamp = Date()
        guard let currentSnapshot = componentsChecklist[100]?.snapshot else {return}
        componentsChecklist[100]?.snapshot = windClient?.addWindDataToSnapshot(currentSnapshot, windArray: winds)
        self.surfQuality?.createSurfQualityAssesment()
        surfQuality?.delegate = self
        checkComponentsThenSegue()
    }
}

extension InitialViewController : AirTempDelegate{
    func didFinishAirTempTask(sender: AirTempClient, airTemps: [AirTemp]) {
        print("The Air Temp Client has returned an array of air temps.")
        componentsChecklist[100]?.air = true
        componentsChecklist[100]?.airTimeStamp = Date()
        guard let currentSnapshot = componentsChecklist[100]?.snapshot else {return}
        componentsChecklist[100]?.snapshot = airTempClient?.addAirTempDataToSnapshot(currentSnapshot, AirTempArray: airTemps)
        checkComponentsThenSegue()
    }
}

extension InitialViewController : SurfQualityDelegate{
    func didFinishSurfQualityTask(sender: SurfQuality) {
        componentsChecklist[100]?.quality = true
        componentsChecklist[100]?.completeTimestamp = Date()
//        guard let currentSnapshot = componentsChecklist[100]?.snapshot else {return}
//        componentsChecklist[100]?.snapshot = surfQuality?.getSnapshotWithSurfQuality()
        checkComponentsThenSegue()
    }
    
}

extension InitialViewController {
    func checkComponentsThenSegue(){
        print("Components are:")
        print(componentsChecklist[100])
        if componentsChecklist[100]?.bouy == true && componentsChecklist[100]?.air == true && componentsChecklist[100]?.wind == true && componentsChecklist[100]?.tide == true && userLocation != (0.0,0.0){
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "segueToHome", sender: self)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destinationVC = segue.destination as? HomeViewController else { return}
        guard let stations = allStations else {return}
        destinationVC.allStations = stations
        destinationVC.userLocation = userLocation
        guard let snapshots = self.componentsChecklist[100]?.snapshot else {return}
        destinationVC.favoritesSnapshots = [snapshots]
    }

}

