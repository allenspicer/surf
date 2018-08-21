//
//  HomeViewController.swift
//  surf
//
//  Created by Allen Spicer on 6/6/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit
import CoreLocation
import Disk

class HomeViewController: UIViewController, UIGestureRecognizerDelegate{
    
    var standardMinimumLineSpacing : CGFloat = 80.0
    
    @IBOutlet weak var proximalCollectionView: UICollectionView!
    @IBOutlet weak var favoritesCollectionView: UICollectionView!
    var favoritesSnapshots = [Snapshot]()
    private var proximalData = [ProximalStation]()
    var allStations = [Station]()
    var userFavoritesForReturn = [Favorite]()
    var idStationSelected = Int()
    var distanceToUser = Int()

    private var cellSelectedIndex = Int()
    private var selectedSnapshot = Snapshot()
    private var selectedStationOrFavorite : Any? = nil
    
    var tideClient : TideClient?
    var windClient : WindClient?
    var airTempClient : AirTempClient?
    var surfQuality : SurfQuality?
    var snapshotComponents = [String:Bool]()

    var userLocation : UserLocation? = nil
    let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
    let transitionComplete = Bool()
    var currentCard: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createProximalCellsFromStations()
        setDelegatesAndDataSources()
        selectionFeedbackGenerator.prepare()
        applyGradientToBackground()
        
        // Initial Flow Layout Setup
        if let layout = self.favoritesCollectionView.collectionViewLayout as? FavoriteFlowLayout{
            layout.estimatedItemSize = CGSize(width: 207.0, height: 264.0)
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = -standardMinimumLineSpacing
        }

        //set current card
        if (favoritesSnapshots.count > 2) {currentCard = 1}
//
//        getUserFavoritesFromPersistence()
//        loadPersistenceAndFallbackSnapshotsAndPopulateFavorites()
        
        stopActivityIndicator()
    }
    
    private func applyGradientToBackground(){
        let backgroundView = UIImageView(frame: self.view.frame)
        backgroundView.image = #imageLiteral(resourceName: "Bkgd_main")
        backgroundView.contentMode = .center
        self.view.addSubview(backgroundView)
        self.view.sendSubview(toBack: backgroundView)
    }
    
    //
    //MARK: - Location Services
    //
    
    private func createProximalCellsFromStations(){
        
        // Used to convert latitude and longitude into miles
        // both numbers are approximate. One longitude at 40 degrees is about 53 miles however the true
        // number of miles is up to 69 at the equator and down to zero at the poles
        let approxMilesToLon = 53.0
        let approxMilesToLat = 69.0
        
        for index in 0..<allStations.count{
            let station = allStations[index]
            var distance = 0
            if let lon = userLocation?.longitude, let lat = userLocation?.latitude {
                let lonDiffAbs = abs(station.longitude - lon) * approxMilesToLon
                let latDiffAbs = abs(station.latitude - lat) * approxMilesToLat
                distance = Int((pow(lonDiffAbs, 2) + pow(latDiffAbs, 2)).squareRoot())
            }
            let proximalStation = ProximalStation(station: station, distanceToUser: distance)
            proximalData.append(proximalStation)
        }
        sortTableObjectsByDistance()
    }

    func sortTableObjectsByDistance(){
        proximalData = proximalData.sorted(by: {$0.distanceToUser < $1.distanceToUser })
        proximalCollectionView.reloadData()
        stopActivityIndicator()
    }
    
    //
    //MARK: - Buoy List for regional data station ids
    //
    
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
    
}

//
//MARK: - Extension to handle Collection View and Delegates Assignment
//

