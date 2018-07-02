//
//  HomeViewController.swift
//  surf
//
//  Created by Allen Spicer on 6/6/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit
import CoreLocation
import iCarousel
import CCZoomTransition

class HomeViewController: UIViewController {

    @IBOutlet weak var favoritesCollectionView: UICollectionView!
    @IBOutlet weak var proximalCollectionView: UICollectionView!
    @IBOutlet weak var carousel: iCarousel!
    private var favoritesData = [Favorite]()
    private var proximalData = [Station]()
    private var cellSelectedIndex = Int()
    private var selectedSnapshot = Snapshot()
    private var selectedStationOrFavorite : Any? = nil
    var snapshotComponents = [String:Bool]()
    var tideClient : TideClient?
    var windClient : WindClient?
    var airTempClient : AirTempClient?
    var surfQuality : SurfQuality?
    private var userLongitude = 0.0
    private var userLatitude = 0.0
    private var locationManager = CLLocationManager()
    private var favoritesArray = [Int]()
    private var nicknamesArray = [String]()
    private var favoriteStationIdsFromMemory = [String : Int]()
    let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
    private let imageArray = [#imageLiteral(resourceName: "crash.png"), #imageLiteral(resourceName: "wave.png"), #imageLiteral(resourceName: "flat.png"), #imageLiteral(resourceName: "wave.png"), #imageLiteral(resourceName: "flat.png"),#imageLiteral(resourceName: "flat.png"),#imageLiteral(resourceName: "flat.png"),#imageLiteral(resourceName: "flat.png"),#imageLiteral(resourceName: "flat.png")]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startActivityIndicator("Loading")
        parseStationList()
        setDataOrGetUserLocation()
        setDelegatesAndDataSources()
            DispatchQueue.global(qos:.utility).async{
                self.setUserFavorites(){ (favoritesDictionary) in
                    self.addFavoriteStationsToCollectionData()
            }
        }
        selectionFeedbackGenerator.prepare()
        
        
        let gradientLayer:CAGradientLayer = CAGradientLayer()
        gradientLayer.frame.size = self.view.frame.size
        let customBlack = #colorLiteral(red: 0.01960784314, green: 0.01960784314, blue: 0.05098039216, alpha: 1)
//        let darkOceanBlue = UIColor( red: CGFloat(14/255.0), green: CGFloat(8/255.0), blue: CGFloat(67/255.0), alpha: CGFloat(1.0) )
//        gradientLayer.colors = [darkOceanBlue.withAlphaComponent(0.1).cgColor, darkOceanBlue.withAlphaComponent(0.5).cgColor]
        gradientLayer.colors = [UIColor.clear.cgColor, customBlack.cgColor]
        self.view.layer.insertSublayer(gradientLayer, at: 0)
    }

    
    func setUserFavorites (completion:@escaping ([String : Int])->Void){
                let defaults = UserDefaults.standard
                if let favorites = defaults.array(forKey:"favorites") as? [Int], let names = defaults.array(forKey: "nicknames") as? [String]{
                    favoritesArray = favorites
                    nicknamesArray = names
                    for index in 0..<favorites.count {
                        let favorite = favorites[index]
                        let name = names[index]
                        favoriteStationIdsFromMemory[name] = favorite
                    }
                }
        completion(favoriteStationIdsFromMemory)
    }

    
    
//
// MARK: - Inital Load Logic
//
    
    private func setDataOrGetUserLocation(){
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
    
//
//MARK: - Location Services
//
    
    private func findDistancesFromUserLocation(){
        
        // Used to convert latitude and longitude into miles
        // both numbers are approximate. One longitude at 40 degrees is about 53 miles however the true
        // number of miles is up to 69 at the equator and down to zero at the poles
        let approxMilesToLon = 53.0
        let approxMilesToLat = 69.0
        
        if (userLatitude != 0 && userLongitude != 0) {
            for index in 0..<proximalData.count{
                let station = proximalData[index]
                let lonDiffAbs = abs(station.lon - userLongitude) * approxMilesToLon
                let latDiffAbs = abs(station.lat - userLatitude) * approxMilesToLat
                let milesFromUser = (pow(lonDiffAbs, 2) + pow(latDiffAbs, 2)).squareRoot()
                proximalData[index].distanceInMiles = Int(milesFromUser)
                print("\(proximalData[index].name) station is \(milesFromUser) from user")
                print("\(userLatitude) \(userLongitude)")
                print("\(station.lat) \(station.lon)")

            }
        }
        sortTableObjectsByDistance()
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
            userLatitude = currentLocation.coordinate.latitude
            userLongitude = currentLocation.coordinate.longitude
            findDistancesFromUserLocation()
            
            let defaults = UserDefaults.standard
            defaults.set(userLatitude, forKey: "userLatitude")
            defaults.set(userLongitude, forKey: "userLongitude")
            
        }
    }
    
