//
//  HomeViewController.swift
//  surf
//
//  Created by Allen Spicer on 6/6/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, UIGestureRecognizerDelegate{
    
    var standardMinimumLineSpacing : CGFloat = 80.0

    
    @IBOutlet weak var proximalCollectionView: UICollectionView!
    @IBOutlet weak var favoritesCollectionView: UICollectionView!
    private var proximalData = [Station]()
    private var cellSelectedIndex = Int()
    private var selectedSnapshot = Snapshot()
    private var selectedStationOrFavorite : Any? = nil
    var favoritesSnapshots = [Snapshot]()
    var snapshotComponents = [String:Bool]()
    var tideClient : TideClient?
    var windClient : WindClient?
    var airTempClient : AirTempClient?
    var surfQuality : SurfQuality?
    var userLocation = (0.0,0.0)
    let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
    let transitionComplete = Bool()
    var currentCard: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startActivityIndicator("Loading")
        parseStationList()
        setDelegatesAndDataSources()
        selectionFeedbackGenerator.prepare()
        applyGradientToBackground()
        setupGestureRecognizer()
        
        
        // Initial Flow Layout Setup
        let layout = self.favoritesCollectionView.collectionViewLayout as! FavoriteFlowLayout
        layout.estimatedItemSize = CGSize(width: 207.0, height: 264.0)
        layout.minimumLineSpacing = -standardMinimumLineSpacing
        
        //set current card
        if (favoritesSnapshots.count > 2) {currentCard = 1}
        
    }
    
    //
    // MARK: - Inital Load Logic
    //
    
    private func applyGradientToBackground(){
        let gradientView = GradientView(frame: self.view.frame)
        gradientView.firstColor = #colorLiteral(red: 0.01568627451, green: 0.6509803922, blue: 0.6509803922, alpha: 1)
        gradientView.secondColor = #colorLiteral(red: 0.01960784314, green: 0.01960784314, blue: 0.05098039216, alpha: 1)
        self.view.addSubview(gradientView)
        self.view.sendSubview(toBack: gradientView)
    }
    
    //
    //MARK: - Apply User Location to Proximal Dataset
    //
    
    private func findDistancesFromUserLocation(){
        
        // Used to convert latitude and longitude into miles
        // both numbers are approximate. One longitude at 40 degrees is about 53 miles however the true
        // number of miles is up to 69 at the equator and down to zero at the poles
        let approxMilesToLon = 53.0
        let approxMilesToLat = 69.0
//        if (userLatitude != 0 && userLongitude != 0) {
        if (userLocation.0 != 0 && userLocation.1 != 0) {
            for index in 0..<proximalData.count{
                let station = proximalData[index]
//                let latDiffAbs = abs(station.lat - userLatitude) * approxMilesToLat
//                let lonDiffAbs = abs(station.lon - userLongitude) * approxMilesToLon
                let latDiffAbs = abs(station.lat - userLocation.0) * approxMilesToLat
                let lonDiffAbs = abs(station.lon - userLocation.1) * approxMilesToLon
                let milesFromUser = (pow(lonDiffAbs, 2) + pow(latDiffAbs, 2)).squareRoot()
                proximalData[index].distanceInMiles = Int(milesFromUser)
            }
        }
        sortTableObjectsByDistance()
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
                        let station = Station(id: "\(id)", stationId: "\(stationId)", lat: lat, lon: lon, beachFaceDirection: beachFaceDirection, name: name, nickname: nil, distanceInMiles: 10000)
                        proximalData.append(station)
                    }
                    stopActivityIndicator()
                }
            } catch {
                // handle error
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destinationVC = segue.destination as? ViewController {
            destinationVC.currentSnapShot = selectedSnapshot
        }
    }
    
    
    
    //
    //MARK: - Gesture Recognizer
    //
    
    //
    //Gesture Recognizer
    //
    
    func setupGestureRecognizer() {
        let touchDown = UILongPressGestureRecognizer(target:self, action: #selector(didTouchDown))
        touchDown.minimumPressDuration = 0
        touchDown.delegate = self
        view.addGestureRecognizer(touchDown)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        //if touch is in current cell return true
        //else return false
        
        let contactPoint = touch.location(in: favoritesCollectionView)
        if let currentCell = favoritesCollectionView.cellForItem(at: IndexPath(item: currentCard, section: 0)) as? FavCollectionViewCell{
            if currentCell.frame.contains(contactPoint){ return true}
        }
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    
    @objc func didTouchDown(gesture: UILongPressGestureRecognizer) {
        let contactPoint = gesture.location(in: favoritesCollectionView)
        if (gesture.state == .began){
            if let currentCell = favoritesCollectionView.cellForItem(at: IndexPath(item: currentCard, section: 0)) as? FavCollectionViewCell{
                if currentCell.frame.contains(contactPoint){
                    currentCell.contentView.bringSubview(toFront: currentCell.mainView)
                }
            }
        }

        if (gesture.state == .ended){
            if let currentCell = favoritesCollectionView.cellForItem(at: IndexPath(item: currentCard, section: 0)) as? FavCollectionViewCell{
                    currentCell.contentView.sendSubview(toBack: currentCell.mainView)
                if currentCell.frame.contains(contactPoint){
                    self.snapshotComponents = ["wave" : true, "tide" : false, "wind" : false, "air" : false, "quality" : false]
                    self.setAdditonalDataClients()
                    selectedSnapshot = favoritesSnapshots[currentCard]
                    selectedStationOrFavorite = favoritesSnapshots[currentCard]
                    let transitionView = createViewForTransition()
                    self.view.addSubview(transitionView)
                    self.view.bringSubview(toFront: transitionView)
                    let centerPoint = CGPoint(x: self.view.center.x, y: currentCell.center.y + 16)
                    transitionView.center = centerPoint
                    transitionView.growCircleTo(800, duration: 1.2, completionBlock: {
                        self.performSegue(withIdentifier: "showStationDetail", sender: self)
                    })
                }
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
//MARK: - Extension to handle Collection View and Delegates Assignment
//

extension HomeViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, TideClientDelegate, WindClientDelegate, AirTempDelegate, SurfQualityDelegate{

    
    override func viewDidLayoutSubviews() {
        favoritesCollectionView.selectItem(at: IndexPath(item: currentCard, section: 0), animated: false, scrollPosition: .centeredHorizontally)
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
        var selectedId = String()
        var selectedName = String()
        var selectedBFD = Double()
        
        switch collectionView {
        case is ProximalCollectionView:
            startActivityIndicator("Loading")
            selectedStationOrFavorite = proximalData[cellSelectedIndex]
            selectedId = proximalData[cellSelectedIndex].stationId
            selectedName = proximalData[cellSelectedIndex].name
            selectedBFD = proximalData[cellSelectedIndex].beachFaceDirection
            selectedCellAction(indexPath.row, selectedId: selectedId, stationName: selectedName, selectedBFD: selectedBFD)
        case is FavoriteCollectionView:
            if indexPath.row != currentCard {
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                currentCard = indexPath.row
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
            cell.titleLabel.text = self.proximalData[indexPath.row].name
            cell.backgroundGradient.frame = cell.bounds
            return cell
        case is FavoriteCollectionView:
            let cell = favoritesCollectionView.dequeueReusableCell(withReuseIdentifier: "FavoriteCollectionViewCell", for: indexPath) as! FavCollectionViewCell
            cell.loadAllViews()
            let snapshot = self.favoritesSnapshots[indexPath.row]
            guard let waveHeight = snapshot.waveHgt else {return cell}
            guard let waveFrequency = snapshot.waveAveragePeriod else {return cell}
            //            guard let nickname = snapshot.nickname else {return cell}
            let nickname = snapshot.nickname ?? "nickname"
            cell.setCellContent(waveHeight: waveHeight, waveFrequency: waveFrequency, locationName: nickname, distanceFromUser: 10.0)
            return cell
        default:
            return UICollectionViewCell()
        }
    }
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        switch collectionView {
//        case is ProximalCollectionView:
//            return CGSize(width: 124, height: 124)
//        case is FavoriteCollectionView:
//            return CGSize(width: 207, height: 264)
//        default:
//            return CGSize()
//        }
//    }

    
    //
    //MARK: - Cell click action and data retreival delegates
    //
    
    
    private func selectedCellAction (_ index : Int, selectedId : String, stationName : String, selectedBFD : Double){
        DispatchQueue.global(qos:.utility).async {
            guard let id = Int(self.proximalData[index].id) else {return}
            let snapshotSetter = SnapshotSetter(stationId: selectedId, beachFaceDirection: selectedBFD, id:id, name: stationName)
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
        surfQuality = SurfQuality(currentSnapshot: selectedSnapshot)
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
            self.performSegue(withIdentifier: "showStationDetail", sender: self)
        }
    }
    
    
}