extension HomeViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate, TideClientDelegate, WindClientDelegate, AirTempDelegate, SurfQualityDelegate{
    
    
    override func viewDidLayoutSubviews() {
        if favoritesSnapshots.count > 0 {
            favoritesCollectionView.selectItem(at: IndexPath(item: currentCard, section: 0), animated: false, scrollPosition: .centeredHorizontally)
        }
        
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView == favoritesCollectionView {
            if (!decelerate) {scrollingHasStopped()}
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == favoritesCollectionView {
            scrollingHasStopped()
        }
    }
    
    func scrollingHasStopped(){
        var visibleRect = CGRect()
        visibleRect.origin = favoritesCollectionView.contentOffset
        visibleRect.size = favoritesCollectionView.bounds.size
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        guard let indexPath = favoritesCollectionView.indexPathForItem(at: visiblePoint) else { return }
        currentCard = indexPath.row
    }
    
    //
    //MARK: - Handling of Collection Views and Cell Display
    //
    
    
    func setDelegatesAndDataSources(){
        favoritesCollectionView.delegate = self
        proximalCollectionView.delegate = self
        
        favoritesCollectionView.dataSource = self
        proximalCollectionView.dataSource = self
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectionFeedbackGenerator.prepare()
        selectionFeedbackGenerator.selectionChanged()
        cellSelectedIndex = indexPath.row
        
        switch collectionView {
        case is ProximalCollectionView:
            startActivityIndicator("Loading")
            selectedStationOrFavorite = proximalData[cellSelectedIndex]
            idStationSelected = proximalData[cellSelectedIndex].station.id
            distanceToUser = proximalData[cellSelectedIndex].distanceToUser
            if var snapshot = snapshotFromPersistence(proximalData[cellSelectedIndex].station.id){
                snapshot.distance = self.distanceToUser
                selectedSnapshot = snapshot
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "segueToDetail", sender: self)
                    self.stopActivityIndicator()
                }
            }else{
                selectedCellAction()
            }
        case is FavoriteCollectionView:
            idStationSelected = favoritesSnapshots[cellSelectedIndex].id
            if indexPath.row != currentCard {
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                currentCard = indexPath.row
            }else{
                selectedSnapshot = favoritesSnapshots[indexPath.row]
                guard let cell = collectionView.cellForItem(at: indexPath) else {return}
                let transitionView = createViewForTransition()
                self.view.addSubview(transitionView)
                self.view.bringSubview(toFront: transitionView)
                let centerPoint = CGPoint(x: self.view.center.x, y: cell.center.y + 16)
                transitionView.center = centerPoint
                transitionView.growCircleTo(850, duration: 1.2, completionBlock: {
                    self.performSegue(withIdentifier: "segueToDetail", sender: self)
                    transitionView.removeFromSuperview()
                })
            }
            
        default:
            break
        }
    }
    
    func currentFavoriteCellSelected(){
        
    }
    
    func createViewForTransition()-> CircleView {
        let mainViewFrame = CGRect(x: 0.0, y: 0.0, width: 207.0, height: 207.0)
        let mainView = CircleView(frame: mainViewFrame)
        mainView.snapshot = selectedSnapshot
        mainView.setAndAssign()
        return mainView
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case is ProximalCollectionView:
            return proximalData.count
        case is FavoriteCollectionView:
            return favoritesSnapshots.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case is ProximalCollectionView:
            let cell = proximalCollectionView.dequeueReusableCell(withReuseIdentifier: "ProximalCollectionViewCell", for: indexPath) as! ProxCollectionViewCell
            let current = self.proximalData[indexPath.row]
            cell.titleLabel.text = current.station.name
            cell.distanceLabel.text = userLocation == nil ? "Unknown Distance" : "\(current.distanceToUser)mi"
            return cell
        case is FavoriteCollectionView:
            let cell = favoritesCollectionView.dequeueReusableCell(withReuseIdentifier: "FavoriteCollectionViewCell", for: indexPath) as! FavCollectionViewCell
            cell.loadAllViews()
            let snapshot = self.favoritesSnapshots[indexPath.row]
            cell.setCellContent(waveHeight: snapshot.waveHeight, waveFrequency: snapshot.period, quality: snapshot.quality, locationName: snapshot.stationName, distanceFromUser: snapshot.distance)
            return cell
        default:
            return UICollectionViewCell()
        }
    }
    
    
    //
    //MARK: - Cell click action and data retreival delegates
    //
    
    
    private func selectedCellAction(){
        self.startActivityIndicator("Loading...")
        
        DispatchQueue.global(qos:.utility).async {
            let buoyClient = BuoyClient(snapshotId: self.idStationSelected, allStations: self.allStations)
            buoyClient.delegate = self
            buoyClient.createBuoyData()
            self.snapshotComponents = ["wave" : true, "tide" : false, "wind" : false, "air" : false, "quality" : false]
        }
    }
    
    
    func snapshotFromPersistence(_ snapshotId : Int)-> Snapshot?{
        var snapshot : Snapshot? = nil
        var persistenceSnapshots = [Snapshot]()
        if Disk.exists(DefaultConstants.allSnapshots, in: .caches) {
            do {
                persistenceSnapshots = try Disk.retrieve(DefaultConstants.allSnapshots, from: .caches, as: [Snapshot].self)
            }catch{
                print("Retrieving from automatic storage with Disk failed. Error is: \(error)")
            }

            for persistenceSnapshot in persistenceSnapshots {
                if persistenceSnapshot.id == snapshotId {
                    snapshot = persistenceSnapshot
                }
            }
            
            //scrub records: if snapshot in persistence is older than an the time limit we should remove it
            let timeLimit : TimeInterval = 60.0 * 60.0
            persistenceSnapshots = persistenceSnapshots.filter({$0.timeStamp.timeIntervalSinceNow > timeLimit})
            
            do {
                try Disk.save(persistenceSnapshots, to: .caches, as: DefaultConstants.allSnapshots)
            }catch{
                print("Saving snapshots in automatic storage with Disk failed. Error is: \(error)")
            }
            
            return snapshot
        }
        return nil
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
    
    func didFinishSurfQualityTask(sender: SurfQuality, snapshot: Snapshot) {
        if let updatedSnapshot = surfQuality?.getSnapshotWithSurfQuality(){
            selectedSnapshot = updatedSnapshot
        }
        snapshotComponents["quality"] = true
        segueWhenAllComponenetsAreLoaded()
    }
    
    func didFinishTideTask(sender: TideClient, tides: [Tide], snapshot: Snapshot) {
        print("View Controller Has Tide Array with \(tides.count) tides")
        if let updatedSnapshot = tideClient?.addTideDataToSnapshot(selectedSnapshot, tideArray: tides){
            selectedSnapshot = updatedSnapshot
        }
        snapshotComponents["tide"] = true
        segueWhenAllComponenetsAreLoaded()
    }
    
    func didFinishWindTask(sender: WindClient, winds: [Wind], snapshot: Snapshot) {
        print("View Controller Has Wind Array with \(winds.count) winds")
        if let updatedSnapshot = windClient?.addWindDataToSnapshot(selectedSnapshot, windArray: winds){
            selectedSnapshot = updatedSnapshot
        }
        snapshotComponents["wind"] = true
        surfQuality = SurfQuality(currentSnapshot: selectedSnapshot)
        self.surfQuality?.createSurfQualityAssesment()
        surfQuality?.delegate = self
    }
    
    func didFinishAirTempTask(sender: AirTempClient, airTemps: [AirTemp], snapshot: Snapshot) {
        print("View Controller Has Air Temp Array with \(airTemps.count) air temps")
        if let updatedSnapshot = airTempClient?.addAirTempDataToSnapshot(selectedSnapshot, AirTempArray: airTemps){
            selectedSnapshot = updatedSnapshot
        }
        snapshotComponents["air"] = true
        segueWhenAllComponenetsAreLoaded()
    }
    
    func segueWhenAllComponenetsAreLoaded(){
        if !snapshotComponents.values.contains(false){
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "segueToDetail", sender: self)
                self.stopActivityIndicator()
            }
            saveCompleteSnapshotToPersistence(with: [selectedSnapshot])
        }
    }
    
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