    func sortTableObjectsByDistance(){
        proximalData = proximalData.sorted(by: {$0.distanceInMiles < $1.distanceInMiles })
        proximalCollectionView.reloadData()
        stopActivityIndicator()
    }
    
//
//MARK: - Buoy List for regional data station ids
//
    
    private func parseStationList(){
        if let path = Bundle.main.path(forResource: "regionalBuoyList", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let metaData = jsonResult as? [[String : AnyObject]]{
                    for station in metaData {
                        guard let stationId = station["station"] else {return}
                        guard let id = station["id"] else {return}
                        guard let beachFaceDirection = station["bfd"] as? Double else {return}
                        guard let lon = station["longitude"] as? Double else {return}
                        guard let lat = station["latitude"] as? Double else {return}
                        guard let name = station["name"] as? String else {return}
                        let station = Station(id: "\(id)", stationId: "\(stationId)", lat: lat, lon: lon, beachFaceDirection: beachFaceDirection, owner: nil, name: name, distance: 10000.0, distanceInMiles: 10000)
                        proximalData.append(station)
                    }
                    stopActivityIndicator()
                }
            } catch {
                // handle error
            }
        }
    }
    
    private func addFavoriteStationsToCollectionData(){
        if let path = Bundle.main.path(forResource: "regionalBuoyList", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                
                //meta data is all possible surf bouy stations
                //currently checking entire list against saved IDs
                //and appending matches to the collection view data
            
                if let metaData = jsonResult as? [[String : AnyObject]]{
                    for station in metaData {
                        guard let id = station["id"] as? Int else {return}
                        if !self.favoriteStationIdsFromMemory.values.contains(id) {continue}
                        guard let stationId = station["station"] as? Int else {return}
                        guard let beachFaceDirection = station["bfd"] as? Double else {return}
                        guard let name = station["name"] as? String else {return}
                        let favorite = Favorite(id: "\(id)", stationId: "\(stationId)", beachFaceDirection: beachFaceDirection, name: name)
                        favoritesData.append(favorite)
                    }
                    DispatchQueue.main.async{
                        self.carousel.type = .rotary
                        self.carousel.perspective = -0.0030
                        self.carousel.viewpointOffset = CGSize(width: 0, height: -125)
                        self.carousel.dataSource = self
                        self.carousel.delegate = self
                        self.stopActivityIndicator()
                    }
                }
            } catch {
                // handle error
                print("Problem accessing regional buoy list document: \(error)")
            }
        }
    }
    
    private func addStationWithIdLatLon(id :String, lat : Double, lon : Double, name: String){

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destinationVC = segue.destination as? ViewController {
            
            if let station = selectedStationOrFavorite as? Station, let id = Int(station.id) as? Int{
                destinationVC.id = id
            }else if let favorite = selectedStationOrFavorite as? Favorite, let id = Int(favorite.id) as? Int{
                destinationVC.id = id
            }
            destinationVC.currentSnapShot = selectedSnapshot
        }
    }
    
    
    //
    //MARK: - Activty Indicator Controllers
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
    
}

//
//MARK: - Extension to handle Collection View and Delegates Assignment
//

