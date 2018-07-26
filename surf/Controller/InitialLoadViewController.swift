//
//  InitialLoadViewController.swift
//  surf
//
//  Created by Allen Spicer on 7/5/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit
import CoreLocation

class InitialLoadViewController: UIViewController {
    
    var favoriteSnapshots = [Snapshot]()
    var userFavorites = [Favorite : Bool]()
    var activityIndicatorView = ActivityIndicatorView()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var waveDictionary = [Int : Wave]()
    var locationManager = CLLocationManager()
    var userLocation = (0.0,0.0)
    var stationList = [Station]()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        displayActivityIndicator()
        DispatchQueue.global(qos:.utility).async{
        self.makeStationList()
        self.setDataOrGetUserLocation()
        self.retrieveUserFavoritesAndCreateSnapshots()
        }
    }
    
    func displayActivityIndicator(){
        let activityIndicatorView = ActivityIndicatorView().setupActivityIndicator(view: self.view, widthView: nil, backgroundColor:UIColor.black.withAlphaComponent(0.1), textColor: UIColor.gray, message: "loading...")
        self.view.addSubview(activityIndicatorView)
    }
    
    func retrieveUserFavoritesAndCreateSnapshots(){
            self.getUserFavoritesFromDefaults(){ (favoritesDictionary) in
                //if the user has favorites get records from persistent or download them
                if self.userFavorites.count > 0 {
                    self.loadWaveRecordsFromPersistence()
                    self.addFavoriteStationsToCollectionData()
                } else {
                    self.segueWhenComplete()
                }
            }
    }
    
    
    func loadWaveRecordsFromPersistence() {
        
        var waveArray = [Wave]()
        do {
            waveArray = try context.fetch(Wave.fetchRequest())
        }
        catch {
            print("Failed to retrieve Wave Entity from context.")
        }
        for wave in waveArray {
            waveDictionary[Int(wave.id)] = wave
        }
        
        //scrub records: if a wave in persistence is more than 5 minutes old remove it from local and persistence
        let fiveMinutes: TimeInterval = 5.0 * 60.0
        
        for wave in waveDictionary {
            guard let timestamp = wave.value.timestamp else {return}
            if abs(timestamp.timeIntervalSinceNow) > fiveMinutes{
                DispatchQueue.main.async {
                    self.context.delete(wave.value)
                }
                waveDictionary.removeValue(forKey: wave.key)
            }
        }
        DispatchQueue.main.async {
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }
        
    }
    
    func segueWhenComplete(){
        if !userFavorites.values.contains(false) && userLocation.0 != 0.0 && userLocation.1 != 0.0{
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "segueInitalToHome", sender: self)
            }
        }
    }
    
    
    func getSnapshotWith(id : Int, stationId: String, beachFaceDirection : Double, name: String){
        DispatchQueue.global(qos:.utility).async {
            let snapshotSetter = SnapshotSetter(stationId: stationId, beachFaceDirection: beachFaceDirection, id: id, name: name)
            var snapshot = snapshotSetter.createSnapshot(finished: {})
            //if snapshot available update snapshot array
            if snapshot.waveHgt != nil && snapshot.waterTemp != nil {
                
                DispatchQueue.main.async {
                    //add to persistent container
                    let wave = Wave(context: self.context)
                    wave.timestamp = Date()
                    if let waveId = snapshot.id {
                        wave.id = Int32(waveId)
                    }
                    if let waveHeight = snapshot.waveHgt {
                        wave.waveHeight = waveHeight
                    }
                    if let frequency = snapshot.waveAveragePeriod {
                        wave.frequency = frequency
                    }
                    if let direction = snapshot.beachFaceDirection {
                        wave.beachFaceDirection = direction
                    }
                    
                    (UIApplication.shared.delegate as! AppDelegate).saveContext()
                }
                
                snapshot = self.appendDistanceToFavoriteSnapshots(snapshot: snapshot)
                
                for favorite in self.userFavorites.keys where favorite.id == id{
                    
                    if snapshot.distanceToUser != nil {
                        self.userFavorites[favorite] = true
                    }else{
                        //
                    }
                }
                
                

                self.favoriteSnapshots.append(snapshot)
                //segue when all snapshots are available
                self.segueWhenComplete()
            }else{
                
                //if no data respond with alertview
                // alert user then let them trigger endpoint again
            
                DispatchQueue.main.async {
                    let alert = UIAlertController.init(title: "Not enough Data", message: "One of the weather stations in your favorites list is not providing much data at the moment", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Try Again", style: .default) { (action:UIAlertAction!) in
                        self.getSnapshotWith(id: id, stationId: stationId, beachFaceDirection: beachFaceDirection, name: name)
                    })
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    func getUserFavoritesFromDefaults (completion:@escaping ([String : Int])->Void){
        
        // retrieve defaults and set up a local dictionary with the users favorites and a false flag
        // false here is a default value to indicate this favorite has not been downloaded
        
        let defaults = UserDefaults.standard
        if let favorites = defaults.array(forKey: DefaultConstants.favorites) as? [Int], let names = defaults.array(forKey: DefaultConstants.nicknames) as? [String]{
            for index in 0..<favorites.count {
                let favorite = Favorite.init(id: favorites[index], stationId: "", beachFaceDirection: 0.0, name: names[index])
                userFavorites[favorite] = false
            }
        }
        completion([String : Int]())
    }
    
    private func addFavoriteStationsToCollectionData(){
        
        for wave in waveDictionary{
            guard let timestamp = wave.value.timestamp else {return}
            for favorite in self.userFavorites.keys where favorite.id == wave.key{
                self.userFavorites[favorite] = true
                //init a snapshot object here and populate with the persistence data
                var snapshot = Snapshot.init()
                snapshot.timeStamp = timestamp
                snapshot.waveHgt = wave.value.waveHeight
                snapshot.waveAveragePeriod = wave.value.frequency
                snapshot.id = wave.key
                snapshot.nickname = favorite.name
                snapshot.beachFaceDirection = favorite.beachFaceDirection
                snapshot = appendDistanceToFavoriteSnapshots(snapshot: snapshot)
                self.favoriteSnapshots.append(snapshot)
                //try to segue, will only work when all snapshots are populated
                self.segueWhenComplete()
            }
        }
        
        //for snapshots in favorites that still have a false value
        //we must download a new snapshot
        
        if let path = Bundle.main.path(forResource: "regionalBuoyList", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                
                for snapshot in userFavorites where snapshot.value == false{
                    let id = snapshot.key.id
                    if let stationsFromJSON = jsonResult as? [[String : AnyObject]]{
                        for station in stationsFromJSON {
                            guard let idFromJSON = station["id"] as? Int else {return}
                            if idFromJSON == id {
                                guard let stationId = station["station"] as? Int else {return}
                                guard let beachFaceDirection = station["bfd"] as? Double else {return}
                                guard let name = station["name"] as? String else {return}
                                var favorite = snapshot.key
                                favorite.stationId = "\(stationId)"
                                favorite.beachFaceDirection = beachFaceDirection
                                favorite.name = name
                                self.getSnapshotWith(id: favorite.id, stationId: favorite.stationId, beachFaceDirection: favorite.beachFaceDirection, name: name)
                            }
                        }
                    }
                }
            } catch {
                // handle error
                print("Problem accessing regional buoy list document: \(error)")
            }
        }
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destinationVC = segue.destination as? HomeViewController {
            destinationVC.favoritesSnapshots = favoriteSnapshots
            destinationVC.userLocation = userLocation
        }
    }
    
    
}



//extension InitialLoadViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate, TideClientDelegate, WindClientDelegate, AirTempDelegate, SurfQualityDelegate{

extension InitialLoadViewController : CLLocationManagerDelegate{
    
    private func setDataOrGetUserLocation(){
        let defaults = UserDefaults.standard
        userLocation.0 = defaults.object(forKey: "userLatitude") as? Double ?? 0.0
        userLocation.1 = defaults.object(forKey: "userLongitude") as? Double ?? 0.0
        if userLocation.0 == 0.0 || userLocation.1 == 0.0 {
            isAuthorizedtoGetUserLocation()
            
            if CLLocationManager.locationServicesEnabled() {
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            }
            
            if CLLocationManager.locationServicesEnabled() {
                locationManager.requestLocation();
            }
        }else{
//            appendDistanceToFavoriteSnapshots()
        }
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
            userLocation.0 = currentLocation.coordinate.latitude
            userLocation.1 = currentLocation.coordinate.longitude
            
//            appendDistanceToFavoriteSnapshots()
            
            let defaults = UserDefaults.standard
            defaults.set(userLocation.0, forKey: "userLatitude")
            defaults.set(userLocation.1, forKey: "userLongitude")
        }
    }
    
    func appendDistanceToFavoriteSnapshots(snapshot : Snapshot) -> Snapshot{
        let approxMilesToLon = 53.0
        let approxMilesToLat = 69.0
        if (userLocation.0 != 0 && userLocation.1 != 0) {
            for station in stationList where snapshot.id == station.id{
                let latDiffAbs = abs(station.lat - userLocation.0) * approxMilesToLat
                let lonDiffAbs = abs(station.lon - userLocation.1) * approxMilesToLon
                let milesFromUser = (pow(lonDiffAbs, 2) + pow(latDiffAbs, 2)).squareRoot()
                var mutableSnapshot = snapshot
                mutableSnapshot.distanceToUser = Int(milesFromUser)
                return mutableSnapshot
//                segueWhenComplete()
            }
        }else{
            print("append distance called but user location not available")
        }
        return Snapshot()
    }
    
    private func makeStationList(){
        if let path = Bundle.main.path(forResource: "regionalBuoyList", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let metaData = jsonResult as? [[String : AnyObject]]{
                    for station in metaData {
                        guard let stationId = station["station"] else {return}
                        guard let id = station["id"] as? Int else {return}
                        guard let beachFaceDirection = station["bfd"] as? Double else {return}
                        guard let lon = station["longitude"] as? Double else {return}
                        guard let lat = station["latitude"] as? Double else {return}
                        guard let name = station["name"] as? String else {return}
                        let station = Station(id: id, stationId: "\(stationId)", lat: lat, lon: lon, beachFaceDirection: beachFaceDirection, name: name, nickname: nil, distanceInMiles: 10000)
                        stationList.append(station)
                    }
                }
            } catch {
                // handle error
            }
        }
    }

}

