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
import MessageUI

final class InitialViewController: UIViewController {
    
    private var locationManager = CLLocationManager()
    private var userLocation : UserLocation? = nil
    private var componentsChecklist : [Int : SnapshotComponents] = [:]

    private var buoyClient : BuoyClient?
    private var tideClient : TideClient?
    private var windClient : WindClient?
    private var airTempClient : AirTempClient?
    private var surfQuality : SurfQuality?
    
    var allStations : [Station]? = nil
    var allPersistenceSnapshots = [Snapshot]()
    var fallbackSnapshots : [Snapshot]? = nil


    override func viewDidLoad() {
        //present identical screen to launch screen, then switch to activity indicator
        startIntroScreenWithTimerToActivityIndicator()
        
        DispatchQueue.global(qos:.utility).async{

            //trigger user location process
            self.getUserLocation()
            
            //get all stations from local file
            self.loadStationDataFromFile()
            
            //check persistence for user favorites
            self.getUserFavoritesList()
            
            //check persistence for saved snapshots
            self.getAndScrubAllPersistenceSnapshots()
            
            //if there are no favorites
            if !self.componentsChecklist.isEmpty {
                    //for each favorite that does not have a snapshot
                    for snapshotId in self.componentsChecklist.keys{
                        
                        //check persistence for records
                        if !self.checkForDownloadedSnapshot(with: snapshotId){
                            
                            //if there is no snapshot in persistence for this favorite start the download process
                            self.setBuoyClientForSnapshot(snapshotId: snapshotId)
                        }
                    }
            }else{
                //if no favorites are saved
                self.ensureQualityAndLocationAreCompleteThenSegue()
            }
        }
    }
    
    //
    //MARK: - Intro Screen Handler
    //
    
    private func startIntroScreenWithTimerToActivityIndicator(){
        
        let allPngImagePaths = Bundle.main.paths(forResourcesOfType: "png", inDirectory: nil)
        let launchImagePaths = allPngImagePaths.filter({$0.contains("LaunchImage")})
        let launchImages = launchImagePaths.map({UIImage(named: $0)})
        let launchImage = launchImages.filter({$0?.scale == UIScreen.main.scale && $0?.size == UIScreen.main.bounds.size})
        
        let introImageView = UIImageView(image: #imageLiteral(resourceName: "splash"))
        if let image = launchImage[0]{
            introImageView.image = image
        }
        self.view.addSubview(introImageView)
        introImageView.contentMode = .scaleAspectFill
        introImageView.translatesAutoresizingMaskIntoConstraints = false
        introImageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0).isActive = true
        introImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 0).isActive = true
        introImageView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: 0).isActive = true
    
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            //when timer is complete remove the intro and set up activity indicator
            introImageView.removeFromSuperview()
            self.startActivityIndicator("Loading...")
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
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
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
            print("User location available from persistence: \(String(describing: userLocation))")
            
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
        
        #if targetEnvironment(simulator)
            userLocation = UserLocation(latitude: 34.2428817, longitude: -77.8217321, timestamp: Date())
        #endif
    }
    
    func respondToLocationServicesDenial(){
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            DispatchQueue.main.async {
                //if no data respond with alertview
                let alert = UIAlertController.init(title: "Location Not Found", message: "This app depends on location services to bring you relevant data. Please turn location services on so we can set your location.", preferredStyle: .alert)
                let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                    guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                        return
                    }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                            //try to get location again
                            self.locationManager.requestLocation()
                        })
                    }
                }
                alert.addAction(settingsAction)
                self.present(alert, animated: true, completion: nil)
            }
        }else{
            locationManager.requestLocation()
        }
    }
    
    //
    //MARK: - Favorites from persistence
    //
    
    private func getUserFavoritesList(){
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
            
            //scrub records: if snapshot in persistence is older than an the time limit we should remove it
            let timeLimit : TimeInterval = 60.0 * 15.0
            allSnapshots = allSnapshots.filter({abs($0.timeStamp.timeIntervalSinceNow) < timeLimit})
            allSnapshots = allSnapshots.sorted(by: {$0.timeStamp < $1.timeStamp})
            allSnapshots = allSnapshots.uniqueElements
            allPersistenceSnapshots = allSnapshots
            
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
            
            // update snapshotcomponents entry where we have data from persistence
            for savedSnapshot in allPersistenceSnapshots where key == savedSnapshot.id {
                componentsChecklist[savedSnapshot.id]?.snapshot = savedSnapshot
                setAllComponentsTo(bool: true, For: savedSnapshot.id)
                ensureQualityAndLocationAreCompleteThenSegue()
                return true
            }
        return false
    }
    
    //
    //MARK: - Init networking handlers
    //
    
    
    func setBuoyClientForSnapshot(snapshotId : Int){
        guard let allStations = self.allStations else {
            print("failed to unwrap self.allStations \n No buoy client created for snapshot with id \(snapshotId)")
            return
        }
        buoyClient = BuoyClient(snapshotId: snapshotId, allStations : allStations)
        buoyClient?.delegate = self
        buoyClient?.createBuoyData()
    }
    
    func setSecondaryDataClientsFor(snapshot : Snapshot){
        
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

//
//MARK: - Core Location
//

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
            print("User location available from gps: \(String(describing: userLocation))")

            do {
                try Disk.save(userLocation, to: .caches, as: DefaultConstants.userLocation)
            }catch{
                print("Saving to automatic storage with Disk failed. Error is: \(error)")
            }
            let maximumDistance = 10.0
            let latDiff = abs(currentLocation.coordinate.latitude - 34.208)
            let lonDiff = abs(currentLocation.coordinate.longitude - -77.796)
            if (pow(lonDiff, 2) + pow(latDiff, 2)).squareRoot() > maximumDistance{
                let alert = UIAlertController.init(title: "You're pretty far from our closest break", message: "For now, you won't have a lot of great info here to work with. Please email us now to let us know where you are and what breaks you're looking for and we'll add them to our 'To-Do' list", preferredStyle: .alert)
                let emailAction = UIAlertAction(title: "Email Now", style: .default){_ in
                    self.composeEmail()
                }
                alert.addAction(emailAction)
                let ignoreAction = UIAlertAction(title: "Ignore", style: .cancel){_ in
                    self.ensureQualityAndLocationAreCompleteThenSegue()
                }
                alert.addAction(ignoreAction)
                self.present(alert, animated: true, completion: nil)
            }else{
                ensureQualityAndLocationAreCompleteThenSegue()
            }
        }
    }
}

