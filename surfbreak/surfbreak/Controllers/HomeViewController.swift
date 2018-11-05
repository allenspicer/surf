//
//  HomeViewController.swift
//  surf
//
//  Created by Allen Spicer on 6/6/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit
import Disk

class HomeViewController: UIViewController, UIGestureRecognizerDelegate{
    
    @IBOutlet weak var proximalCollectionView: UICollectionView!
    @IBOutlet weak var favoritesCollectionView: UICollectionView!
    
    var favoritesSnapshots = [Snapshot]()
    var userLocation : UserLocation? = nil
    var allStations = [Station]()

    private var proximalData = [ProximalStation]()
    private var userFavoritesForReturn = [Favorite]()
    private var idStationSelected = Int()
    private var distanceToUser = Int()
    private var transitionView = CircleView()
    private var mainView = CircleView()
    private var cellSelectedIndex = Int()
    private var selectedSnapshot = Snapshot()
    private var snapshotComponents = [String:Bool]()
    private let transitionComplete = Bool()
    private var currentCard: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupProximalAndFavoriteCollections()
        setupGestureRecognizer()
    }
    
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    //in some instances the custom transition will leave a circleview object in the heirarchy
    override func viewWillAppear(_ animated: Bool) {
        for view in view.subviews where view is CircleView{
            view.removeFromSuperview()
        }
    }
}

//
//MARK: - Applying User Location
//

extension HomeViewController {
    private func setupProximalAndFavoriteCollections(){
        // Assign data sources and delegate for collection views
        setDelegatesAndDataSources()
        
        for index in 0..<allStations.count{
            let station = allStations[index]
            let proximalStation = ProximalStation(station: station, distanceToUser: distanceFromUserWith(station))
            proximalData.append(proximalStation)
        }
        proximalData = proximalData.sorted(by: {$0.distanceToUser < $1.distanceToUser })
        proximalCollectionView.reloadData()
        
        //update distances for favorite snapshots
        for index in 0..<favoritesSnapshots.count {
            for station in allStations where favoritesSnapshots[index].stationId == station.station {
                var snapshot = favoritesSnapshots[index]
                snapshot.distance = distanceFromUserWith(station)
                favoritesSnapshots[index] = snapshot
            }
        }
        favoritesCollectionView.reloadData()
        
        // Initial Flow Layout Setup
        if let layout = self.favoritesCollectionView.collectionViewLayout as? FavoriteFlowLayout{
            let standardMinimumLineSpacing : CGFloat = 80.0
            layout.estimatedItemSize = CGSize(width: 207.0, height: 264.0)
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = -standardMinimumLineSpacing
        }
        
        //set current card
        if (favoritesSnapshots.count > 2) {currentCard = 1}
        stopActivityIndicator()
    }
    
    private func distanceFromUserWith(_ station : Station) -> Int{
        // Used to convert latitude and longitude into miles
        // both numbers are approximate. One longitude at 40 degrees is about 53 miles however the true
        // number of miles is up to 69 at the equator and down to zero at the poles
        guard let userLocation = userLocation else {return 0}
        let lon = userLocation.longitude
        let lat = userLocation.latitude
        
        let approxMilesToLon = 53.0
        let approxMilesToLat = 69.0
        let lonDiffAbs = abs(station.longitude - lon) * approxMilesToLon
        let latDiffAbs = abs(station.latitude - lat) * approxMilesToLat
        return Int((pow(lonDiffAbs, 2) + pow(latDiffAbs, 2)).squareRoot())
    }
    
}

//
//MARK: - Haptics
//

extension HomeViewController {
    private func feedbackForSelection(){
        let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
        selectionFeedbackGenerator.prepare()
        selectionFeedbackGenerator.selectionChanged()
    }
}

//
//MARK: - Activty Indicator Controls
//

extension HomeViewController {
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
//MARK: - User Interface helpers and fine tuning
//
    
