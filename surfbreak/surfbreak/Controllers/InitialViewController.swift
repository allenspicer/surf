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
    private var userLocation : UserLocation? = nil
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private var componentsChecklist = [Int : SnapshotComponents]()

    private var buoyClient : BuoyClient?
    private var tideClient : TideClient?
    private var windClient : WindClient?
    private var airTempClient : AirTempClient?
    private var surfQuality : SurfQuality?
    
    var allStations : [Station]? = nil
    var allPersistenceSnapshots = [Snapshot]()
    var favoriteSnapshots : [Snapshot]? = nil


    override func viewDidLoad() {
        //set up activity indicator
        startActivityIndicator("Loading...")
        
        DispatchQueue.global(qos:.utility).async{

            //trigger user location process
            self.getUserLocation()
            
            //get all stations from local file
            self.loadStationDataFromFile()
            guard let stations = self.allStations else {return}
            
            //check persistence for user favorites
            self.getUserFavoritesFromPersistence()
            
            //check persistence for saved snapshots
            self.getAndScrubAllPersistenceSnapshots()
            
            if self.componentsChecklist.count > 0 {
                    
                //for each favorite that does not have a snapshot
                for key in self.componentsChecklist.keys {
                    
                    //if favorites check persistence for records
                    if !self.checkForDownloadedSnapshot(with: key){
                        self.setDataClientsForStation(snapshotId: key, allStations: stations)
                    }
                }
            }
            //if no favorites, or if transition to home
            self.checkComponentsThenSegue()
        }
    }
    
    //
    //MARK: - Activty Indicator Triggers
    //
    
    private func startActivityIndicator(_ message : String){
        let activityIndicatorView = ActivityIndicatorView().setupActivityIndicator(view: self.view, widthView: nil, backgroundColor:UIColor.black.withAlphaComponent(0.1), textColor: UIColor.gray, message: message)
        self.view.addSubview(activityIndicatorView)
    }
    
    private func stopActivityIndicator(){
        for view in self.view.subviews {
            if view.isKind(of: ActivityIndicatorView.self){
                view.removeFromSuperview()
            }
        }
    }
    
    //
    //MARK: - location services
    //

    private func getUserLocation (){
        if Disk.exists(DefaultConstants.userLocation, in: .caches) {
            do {
                userLocation = try Disk.retrieve(DefaultConstants.userLocation, from: .caches, as: UserLocation.self)
            }catch{
                print("Retrieving from automatic storage with Disk failed. Error is: \(error)")
            }
        }
        
        if userLocation != nil{
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
        var favoritesArray = [Favorite]()
        if Disk.exists(DefaultConstants.favorites, in: .caches) {
            do{
                favoritesArray = try Disk.retrieve(DefaultConstants.favorites, from: .caches, as: [Favorite].self)
            }catch{
                print("Retrieving from favorite automatic storage with Disk failed. Error is: \(error)")
            }
            for favorite in favoritesArray {
                var newComponentsStruct = SnapshotComponents()
                newComponentsStruct.snapshot = Snapshot()
                newComponentsStruct.snapshot?.nickname = favorite.nickname
                self.componentsChecklist[favorite.id] = newComponentsStruct
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
    //MARK: - check persistence for snapshot records
    //
    func getAndScrubAllPersistenceSnapshots(){
        if Disk.exists(DefaultConstants.allSnapshots, in: .caches) {
            var allSnapshots = [Snapshot]()
            do {
                allSnapshots = try Disk.retrieve(DefaultConstants.allSnapshots, from: .caches, as: [Snapshot].self)
            }catch{
                print("Retrieving snapshots from automatic storage with Disk failed. Error is: \(error)")
            }
            
            
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "h:mm a"
            print("\(allSnapshots.count) Favorite Snapshots Timestamps before removing")
            for snapshot in allSnapshots{
                print(dateFormatter.string(from: snapshot.timeStamp))
            }
            
            allSnapshots = allSnapshots.sorted(by: {$0.timeStamp < $1.timeStamp})
            allSnapshots = allSnapshots.uniqueElements
            
            print("\(allSnapshots.count) Favorite Snapshots after removing")
            for snapshot in allSnapshots{
                print(dateFormatter.string(from: snapshot.timeStamp))
            }
            
            
            
            
            
            

            
            do {
                try Disk.save(allSnapshots, to: .caches, as: DefaultConstants.allSnapshots)
            }catch{
                print("Saving snapshots in automatic storage with Disk failed. Error is: \(error)")
            }
            
        }
        
    }
    
    
    
    func checkForDownloadedSnapshot(with key:Int)->Bool{
            
            // remove snapshotcomponents entry where we have data from persistence
            for savedSnapshot in allPersistenceSnapshots where key == savedSnapshot.id {
                
                //remove the entry from componentsChecklist
                self.componentsChecklist.removeValue(forKey: Int(savedSnapshot.id))
                
                //then populate persistence snapshot into favoriteSnapshots array
                if favoriteSnapshots?.append(savedSnapshot) == nil {
                    favoriteSnapshots = [savedSnapshot]
                }
                return true
            }
        return false
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
            userLocation = UserLocation(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude, timestamp: Date())
            print("User location available from gps: \(userLocation)")

            do {
                try Disk.save(userLocation, to: .caches, as: DefaultConstants.userLocation)
            }catch{
                print("Saving to automatic storage with Disk failed. Error is: \(error)")
            }
            self.checkComponentsThenSegue()
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
        if let userLocation = userLocation {
            buoyClient?.appendDistanceToUserWith(userLocation: userLocation)
        }
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
        guard let currentSnapshot = componentsChecklist[snapshot.id]?.snapshot else {return}
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
        print("Beginning Transiton")
        print("There are \(favoriteSnapshots?.count) snapshots to be sent to the Home Controller ")
        print("There are \(componentsChecklist.count) componentsChecklists ")
        print("The component checklists are")
        for key in componentsChecklist.keys {
            print(key)
            print(componentsChecklist[key]?.bouy)
            print(componentsChecklist[key]?.air)
            print(componentsChecklist[key]?.wind)
            print(componentsChecklist[key]?.tide)
            print(userLocation)

            if componentsChecklist[key]?.bouy == false || componentsChecklist[key]?.air == false ||  componentsChecklist[key]?.wind == false || componentsChecklist[key]?.tide == false || userLocation == nil{
                return
            }
        }
        
        if userLocation == nil {
            //try to get location again
            locationManager.requestLocation()
            return
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
            if Disk.exists(DefaultConstants.allSnapshots, in: .caches) {
                do {
                    try Disk.append(snapshots, to: DefaultConstants.allSnapshots, in: .caches)
                }catch{
                    print("Appending to automatic storage with Disk failed. Error is: \(error)")
                }
            }else{
                do {
                    try Disk.save(snapshots, to: .caches, as: DefaultConstants.allSnapshots)
                }catch{
                    print("Saving to automatic storage with Disk failed. Error is: \(error)")
                }
            }

        }
    }
}

