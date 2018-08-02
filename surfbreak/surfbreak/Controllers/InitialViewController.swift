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
    private var buoyClient : BuoyClient?
//    private var tideClient : TideClient?
//    private var windClient : WindClient?
//    private var airTempClient : AirTempClient?
//    private var surfQuality : SurfQuality?


    override func viewDidLoad() {
        //set up activity indicator
//        DispatchQueue.global(qos:.utility).async{

        //trigger user location process
            self.getUserLocation()
            self.setDataClientsForStation(snapshotId: 100)
        //check persistence for user favorites
        //for each favorite
            // load series of data points (clients)
//        }
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
    //MARK: - Init networking handlers
    //
    
    
    func setDataClientsForStation(snapshotId : Int){
        buoyClient = BuoyClient(snapshotId: snapshotId)
        buoyClient?.delegate = self
        buoyClient?.createBuoyData()
        
//        tideClient = TideClient(currentSnapshot: self.selectedSnapshot)
//        tideClient?.delegate = self
//        tideClient?.createTideData()
//
//        windClient = WindClient(currentSnapshot: self.selectedSnapshot)
//        windClient?.delegate = self
//        windClient?.createWindData()
//
//        airTempClient = AirTempClient(currentSnapshot: self.selectedSnapshot)
//        airTempClient?.delegate = self
//        airTempClient?.createAirTempData()
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
            locationManager.requestLocation();
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
            }
        }
    }
}

extension InitialViewController : BuoyClientDelegate{
    func didFinishBuoyTask(sender: BuoyClient, buoys: [Buoy]) {
        print("Initial View Controller Has Buoy Array with \(buoys.count) buoys")
//        let snapshot = buoyClient?.getBuoyDataAsSnapshot()
//        print("THe Snapshot has been returned. Contents are \(snapshot)")
//        snapshotComponents["tide"] = true
//        segueWhenAllComponenetsAreLoaded()
    }
}

extension InitialViewController {
    
}

extension InitialViewController {
    
}