    private func setFavoriteCollectionSelection (){
        if favoritesCollectionView.cellForItem(at: IndexPath(item: currentCard, section: 0)) != nil {
                        favoritesCollectionView.selectItem(at: IndexPath(item: currentCard, section: 0), animated: false, scrollPosition: .centeredHorizontally)
        }else{
            if favoritesCollectionView.cellForItem(at: IndexPath(item: 0, section: 0)) != nil {
                favoritesCollectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .centeredHorizontally)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        setFavoriteCollectionSelection()
    }
    
    private func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView == favoritesCollectionView {
            if (!decelerate) {scrollingHasStopped()}
        }
    }
    
    private func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == favoritesCollectionView {
            scrollingHasStopped()
        }
    }
    
    private func scrollingHasStopped(){
        var visibleRect = CGRect()
        visibleRect.origin = favoritesCollectionView.contentOffset
        visibleRect.size = favoritesCollectionView.bounds.size
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        guard let indexPath = favoritesCollectionView.indexPathForItem(at: visiblePoint) else { return }
        currentCard = indexPath.row
    }
    
}

//
//MARK: Collection View Needs and Delegate Assignments
//

extension HomeViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, BuoyClientDelegate, TideClientDelegate, WindClientDelegate, AirTempDelegate, SurfQualityDelegate{
    private func setDelegatesAndDataSources(){
        favoritesCollectionView.delegate = self
        proximalCollectionView.delegate = self
        favoritesCollectionView.dataSource = self
        proximalCollectionView.dataSource = self
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        feedbackForSelection()
        cellSelectedIndex = indexPath.row
        switch collectionView {
        case is ProximalCollectionView:
            startActivityIndicator("Loading")
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
            if favoritesSnapshots.count < 1 { return }
            idStationSelected = favoritesSnapshots[cellSelectedIndex].id
            if indexPath.row != currentCard {
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                currentCard = indexPath.row
            }else{
                selectedSnapshot = favoritesSnapshots[indexPath.row]
                guard let cell = collectionView.cellForItem(at: indexPath) as? FavCollectionViewCell else {return}
                let cellCenter = cell.convert(cell.imageView.center, to: cell.superview?.superview)
                transitionView = createViewForTransition()
                self.view.addSubview(transitionView)
                self.view.bringSubview(toFront: transitionView)
                let centerPoint = CGPoint(x: self.view.center.x, y: cellCenter.y)
                transitionView.center = centerPoint
                transitionView.growCircleTo(850, duration: 0.8, completionBlock: {
                    self.performSegue(withIdentifier: "segueToDetail", sender: self)
                })
            }
            
        default:
            break
        }
    }
    
    
    private func createViewForTransition()-> CircleView {
        let mainViewFrame = CGRect(x: 0.0, y: 0.0, width: 207.0, height: 207.0)
        mainView = CircleView(frame: mainViewFrame)
        mainView.snapshot = selectedSnapshot
        mainView.setAndAssign()
        return mainView
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case is ProximalCollectionView:
            return proximalData.count
        case is FavoriteCollectionView:
            if favoritesSnapshots.count < 1 { return 1 }
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
            cell.titleLabel.addCharacterSpacing(kernValue: 1.3)
            cell.distanceLabel.text = current.distanceToUser == 0 ? "Unknown Distance" : "\(current.distanceToUser)mi"
            cell.distanceLabel.addCharacterSpacing(kernValue: 1.4)
            return cell
        case is FavoriteCollectionView:
            if favoritesSnapshots.count < 1 {
            let cell = favoritesCollectionView.dequeueReusableCell(withReuseIdentifier: "PlaceholderFavoriteCollectionViewCell", for: indexPath) as! PlaceholderFavCollectionViewCell
                return cell
            }
            let cell = favoritesCollectionView.dequeueReusableCell(withReuseIdentifier: "FavoriteCollectionViewCell", for: indexPath) as! FavCollectionViewCell
            cell.loadAllViews()
            let snapshot = self.favoritesSnapshots[indexPath.row]
            let snapshotName = snapshot.nickname == "" ? snapshot.stationName : snapshot.nickname
            cell.setCellContent(waveHeight: snapshot.waveHeight, waveFrequency: snapshot.period, quality: snapshot.quality, locationName: snapshotName, distanceFromUser: snapshot.distance)
            return cell
        default:
            return UICollectionViewCell()
        }
    }
    
    
    private func selectedCellAction(){
        DispatchQueue.global(qos:.utility).async {
            let buoyClient = BuoyClient(snapshotId: self.idStationSelected, allStations: self.allStations)
            buoyClient.delegate = self
            buoyClient.createBuoyData()
            self.snapshotComponents = ["wave" : true, "tide" : false, "wind" : false, "air" : false, "quality" : false]
        }
    }
}

