//
//  ViewController.swift
//  surfbreak
//
//  Created by Allen Spicer on 7/26/18.
//  Copyright © 2018 surfbreak. All rights reserved.
//

import UIKit
import CoreLocation
import Disk

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
            guard let stations = self.allStations else {return}
            
            //check persistence for user favorites
            self.getUserFavoritesFromPersistence()
            
            if self.componentsChecklist.count > 0 {
                
                //if favorites check persistence for records
                self.checkForDownloadedSnapshots()
                    
                //for each favorite that does not have a snapshot
                //make data requests
                for key in self.componentsChecklist.keys {
                    self.setDataClientsForStation(snapshotId: key, allStations: stations)
                }
            }
            //if no favorites, or if transition to home
            self.checkComponentsThenSegue()
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
    //MARK: - Favorites from persistence
    //
    
    private func getUserFavoritesFromPersistence (){
        
        self.componentsChecklist[100] = SnapshotComponents()

//        var favoritesArray = [Favorite]()
//        do {
//            favoritesArray = try context.fetch(Favorite.fetchRequest())
//        }
//        catch {
//            print("Failed to retrieve Favorite Entity from context.")
//        }
//        for favorite in favoritesArray {
//            var newComponentsStruct = SnapshotComponents()
//            newComponentsStruct.snapshot = Snapshot()
//            if let nickname = favorite.name {
//                newComponentsStruct.snapshot?.nickname = nickname
//            }
//            self.componentsChecklist[Int(favorite.id)] = newComponentsStruct
//        }
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
    //MARK: - check persistence for snapshot records
    //
    func checkForDownloadedSnapshots(){
        var favoritesArray = [Snapshot]()
        do {
            favoritesArray = try Disk.retrieve("favorites", from: .caches, as: [Snapshot].self)
        }catch{
            print("Saving to automatic storage with Disk failed. Error is: \(error)")
        }
        
        // remove snapshotcomponents entry where we have data from persistence
        for favoriteSnapshot in favoritesArray where self.componentsChecklist[Int(favoriteSnapshot.id)] != nil {
            
            //remove the entry from componentsChecklist
            self.componentsChecklist.removeValue(forKey: Int(favoriteSnapshot.id))
            
            //then populate persistence snapshot into favoriteSnapshots array
            favoriteSnapshots?.append(favoriteSnapshot)
        }
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
        componentsChecklist[snapshot.id]?.bouy = true
        componentsChecklist[snapshot.id]?.bouyTimeStamp = Date()
        componentsChecklist[snapshot.id]?.snapshot = snapshot
        setDataClientsFor(snapshot: snapshot)
    }
}

extension InitialViewController : TideClientDelegate{
    func didFinishTideTask(sender: TideClient, tides: [Tide], snapshot: Snapshot) {
        print("The Tide Client has returned an array of tides.")
        componentsChecklist[snapshot.id]?.tide = true
        componentsChecklist[snapshot.id]?.tideTimeStamp = Date()
        guard let currentSnapshot = componentsChecklist[snapshot.id]?.snapshot else {return}
        componentsChecklist[snapshot.id]?.snapshot = tideClient?.addTideDataToSnapshot(currentSnapshot, tideArray: tides)
        checkComponentsThenSegue()
    }
}

extension InitialViewController : WindClientDelegate{
    func didFinishWindTask(sender: WindClient, winds: [Wind], snapshot: Snapshot) {
        print("The Wind Client has returned an array of winds.")
        componentsChecklist[snapshot.id]?.wind = true
        componentsChecklist[snapshot.id]?.windTimeStamp = Date()
        guard let currentSnapshot = componentsChecklist[100]?.snapshot else {return}
        componentsChecklist[snapshot.id]?.snapshot = windClient?.addWindDataToSnapshot(currentSnapshot, windArray: winds)
        self.surfQuality?.createSurfQualityAssesment()
        surfQuality?.delegate = self
    }
}

extension InitialViewController : AirTempDelegate{
    func didFinishAirTempTask(sender: AirTempClient, airTemps: [AirTemp], snapshot: Snapshot) {
        print("The Air Temp Client has returned an array of air temps.")
        componentsChecklist[snapshot.id]?.air = true
        componentsChecklist[snapshot.id]?.airTimeStamp = Date()
        guard let currentSnapshot = componentsChecklist[snapshot.id]?.snapshot else {return}
        componentsChecklist[snapshot.id]?.snapshot = airTempClient?.addAirTempDataToSnapshot(currentSnapshot, AirTempArray: airTemps)
        checkComponentsThenSegue()
    }
}

extension InitialViewController : SurfQualityDelegate{
    func didFinishSurfQualityTask(sender: SurfQuality, snapshot: Snapshot) {
        componentsChecklist[snapshot.id]?.quality = true
        componentsChecklist[snapshot.id]?.completeTimestamp = Date()
//        guard let currentSnapshot = componentsChecklist[100]?.snapshot else {return}
//        componentsChecklist[100]?.snapshot = surfQuality?.getSnapshotWithSurfQuality()
        checkComponentsThenSegue()
    }
    
}

extension InitialViewController {
    
    func checkComponentsThenSegue(){
        for key in componentsChecklist.keys {
            if componentsChecklist[key]?.bouy == false || componentsChecklist[key]?.air == false ||  componentsChecklist[key]?.wind == false || componentsChecklist[key]?.tide == false || userLocation == (0.0,0.0){
                return
            }
        }
        
        //if nothing in componentsChecklist or if all components are downloaded segue
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "segueToHome", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destinationVC = segue.destination as? HomeViewController else { return}
        guard let stations = allStations else {return}
        destinationVC.allStations = stations
        destinationVC.userLocation = userLocation
        if let snapshots = favoriteSnapshots {
            destinationVC.favoritesSnapshots = snapshots
            saveCompleteSnapshotToPersistence(with: snapshots)
        }
    }
}

extension InitialViewController {
    
    func saveCompleteSnapshotToPersistence(with snapshots: [Snapshot]){
        
        DispatchQueue.global(qos:.utility).async{
            if Disk.exists("favorites", in: .caches) {
                do {
                    try Disk.append(snapshots, to: "favorites", in: .caches)
                }catch{
                    print("Appending to automatic storage with Disk failed. Error is: \(error)")
                }
            }else{
                do {
                    try Disk.save(snapshots, to: .caches, as: "favorites")
                }catch{
                    print("Saving to automatic storage with Disk failed. Error is: \(error)")
                }
            }

        }
//
//            //scrub records: if a wave in persistence is more than 5 minutes old remove it from local and persistence
//            let fiveMinutes: TimeInterval = 5.0 * 60.0
//
//            for wave in waveDictionary {
//                guard let timestamp = wave.value.timestamp else {return}
//                if abs(timestamp.timeIntervalSinceNow) > fiveMinutes{
//                    DispatchQueue.main.async {
//                        self.context.delete(wave.value)
//                    }
//                    waveDictionary.removeValue(forKey: wave.key)
//                }
//            }
//            DispatchQueue.main.async {
//                (UIApplication.shared.delegate as! AppDelegate).saveContext()
//            }
        
        
    }
}