extension HomeViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate, TideClientDelegate, WindClientDelegate, AirTempDelegate, SurfQualityDelegate, iCarouselDataSource, iCarouselDelegate{
    
    
    func numberOfItems(in carousel: iCarousel) -> Int {
        return favoritesData.count
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        var label: UILabel
        var distanceLabel: UILabel
        var itemView: UIImageView
        var mainView: UIView
        
        //reuse view if available, otherwise create a new view
        if let view = view as? UIImageView {
            itemView = view
            //get a reference to the label in the recycled view
            label = itemView.viewWithTag(1) as! UILabel
        } else {
            //don't do anything specific to the index within
            //this `if ... else` statement because the view will be
            //recycled and used with other index values later
            itemView = UIImageView(frame: CGRect(x: 0, y: 0, width: 207, height: 264))
//            itemView.image = UIImage(named: "page.png")
            itemView.contentMode = .center
            
            let mainViewFrame = CGRect(x: 0.0, y: 0.0, width: 207.0, height: 207.0)
            mainView = UIView(frame: mainViewFrame)
            mainView.layer.cornerRadius = 103
            mainView.layer.masksToBounds = true
            mainView.layer.borderWidth = 4
            mainView.layer.borderColor = #colorLiteral(red: 0.3529411765, green: 0.9882352941, blue: 0.5725490196, alpha: 1)
            mainView.backgroundColor = #colorLiteral(red: 0.8666666667, green: 0.7529411765, blue: 0.1333333333, alpha: 1)
            
            let gradientLayer:CAGradientLayer = CAGradientLayer()
            gradientLayer.frame.size = mainViewFrame.size
            let customGreen = #colorLiteral(red: 0.01176470588, green: 0.5294117647, blue: 0.5294117647, alpha: 1)
            gradientLayer.colors = [UIColor.clear.cgColor, customGreen]
            mainView.layer.insertSublayer(gradientLayer, at: 1)
            
            itemView.addSubview(mainView)


            let labelFrame = CGRect(x: 0.0, y: itemView.frame.height - 40, width: itemView.frame.width, height: 20.0)
            label = UILabel(frame: labelFrame)
            label.backgroundColor = .clear
            label.textColor = #colorLiteral(red: 1, green: 0.9450980392, blue: 0.5058823529, alpha: 1)
            label.textAlignment = .center
            label.font = label.font.withSize(15)
            label.tag = 1
            itemView.addSubview(label)
            label.bottomAnchor.constraint(equalTo: itemView.bottomAnchor).isActive = true
            
            let distanceLabelFrame = CGRect(x: 0.0, y: itemView.frame.height - 20, width: itemView.frame.width, height: 20.0)
            distanceLabel = UILabel(frame: distanceLabelFrame)
            distanceLabel.backgroundColor = .clear
            distanceLabel.textColor = #colorLiteral(red: 1, green: 0.9450980392, blue: 0.5058823529, alpha: 1)
            distanceLabel.textAlignment = .center
            distanceLabel.font = label.font.withSize(15)
            distanceLabel.tag = 1
            itemView.addSubview(distanceLabel)
            distanceLabel.bottomAnchor.constraint(equalTo: itemView.bottomAnchor).isActive = true
            distanceLabel.text = "10mi"
        }
        
        //set item label
        //remember to always set any properties of your carousel item
        //views outside of the `if (view == nil) {...}` check otherwise
        //you'll get weird issues with carousel item content appearing
        //in the wrong place in the carousel
        if let name = favoritesData[index].name {
            label.text = "\(name)"
        }
        
        
        
        return itemView
    }
    
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        switch option {
        case .spacing:
            return 2.50
        case .visibleItems:
            return 3
        default:
            return value
        }
    }

    
    func setDelegatesAndDataSources(){
        proximalCollectionView.delegate = self
        proximalCollectionView.dataSource = self
    }
    
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        
        selectionFeedbackGenerator.prepare()
        selectionFeedbackGenerator.selectionChanged()

        
        //if item is selected transition to detail
        if carousel.currentItemIndex == index {
            
            startActivityIndicator("Loading")
            var selectedId = String()
            var selectedName = String()
            var selectedBFD = Double()
            
            
            selectedStationOrFavorite = favoritesData[index]
            selectedId = favoritesData[index].stationId
            if let name = favoritesData[index].name {
                selectedName = name
            }
            selectedBFD = proximalData[cellSelectedIndex].beachFaceDirection
            
            selectedCellAction(index, selectedId: selectedId, stationName: selectedName, selectedBFD: selectedBFD)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectionFeedbackGenerator.prepare()
        selectionFeedbackGenerator.selectionChanged()
        startActivityIndicator("Loading")
        cellSelectedIndex = indexPath.row
        var selectedId = String()
        var selectedName = String()
        var selectedBFD = Double()

        switch collectionView {
        case is ProximalCollectionView:
                selectedStationOrFavorite = proximalData[cellSelectedIndex]
                selectedId = proximalData[cellSelectedIndex].stationId
                if let name = proximalData[cellSelectedIndex].name {
                    selectedName = name
                }
                selectedBFD = proximalData[cellSelectedIndex].beachFaceDirection
        default:
            break
        }
        selectedCellAction(indexPath.row, selectedId: selectedId, stationName: selectedName, selectedBFD: selectedBFD)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case is ProximalCollectionView:
          return proximalData.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case is ProximalCollectionView:
            let cell = proximalCollectionView.dequeueReusableCell(withReuseIdentifier: "ProximalCollectionViewCell", for: indexPath) as! ProxCollectionViewCell
            
            let gradientLayer:CAGradientLayer = CAGradientLayer()
            gradientLayer.frame.size = cell.layer.frame.size
            let customBlack = #colorLiteral(red: 0.06274509804, green: 0.05098039216, blue: 0.1490196078, alpha: 1)
            gradientLayer.colors = [UIColor.clear.cgColor, customBlack.cgColor]
            cell.imageView.layer.insertSublayer(gradientLayer, at: 1)
//            cell.imageView.image = imageArray[indexPath.row]
            cell.imageView.layer.cornerRadius = 15
            cell.imageView.layer.masksToBounds = true
//            cell.titleLabel.textColor = .white
//            cell.titleLabel.text = self.proximalData[indexPath.row].name
            cell.contentView.layer.borderWidth = 2
            cell.contentView.layer.borderColor = #colorLiteral(red: 0.5058823529, green: 1, blue: 0.8274509804, alpha: 1)
            cell.contentView.layer.cornerRadius = 15
            return cell
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch collectionView {
        case is ProximalCollectionView:
            return CGSize(width: 124, height: 124)
        default:
            return CGSize()
        }
    }
    
    private func selectedCellAction (_ index : Int, selectedId : String, stationName : String, selectedBFD : Double){
        DispatchQueue.global(qos:.utility).async {
            let snapshotSetter = SnapshotSetter(stationId: selectedId, beachFaceDirection: selectedBFD)
            self.selectedSnapshot = snapshotSetter.createSnapshot(finished: {})
            self.snapshotComponents = ["wave" : true, "tide" : false, "wind" : false, "air" : false, "quality" : false]
            //remove spinner for response:
                if self.selectedSnapshot.waveHgt != nil && self.selectedSnapshot.waterTemp != nil {
                    self.selectedSnapshot.stationName = stationName
                    self.setAdditonalDataClients()
                }else{
                    DispatchQueue.main.async {
                        //if no data respond with alertview
                        self.stopActivityIndicator()
                        let alert = UIAlertController.init(title: "Not enough Data", message: "This bouy is not providing much data at the moment", preferredStyle: .alert)
                        let doneAction = UIAlertAction(title: "Cancel", style: .destructive)
                        alert.addAction(doneAction)
                            self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        switch collectionView {
        case is ProximalCollectionView:
            return UIEdgeInsetsMake(0, 0, 0, 0)
        default:
            return UIEdgeInsetsMake(0, 0, 0, 0)
        }
    }

    
    func setAdditonalDataClients(){
        tideClient = TideClient(currentSnapshot: self.selectedSnapshot)
        tideClient?.delegate = self
        tideClient?.createTideData()
        
        windClient = WindClient(currentSnapshot: self.selectedSnapshot)
        windClient?.delegate = self
        windClient?.createWindData()
        
        airTempClient = AirTempClient(currentSnapshot: self.selectedSnapshot)
        airTempClient?.delegate = self
        airTempClient?.createAirTempData()
    }
    
    func didFinishSurfQualityTask(sender: SurfQuality) {
        if let updatedSnapshot = surfQuality?.getSnapshotWithSurfQuality(){
            selectedSnapshot = updatedSnapshot
        }
        snapshotComponents["quality"] = true
        segueWhenAllComponenetsAreLoaded()
    }
    
    func didFinishTideTask(sender: TideClient, tides: [Tide]) {
        print("View Controller Has Tide Array with \(tides.count) tides")
        if let updatedSnapshot = tideClient?.addTideDataToSnapshot(selectedSnapshot, tideArray: tides){
            selectedSnapshot = updatedSnapshot
        }
        snapshotComponents["tide"] = true
        segueWhenAllComponenetsAreLoaded()
    }
    
    func didFinishWindTask(sender: WindClient, winds: [Wind]) {
        print("View Controller Has Wind Array with \(winds.count) winds")
        if let updatedSnapshot = windClient?.addWindDataToSnapshot(selectedSnapshot, windArray: winds){
            selectedSnapshot = updatedSnapshot
        }
        snapshotComponents["wind"] = true
        surfQuality = SurfQuality(currentSnapshot: self.selectedSnapshot)
        self.surfQuality?.createSurfQualityAssesment()
        surfQuality?.delegate = self
    }
    
    func didFinishAirTempTask(sender: AirTempClient, airTemps: [AirTemp]) {
        print("View Controller Has Air Temp Array with \(airTemps.count) air temps")
        if let updatedSnapshot = airTempClient?.addAirTempDataToSnapshot(selectedSnapshot, AirTempArray: airTemps){
            selectedSnapshot = updatedSnapshot
        }
        snapshotComponents["air"] = true
        segueWhenAllComponenetsAreLoaded()
    }
    
    func segueWhenAllComponenetsAreLoaded(){
        if !snapshotComponents.values.contains(false){
            stopActivityIndicator()
            let viewController = ViewController()
            viewController.cc_setZoomTransition(originalView: self.view)
            self.present(viewController, animated: true, completion: nil)
            
//            self.performSegue(withIdentifier: "showStationDetail", sender: self)
        }
    }

}