//
//MARK: - Retrieving and storage of data for proximal collection cells
//

extension HomeViewController {
    private func snapshotFromPersistence(_ snapshotId : Int)-> Snapshot?{
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
            let timeLimitInMinutes = 5.0
            let timeLimit : TimeInterval = 60.0 * timeLimitInMinutes
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
    
    
    func didFinishBuoyTask(sender: BuoyClient, snapshot: Snapshot, stations: [Station]) {
        print("The Buoy Client has returned a populated snapshot. Contents are: \(snapshot)")
        self.selectedSnapshot = snapshot
        self.selectedSnapshot.distance = self.distanceToUser
        //remove spinner for response:
        if (self.selectedSnapshot.waveHeight != 0.0 && self.selectedSnapshot.period != 0.0) {
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
    
    
    private func setAdditonalDataClients(){
        let tideClient = TideClient(currentSnapshot: self.selectedSnapshot)
        tideClient.delegate = self
        tideClient.createTideData()
        
        let windClient = WindClient(currentSnapshot: self.selectedSnapshot)
        windClient.delegate = self
        windClient.createWindData()
        
        let airTempClient = AirTempClient(currentSnapshot: self.selectedSnapshot)
        airTempClient.delegate = self
        airTempClient.createAirTempData()
    }
    
    
    func didFinishSurfQualityTask(sender: SurfQuality, snapshot: Snapshot) {
        selectedSnapshot = sender.getSnapshotWithSurfQuality()
        snapshotComponents["quality"] = true
        segueWhenAllComponenetsAreLoaded()
    }
    
    
    func didFinishTideTask(sender: TideClient, tides: [Tide], snapshot: Snapshot) {
        print("View Controller Has Tide Array with \(tides.count) tides")
        selectedSnapshot = sender.addTideDataToSnapshot(selectedSnapshot, tideArray: tides)
        snapshotComponents["tide"] = true
        segueWhenAllComponenetsAreLoaded()
    }
    
    
    func didFinishWindTask(sender: WindClient, winds: [Wind], snapshot: Snapshot) {
        print("View Controller Has Wind Array with \(winds.count) winds")
        selectedSnapshot = sender.addWindDataToSnapshot(selectedSnapshot, windArray: winds)
        snapshotComponents["wind"] = true
        let surfQuality = SurfQuality(currentSnapshot: selectedSnapshot)
        surfQuality.createSurfQualityAssesment()
        surfQuality.delegate = self
    }
    
    
    func didFinishAirTempTask(sender: AirTempClient, airTemps: [AirTemp], snapshot: Snapshot) {
        print("View Controller Has Air Temp Array with \(airTemps.count) air temps")
        selectedSnapshot = sender.addAirTempDataToSnapshot(selectedSnapshot, AirTempArray: airTemps)
        snapshotComponents["air"] = true
        segueWhenAllComponenetsAreLoaded()
    }
}

//
//MARK: - Retrieving and saving snapshot data
//

extension HomeViewController{
    private func dataLoadFailedUseFallBackFromPersistence(){
        var persistenceSnapshots = [Snapshot]()
        if Disk.exists(DefaultConstants.fallBackSnapshots, in: .documents) {
            do {
                persistenceSnapshots = try Disk.retrieve(DefaultConstants.fallBackSnapshots, from: .documents, as: [Snapshot].self)
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
    
    
    private func saveCompleteSnapshotToPersistence(with snapshots: [Snapshot]){
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
    
    
    private func loadPersistenceAndFallbackSnapshotsAndPopulateFavorites(){
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
        
        if Disk.exists(DefaultConstants.fallBackSnapshots, in: .documents) {
            do {
                fallbackSnapshots = try Disk.retrieve(DefaultConstants.fallBackSnapshots, from: .documents, as: [Snapshot].self)
            }catch{
                print("Retrieving snapshots from automatic storage with Disk failed. Error is: \(error)")
            }
        }
        
        //for all the users favorites
        for favorite in userFavoritesForReturn{
            
            //if a snapshot record is not in the tableview data
            if !favoritesSnapshots.map({$0.id}).contains(favorite.id){
                
                //look in persistence
                for var snapshot in persistenceSnapshots where snapshot.id == favorite.id{
                    if (favorite.nickname != ""){
                        snapshot.nickname = favorite.nickname
                    }
                    //append that key to favorites snapshots data
                    favoritesSnapshots.append(snapshot)
                    DispatchQueue.main.async {
                        self.favoritesCollectionView.reloadData()
                    }
                    return
                }
                
                //then fallback data
                for var snapshot in fallbackSnapshots where snapshot.id == favorite.id{
                    
                    if (favorite.nickname != ""){
                        snapshot.nickname = favorite.nickname
                    }
                    
                    //append that key to favorites snapshots data
                    favoritesSnapshots.append(snapshot)
                    DispatchQueue.main.async {
                        self.favoritesCollectionView.reloadData()
                    }
                }
            }
        }
    }
}

//
//MARK: - Gesture Recognizer for Data Reset
//

extension HomeViewController{
    private func setupGestureRecognizer() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress))
        longPressGesture.minimumPressDuration = 2
        longPressGesture.delegate = self
        self.view.addGestureRecognizer(longPressGesture)
    }
    
    
    @objc func didLongPress(gesture: UILongPressGestureRecognizer) {
        let alert = UIAlertController.init(title: "Reset All Data?", message: "Would you like to delete your settings? This will clear all cached data including favorites, location and wave data", preferredStyle: .alert)
        let resetAction = UIAlertAction(title: "Clear Data", style: .destructive){_ in
                do {
                    try Disk.clear(.caches)
                    self.performSegue(withIdentifier: "segueHomeToInitial", sender: self)
                }catch{
                    print("Attempting to clear caches in automatic storage with Disk failed. Error is: \(error)")
                }
        }
        alert.addAction(resetAction)
        let returnAction = UIAlertAction(title: "Nevermind", style: .default){_ in }
        alert.addAction(returnAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let viewTouched = touch.view{
            if viewTouched is UICollectionViewCell { return false }
        }
        return true
    }

}

//
//MARK: - Segue Handling
//

extension HomeViewController {
    private func segueWhenAllComponenetsAreLoaded(){
        if !snapshotComponents.values.contains(false){
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "segueToDetail", sender: self)
                self.stopActivityIndicator()
            }
            saveCompleteSnapshotToPersistence(with: [selectedSnapshot])
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? ViewController {
            favoritesCollectionView.collectionViewLayout.invalidateLayout()
            destinationVC.currentSnapShot = selectedSnapshot
        }
    }
    
    
    @IBAction func unwindToVC1(segue:UIStoryboardSegue) {
        for view in view.subviews where view is CircleView{
            view.removeFromSuperview()
        }
        if let sourceViewController = segue.source as? ViewController {
            
            //if there is a favorite to be removed or added
            if let favorite = sourceViewController.favoriteForUnwind {
                
                //if favorite needs to be removed
                if favoritesSnapshots.contains(where: {$0.id == favorite.id}){
                    favoritesSnapshots = favoritesSnapshots.filter({$0.id != favorite.id})
                    //reload and set when favorite is removed
                    favoritesCollectionView.reloadData()
                    self.setFavoriteCollectionSelection()

                //if favorite needs to be added
                }else{
                    favoritesSnapshots.append(sourceViewController.currentSnapShot)
                    
                    //reload and set when favorite is added
                    favoritesCollectionView.reloadData()
                    self.setFavoriteCollectionSelection()
                }
            }
        }
    }
}
