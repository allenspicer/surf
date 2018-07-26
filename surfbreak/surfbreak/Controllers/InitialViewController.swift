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


    override func viewDidLoad() {
        //set up activity indicator
        DispatchQueue.global(qos:.utility).async{

        //trigger user location process
            self.getUserLocation()
        //check persistence for user favorites
        //for each favorite
            // load series of data points (clients)
        }
    }

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
            //user location available
            //apply location to find distances
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
            print(userLocation)
            
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

extension InitialViewController {
    
}

extension InitialViewController {
    
}

extension InitialViewController {
    
}

