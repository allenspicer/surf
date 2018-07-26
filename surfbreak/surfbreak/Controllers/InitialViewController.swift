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


    override func viewDidLoad() {
        //set up activity indicator
        //trigger user location process
        getUserLocation()
        //check persistence for user favorites
        //for each favorite
            // load series of data points (clients)

    }

    private func getUserLocation (){
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
            print(userLocation)
        }
    }
}

extension InitialViewController {
    
}

extension InitialViewController {
    
}

extension InitialViewController {
    
}