//
//MARK: - Email composition
//

extension InitialViewController : MFMailComposeViewControllerDelegate{
    func composeEmail() {
        var informationalFooter = ""
        if let userLocation = userLocation {
            informationalFooter = "\(userLocation.latitude).\(userLocation.longitude)."
        }
        if let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String{
            informationalFooter.append("v\(appVersion).")
        }
        let iosVersion = UIDevice.current.systemVersion
        informationalFooter.append("\(iosVersion)")
        let mailController = MFMailComposeViewController()
        mailController.mailComposeDelegate = self
        var mail = "surfbreakapp"
        mail.append("@")
        mail.append("gmail.com")
        mailController.setToRecipients([mail])
        mailController.setSubject("Support Request")
        mailController.setMessageBody("""
            Name:
            Contact Email:
            City/State/Country:
            Surf Spots I'm Looking For:
            
            Please add my spots to your supported surfbreaks!
            
            For support use: \(informationalFooter)
            """, isHTML: false)
        self.present(mailController, animated: true, completion: nil)
    }
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result {
        case .cancelled:
            break
        case .saved:
            break
        case .sent:
            break
        case .failed:
            break
        }
        dismiss(animated: true, completion: {
            self.ensureQualityAndLocationAreCompleteThenSegue()
        })
    }
}

//
//MARK: - Data Client Delegates
//

extension InitialViewController : BuoyClientDelegate{
    func didFinishBuoyTask(sender: BuoyClient, snapshot: Snapshot, stations: [Station]) {
        print("The Buoy Client has returned with \(snapshot.waveHeight)ft waves at \(snapshot.period)sec")
        if (allStations == nil) { allStations = stations }
        componentsChecklist[snapshot.id]?.bouy = true
        componentsChecklist[snapshot.id]?.bouyTimeStamp = Date()
        componentsChecklist[snapshot.id]?.snapshot = snapshot
        if let userLocation = userLocation {
            buoyClient?.appendDistanceToUserWith(userLocation: userLocation)
        }
        
        if snapshot.waveHeight != 0.0 && snapshot.period != 0.0 {
            setSecondaryDataClientsFor(snapshot: snapshot)
        }else{
            self.dataLoadFailedUseFallBackFromPersistence(snapshotId: sender.snapshotId)
                DispatchQueue.main.async {
                    //if no data respond with alertview
                    let alert = UIAlertController.init(title: "Not enough Data", message: "This data is a little old. The bouy you want is not providing much data at the moment.", preferredStyle: .alert)
                    let retryAction = UIAlertAction(title: "Retry", style: .destructive){_ in
                        DispatchQueue.global(qos:.utility).async{
                            self.setAllComponentsTo(bool: false, For: sender.snapshotId)
                            self.setBuoyClientForSnapshot(snapshotId: sender.snapshotId)
                        }
                    }
                    alert.addAction(retryAction)
                    let continueAction = UIAlertAction(title: "Continue", style: .default){_ in
                        DispatchQueue.global(qos:.utility).async{
                            self.ensureQualityAndLocationAreCompleteThenSegue()
                        }
                    }
                    alert.addAction(continueAction)
                    self.present(alert, animated: true, completion: nil)
                }
        }
    }
}

extension InitialViewController : TideClientDelegate{
    func didFinishTideTask(sender: TideClient, tides: [Tide], snapshot: Snapshot) {
        print("The Tide Client has returned an array of tides.")
        componentsChecklist[snapshot.id]?.tide = true
        componentsChecklist[snapshot.id]?.tideTimeStamp = Date()
        guard let currentSnapshot = componentsChecklist[snapshot.id]?.snapshot else {return}
        componentsChecklist[snapshot.id]?.snapshot = tideClient?.addTideDataToSnapshot(currentSnapshot, tideArray: tides)
        attemptToCreateQualityMeasureWithCompleteComponentChecklist()
    }
}

