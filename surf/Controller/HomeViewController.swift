//
//  HomeViewController.swift
//  surf
//
//  Created by uBack on 6/6/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit
import CoreLocation

class HomeViewController: UIViewController {

    @IBOutlet weak var favoritesCollectionView: UICollectionView!
    @IBOutlet weak var proximalCollectionView: UICollectionView!
    private var favoritesData = [Station]()
    private var proximalData = [Station]()
    private var cellSelectedIndex = Int()
    private var selectedSnapshot = Snapshot()
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
        let approxMilesToLon = 53
        let approxMilesToLat = 69
        
        if (userLatitude != 0 && userLongitude != 0) {
            for index in 0..<proximalData.count{
                let station = proximalData[index]
                let absoluteLonDiff = Int(abs(station.lon - userLongitude).rounded())
                let absoluteLatDiff = Int(abs(station.lat - userLatitude).rounded())
                let distanceInMiles = (absoluteLatDiff * approxMilesToLat) + (absoluteLonDiff * approxMilesToLon)
                proximalData[index].distanceInMiles = distanceInMiles
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
                        guard let lon = station["longitude"] as? Double else {return}
                        guard let lat = station["latitude"] as? Double else {return}
                        let station : Station = Station(id: "\(stationId)", lat: lat, lon: lon, owner: nil, name: station["name"] as? String ?? "", distance: 10000.0, distanceInMiles: 10000)
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
                if let metaData = jsonResult as? [[String : AnyObject]]{
                    for station in metaData {
                        guard let stationId = station["station"] as? Int else {return}
                        if !self.favoriteStationIdsFromMemory.values.contains(stationId) {continue}
                        guard let lon = station["longitude"] as? Double else {return}
                        guard let lat = station["latitude"] as? Double else {return}
                        let station : Station = Station(id: "\(stationId)", lat: lat, lon: lon, owner: nil, name: station["name"] as? String ?? "", distance: 10000.0, distanceInMiles: 10000)
                        favoritesData.append(station)
                        return
                    }
                    DispatchQueue.main.async{
                        self.favoritesCollectionView.reloadData()
                        self.stopActivityIndicator()
                    }
                }
            } catch {
                // handle error
                print("Problem accessing regional buoy list docuemnt: \(error)")
            }
        }
    }
    
    private func addStationWithIdLatLon(id :String, lat : Double, lon : Double, name: String){

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let selectedStation = proximalData[cellSelectedIndex]
        
        if let destinationVC = segue.destination as? ViewController {
            if let id = Int(selectedStation.id){
                destinationVC.stationId = id
            }
            destinationVC.currentSnapShot = selectedSnapshot
            if destinationVC.currentSnapShot != nil {
                destinationVC.snapshotComponents = ["wave" : true, "tide" : false, "wind" : false, "air" : false]
            }
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
//MARK: - Extension to handle Collection View
//

extension HomeViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate{
    
    func setDelegatesAndDataSources(){
        favoritesCollectionView.delegate = self
        proximalCollectionView.delegate = self
        
        favoritesCollectionView.dataSource = self
        proximalCollectionView.dataSource = self
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectionFeedbackGenerator.prepare()
        selectionFeedbackGenerator.selectionChanged()
        startActivityIndicator("Loading")
        cellSelectedIndex = indexPath.row
        var selectedId = String()
        var selectedName = String()
        
        switch collectionView {
        case is ProximalCollectionView:
                selectedId = proximalData[cellSelectedIndex].id
                if let name = proximalData[cellSelectedIndex].name {
                    selectedName = name
                }
        case is FavoriteCollectionView:
                selectedId = favoritesData[cellSelectedIndex].id
                if let name = favoritesData[cellSelectedIndex].name {
                    selectedName = name
            }        default:
            break
        }
        selectedCellAction(indexPath.row, selectedId: selectedId, stationName: selectedName)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case is ProximalCollectionView:
          return proximalData.count
        case is FavoriteCollectionView:
            return favoritesData.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case is ProximalCollectionView:
            let cell = proximalCollectionView.dequeueReusableCell(withReuseIdentifier: "ProximalCollectionViewCell", for: indexPath) as! ProxCollectionViewCell
            cell.imageView.image = imageArray[indexPath.row]
            cell.titleLabel.textColor = .black
            cell.titleLabel.text = self.proximalData[indexPath.row].name
            return cell
        case is FavoriteCollectionView:
            let cell = favoritesCollectionView.dequeueReusableCell(withReuseIdentifier: "FavoriteCollectionViewCell", for: indexPath) as! FavCollectionViewCell
            cell.imageView.image = imageArray[indexPath.row]
            cell.imageView.layer.cornerRadius = 75
            cell.imageView.layer.masksToBounds = true
            cell.titleLabel.textColor = .black
            cell.titleLabel.text = "Unnamed"
            print("nicknames are: \(nicknamesArray)")
            print("favorites are: \(favoritesData)")
            
            
            if let name = nicknamesArray[indexPath.row] as? String{
                cell.titleLabel.text = name
            }
            return cell
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch collectionView {
        case is ProximalCollectionView:
            return CGSize(width: 100, height: 140)
        case is FavoriteCollectionView:
            return CGSize(width: 150, height: 200)
        default:
            return CGSize()
        }
    }
    
    private func selectedCellAction (_ index : Int, selectedId : String, stationName : String){
        DispatchQueue.global(qos:.utility).async {
            let data = createSnapshot(stationId: selectedId, finished: {})
            //remove spinner for response:
            DispatchQueue.main.async {
                if data.waveHgt != nil && data.waterTemp != nil {
                    self.stopActivityIndicator()
                    self.selectedSnapshot = data
                    self.selectedSnapshot.stationName = stationName
                        self.performSegue(withIdentifier: "showStationDetail", sender: self)
                }else{
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
        case is FavoriteCollectionView:
            let cellWidth : CGFloat = 150
            let numberOfCells = CGFloat(favoritesData.count)
            let edgeInsets = (self.view.frame.size.width - (numberOfCells * cellWidth)) / (numberOfCells + 1)
            return UIEdgeInsetsMake(0, edgeInsets, 0, edgeInsets)
        default:
            return UIEdgeInsetsMake(0, 0, 0, 0)
        }
    }

        

}