extension HomeViewController : BuoyClientDelegate{
    func didFinishBuoyTask(sender: BuoyClient, snapshot: Snapshot, stations: [Station]) {
        print("The Buoy Client has returned a populated snapshot. Contents are: \(snapshot)")
        self.selectedSnapshot = snapshot
        self.selectedSnapshot.distance = self.distanceToUser
            //remove spinner for response:
            if (self.selectedSnapshot.waveHeight != 0.0 && self.selectedSnapshot.waterTemp != 0.0) {
//                self.selectedSnapshot.stationName = stationName
                self.setAdditonalDataClients()
            }else{
                DispatchQueue.main.async {
                    //if no data respond with alertview
                    self.stopActivityIndicator()
                    let alert = UIAlertController.init(title: "Not enough Data", message: "This data is a little old. The bouy you want is not providing much data at the moment.", preferredStyle: .alert)
                    let retryAction = UIAlertAction(title: "Retry", style: .destructive){_ in
                        self.selectedCellAction()
                    }
                    alert.addAction(retryAction)
                    let continueAction = UIAlertAction(title: "Continue", style: .default){_ in
                        self.dataLoadFailedUseFallBackFromPersistence()
                        }
                    alert.addAction(continueAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
    }
    
    func dataLoadFailedUseFallBackFromPersistence(){
        
        var persistenceSnapshots = [Snapshot]()
        
        if Disk.exists(DefaultConstants.fallBackSnapshots, in: .caches) {
            do {
                persistenceSnapshots = try Disk.retrieve(DefaultConstants.fallBackSnapshots, from: .caches, as: [Snapshot].self)
            }catch{
                print("Retrieving from automatic storage with Disk failed. Error is: \(error)")
            }
            
            for persistenceSnapshot in persistenceSnapshots {
                if persistenceSnapshot.id == idStationSelected {
                    self.selectedSnapshot = persistenceSnapshot
                    self.stopActivityIndicator()
                    self.snapshotComponents = [String:Bool]()
                    self.performSegue(withIdentifier: "segueToDetail", sender: self)
                }
            }
        }
    }
}

extension HomeViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destinationVC = segue.destination as? ViewController {
            destinationVC.currentSnapShot = selectedSnapshot
        }
    }
    
    @IBAction func unwindToVC1(segue:UIStoryboardSegue) {
        DispatchQueue.global(qos:.utility).async {
            self.getUserFavoritesFromPersistence()
            self.loadPersistenceAndFallbackSnapshotsAndPopulateFavorites()
        }
    }

    func loadPersistenceAndFallbackSnapshotsAndPopulateFavorites(){
        var persistenceSnapshots = [Snapshot]()
        var fallbackSnapshots = [Snapshot]()

        if Disk.exists(DefaultConstants.allSnapshots, in: .caches) {
            do {
                persistenceSnapshots = try Disk.retrieve(DefaultConstants.allSnapshots, from: .caches, as: [Snapshot].self)
            }catch{
                print("Retrieving snapshots from automatic storage with Disk failed. Error is: \(error)")
            }
 
            //scrub records: if snapshot in persistence is older than an the time limit we should remove it
            let timeLimit : TimeInterval = 60.0 * 60.0
            persistenceSnapshots = persistenceSnapshots.filter({$0.timeStamp.timeIntervalSinceNow < timeLimit})
            persistenceSnapshots = persistenceSnapshots.sorted(by: {$0.timeStamp < $1.timeStamp})
            persistenceSnapshots = persistenceSnapshots.uniqueElements

            do {
                try Disk.save(persistenceSnapshots, to: .caches, as: DefaultConstants.allSnapshots)
            }catch{
                print("Saving snapshots in automatic storage with Disk failed. Error is: \(error)")
            }
        }
        
        if Disk.exists(DefaultConstants.fallBackSnapshots, in: .caches) {
            do {
                fallbackSnapshots = try Disk.retrieve(DefaultConstants.fallBackSnapshots, from: .caches, as: [Snapshot].self)
            }catch{
                print("Retrieving snapshots from automatic storage with Disk failed. Error is: \(error)")
            }
        }
        
        //for all the users favorites
        for favorite in userFavoritesForReturn{

            //if a snapshot record is not in the tableview data
            if !favoritesSnapshots.map({$0.id}).contains(favorite.id){
                
                //look in persistence
                for snapshot in persistenceSnapshots where snapshot.id == favorite.id{
                    
                    //append that key to favorites snapshots data
                    favoritesSnapshots.append(snapshot)
                    DispatchQueue.main.async {
                        self.favoritesCollectionView.reloadData()
                    }
                    return
                }

                //then fallback data
                for snapshot in fallbackSnapshots where snapshot.id == favorite.id{
                    
                    //append that key to favorites snapshots data
                    favoritesSnapshots.append(snapshot)
                    DispatchQueue.main.async {
                        self.favoritesCollectionView.reloadData()
                    }
                }
            }
        }
    }
    
    func getUserFavoritesFromPersistence(){
        var favoritesArray = [Favorite]()
        if Disk.exists(DefaultConstants.favorites, in: .caches) {
            do{
                favoritesArray = try Disk.retrieve(DefaultConstants.favorites, from: .caches, as: [Favorite].self)
            }catch{
                print("Retrieving from favorite automatic storage with Disk failed. Error is: \(error)")
            }
            userFavoritesForReturn = favoritesArray
            removePreviousFavoritesFromTableData()
        }
    }
    
    
    
    func removePreviousFavoritesFromTableData(){
        favoritesSnapshots = favoritesSnapshots.filter({ userFavoritesForReturn.map({$0.id}).contains($0.id)})
        DispatchQueue.main.async {
            self.favoritesCollectionView.reloadData()
        }
    }
}