extension InitialViewController : WindClientDelegate{
    func didFinishWindTask(sender: WindClient, winds: [Wind], snapshot: Snapshot) {
        print("The Wind Client has returned an array of winds.")
        componentsChecklist[snapshot.id]?.wind = true
        componentsChecklist[snapshot.id]?.windTimeStamp = Date()
        guard let currentSnapshot = componentsChecklist[snapshot.id]?.snapshot else {return}
        componentsChecklist[snapshot.id]?.snapshot = windClient?.addWindDataToSnapshot(currentSnapshot, windArray: winds)
    }
}

extension InitialViewController : AirTempDelegate{
    func didFinishAirTempTask(sender: AirTempClient, airTemps: [AirTemp], snapshot: Snapshot) {
        print("The Air Temp Client has returned an array of air temps.")
        componentsChecklist[snapshot.id]?.air = true
        componentsChecklist[snapshot.id]?.airTimeStamp = Date()
        guard let currentSnapshot = componentsChecklist[snapshot.id]?.snapshot else {return}
        componentsChecklist[snapshot.id]?.snapshot = airTempClient?.addAirTempDataToSnapshot(currentSnapshot, AirTempArray: airTemps)
        attemptToCreateQualityMeasureWithCompleteComponentChecklist()
    }
}

extension InitialViewController : SurfQualityDelegate{
    func didFinishSurfQualityTask(sender: SurfQuality, snapshot: Snapshot) {
        componentsChecklist[snapshot.id]?.quality = true
        componentsChecklist[snapshot.id]?.completeTimestamp = Date()
        componentsChecklist[snapshot.id]?.snapshot = snapshot
        ensureQualityAndLocationAreCompleteThenSegue()
    }
    
}

extension InitialViewController {
    
    func attemptToCreateQualityMeasureWithCompleteComponentChecklist(){
        print("Checking for components needed for quality assesment")
        print("There are \(componentsChecklist.count) componentsChecklists ")
        for key in componentsChecklist.keys {
            if componentsChecklist[key]?.bouy == false || componentsChecklist[key]?.air == false ||  componentsChecklist[key]?.wind == false || componentsChecklist[key]?.tide == false{
                print("Exiting on checkComponentsForCompletion")
                print("Snapshot id \(key)")
                print("Buoy data present: \(String(describing: componentsChecklist[key]?.bouy))")
                print("Air data present: \(String(describing: componentsChecklist[key]?.air))")
                print("Wind data present: \(String(describing: componentsChecklist[key]?.wind))")
                print("Tide data present: \(String(describing: componentsChecklist[key]?.tide))")
                return
            }
            guard let snapshot = (componentsChecklist[key]?.snapshot) else {return}
            surfQuality = SurfQuality(currentSnapshot: (snapshot))
            surfQuality?.delegate = self
            self.surfQuality?.createSurfQualityAssesment()
        }
    }
    
    func ensureQualityAndLocationAreCompleteThenSegue(){
        for key in componentsChecklist.keys {
            if componentsChecklist[key]?.quality == false{
                print("Exiting on checkComponentsThenSegue quality not available")
                print("for snapshot id \(key)")
                return
            }
        }
        
        if userLocation == nil {
            print("Exiting on checkComponentsThenSegue userLocations not available")
            //try to get location again
            respondToLocationServicesDenial()
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
        let snapshots = componentsChecklist.compactMap({$0.value.snapshot})
        destinationVC.favoritesSnapshots = snapshots
        saveCompleteSnapshotToPersistence(with: snapshots.filter({!$0.isFallback}))
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
    
    func dataLoadFailedUseFallBackFromPersistence(snapshotId : Int){
        if fallbackSnapshots == nil{
            if Disk.exists(DefaultConstants.fallBackSnapshots, in: .documents) {
                do {
                    fallbackSnapshots = try Disk.retrieve(DefaultConstants.fallBackSnapshots, from: .documents, as: [Snapshot].self)
                }catch{
                    print("Retrieving from automatic storage with Disk failed. Error is: \(error)")
                }
            }
        }
        
        guard let fallbackSnapshots = fallbackSnapshots else {
            print("Exiting on dataLoadFailedUseFallBackFromPersistence fallbackSnapshots not available")
            return
        }
        for snapshot in fallbackSnapshots where snapshot.id == snapshotId{
            componentsChecklist[snapshotId]?.snapshot = snapshot
            setAllComponentsTo(bool: true, For: snapshotId)
        }
    }
    
    func setAllComponentsTo(bool:Bool, For id:Int){
        self.componentsChecklist[id]?.bouy = bool
        self.componentsChecklist[id]?.air = bool
        self.componentsChecklist[id]?.tide = bool
        self.componentsChecklist[id]?.wind = bool
        self.componentsChecklist[id]?.quality = bool
    }
    
}

