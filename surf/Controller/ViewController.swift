//
//  SnapshotViewController.swift
//  surf
//
//  Created by Allen Spicer on 3/4/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit

final class ViewController: UIViewController, UIGestureRecognizerDelegate {

    private var displayLink: CADisplayLink?
    private var startTime: CFAbsoluteTime?
    private var path: UIBezierPath!
    var currentSnapShot = Snapshot()
    var stationId = Int()
    var stationName = String()
    private var waterColor: CGColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    private var aiView = UIView()
    private var wlView = UIView()
    var tideClient : TideClient?
    var windClient : WindClient?
    var airTempClient : AirTempClient?
    var activityIndicatorView = ActivityIndicatorView()
    var snapshotComponents = [String:Bool]()
    var favoriteButton = UIButton()
    var favoriteFlag = false
    var indexOfCurrentStationInFavoritesArray: Int?
    var favoritesArray = [Int]()
    var nicknamesArray = [String]()

    
    /// The `CAShapeLayer` that will contain the animated path
     private let shapeLayer: CAShapeLayer = {
        let _layer = CAShapeLayer()
        _layer.strokeColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        _layer.fillColor = UIColor.clear.cgColor
        _layer.lineWidth = 4
        return _layer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkStorageForFavorite()
        setupGestureRecognizer()
        setUIFromCurrentSnapshot(true)
        setupAnimatedWaveWithBouyData()
        setAdditonalDataClients()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        stopDisplayLink()
    }
    
    
    func checkStorageForFavorite(){
        indexOfCurrentStationInFavoritesArray = nil
        let defaults = UserDefaults.standard
        if let favorites = defaults.array(forKey: "favorites") as? [Int], let names = defaults.array(forKey: "nicknames") as? [String]{
            favoritesArray = favorites
            nicknamesArray = names
            for favorite in favorites {
                if currentSnapShot.stationId == favorite{
                    favoriteFlag = true
                    indexOfCurrentStationInFavoritesArray = favorites.index(of: favorite)
                }
            }
        }
    }
    
    func setupAnimatedWaveWithBouyData(){
        if let color = currentSnapShot.waterColor{
            waterColor = color
            self.shapeLayer.strokeColor = waterColor
        }
        self.view.layer.addSublayer(self.shapeLayer)
        self.startDisplayLink()
    }
    
    func setAdditonalDataClients(){
        tideClient = TideClient(currentSnapshot: self.currentSnapShot)
        tideClient?.delegate = self
        tideClient?.createTideData()

        windClient = WindClient(currentSnapshot: self.currentSnapShot)
        windClient?.delegate = self
        windClient?.createWindData()
        
        airTempClient = AirTempClient(currentSnapshot: self.currentSnapShot)
        airTempClient?.delegate = self
        airTempClient?.createAirTempData()
    }
    
    
    //
    //Gesture Recognizer
    //
    
    func setupGestureRecognizer() {
        let touchDown = UILongPressGestureRecognizer(target:self, action: #selector(didTouchDown))
        touchDown.minimumPressDuration = 0
        touchDown.delegate = self
        view.addGestureRecognizer(touchDown)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        view.addGestureRecognizer(swipeDown)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let viewTouched = touch.view{
            if viewTouched is UIButton { return false }
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    
    @objc func didTouchDown(gesture: UILongPressGestureRecognizer) {
        if (gesture.state == .began){
            for view in self.view.subviews as [UIView] {
                if let snapshotView = view as? SurfSnapshotView {
                    snapshotView.addWaveHeightIndicator()
//                    UIView.animate(withDuration: 0.3, animations: { () -> Void in
//                        self.view.backgroundColor = self.view.backgroundColor?.adjust(by: 30)
//                    })
//                    view.animateHide()
                }
            }
        }
        
        if (gesture.state == .ended){
            for view in self.view.subviews as [UIView] {
                if let snapshotView = view as? SurfSnapshotView {
                    snapshotView.removeWaveHeightIndicator()
//                    view.animateShow()
//                    UIView.animate(withDuration: 0.2, animations: { () -> Void in
//                        self.view.backgroundColor = self.view.backgroundColor?.adjust(by: -30)
//                    })
                }
            }
        }
    }
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.down:
                returnToTableView()
            default:
                break
            }
        }
    }
    
    
    //
    //Animation Components
    //

    
    /// Start the display link
    
    private func startDisplayLink() {
        startTime = CFAbsoluteTimeGetCurrent()
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector:#selector(handleDisplayLink(_:)))
        displayLink?.add(to: RunLoop.current, forMode: .commonModes)
    }
    
    /// Stop the display link
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    /// Handle the display link timer.
    ///
    /// - Parameter displayLink: The display link.
    
    @objc func handleDisplayLink(_ displayLink: CADisplayLink) {
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime!
        var waveHeightFloat :CGFloat = 0.0
        if let wHeight = currentSnapShot.waveHgt {
            let rounded = (wHeight * 10).rounded() / 10
            waveHeightFloat = CGFloat(rounded * 10)
        }
        
        if let path = wave(at: elapsed, waveHeightMax: waveHeightFloat).cgPath as CGPath?{
            shapeLayer.path = path
        }
    }
    
    /// Create the wave at a given elapsed time.
    ///
    /// You should customize this as you see fit.
    ///
    /// - Parameter elapsed: How many seconds have elapsed.
    /// - Returns: The `UIBezierPath` for a particular point of time.
    
    private func wave(at elapsed: Double, waveHeightMax: CGFloat) -> UIBezierPath {
        let centerY = view.bounds.height / 2
        var amplitude = CGFloat(0)
        var frequency = elapsed * 2
        if let period = currentSnapShot.waveAveragePeriod {
            frequency = elapsed * 2 / period
        }
        amplitude = CGFloat(waveHeightMax)
        
        func f(_ x: Int) -> CGFloat {
            return sin(((CGFloat(x) / view.bounds.width) + CGFloat(frequency)) * .pi) * amplitude + centerY
        }
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: f(0)))
        for x in stride(from: 0, to: Int(view.bounds.width + 9), by: 10) {
            path.addLine(to: CGPoint(x: CGFloat(x), y: f(x)))
        }
        
        return path
    }
    
    func returnToTableView(){
        self.performSegue(withIdentifier: "returnToHomeView", sender: self)
    }
    
    func setButton(_ button :UIButton){
        button.setTitle(favoriteFlag ? "Fav" : "Not Fav" , for: .normal)
        favoriteFlag = !favoriteFlag
    }
    
    func addFavoriteButton(){
        favoriteButton = UIButton(frame: CGRect(x: 40, y: 30, width: 40, height: 40))
        setButton(favoriteButton)
        favoriteButton.setTitleColor(.black, for: .normal)
        favoriteButton.titleLabel?.textColor = .black
        favoriteButton.addTarget(self, action: #selector(favoriteButtonAction), for: .touchUpInside)
        for view in self.view.subviews {
           if view is SurfSnapshotView {
               view.addSubview(favoriteButton)
               }
           }
        }
    
    

    @objc func favoriteButtonAction(){
        setButton(favoriteButton)
        
        if let index = indexOfCurrentStationInFavoritesArray as? Int {
            
            if index >= 0 {
                //subtract from array
                favoritesArray.remove(at: index)
                let defaults = UserDefaults.standard
                defaults.set(favoritesArray, forKey: "favorites")
                print("New Favorites Set: \(favoritesArray)")
                nicknamesArray.remove(at: index)
                defaults.set(favoritesArray, forKey: "nicknames")
                print("New Nicknames Set: \(nicknamesArray)")
            }
        }else{
            addFavorite()
        }
    }
        
        
    func addFavorite(){
        let alert = UIAlertController.init(title: "Pick a nickname", message: "What would you like to call this break?", preferredStyle: .alert)
        alert.addTextField { (textField) in textField.text = self.currentSnapShot.stationName}
        let okayAction = UIAlertAction(title: "Okay", style: .default){ (_) in
            guard let textFields = alert.textFields,
                textFields.count > 0 else {
                    // Could not find textfield
                    return
            }
            if let text = textFields[0].text {
                self.saveStationAndNameToFavoritesDefaults(nickname: text)
            }
        }
        alert.addAction(okayAction)
        let doneAction = UIAlertAction(title: "Cancel", style: .destructive)
        alert.addAction(doneAction)
        self.present(alert, animated: true, completion: nil)
        }
    
    func saveStationAndNameToFavoritesDefaults(nickname : String){
        favoritesArray.append(stationId)
        UserDefaults.standard.set(favoritesArray, forKey: "favorites")
        nicknamesArray.append(nickname)
        UserDefaults.standard.set(nicknamesArray, forKey: "nicknames")
        }
}

extension ViewController: TideClientDelegate, WindClientDelegate, AirTempDelegate{

    func didFinishTideTask(sender: TideClient, tides: [Tide]) {
        print("View Controller Has Tide Array with \(tides.count) tides")
        currentSnapShot = addTideDataToSnapshot(currentSnapShot, tideArray: tides)
        snapshotComponents["tide"] = true
        checkDataComponentsThenRefresh()
    }
    
    func didFinishWindTask(sender: WindClient, winds: [Wind]) {
        print("View Controller Has Wind Array with \(winds.count) winds")
        currentSnapShot = addWindDataToSnapshot(currentSnapShot, windArray: winds)
        snapshotComponents["wind"] = true
        checkDataComponentsThenRefresh()
    }
    
    func didFinishAirTempTask(sender: AirTempClient, airTemps: [AirTemp]) {
        print("View Controller Has Air Temp Array with \(airTemps.count) air temps")
        currentSnapShot = addAirTempDataToSnapshot(currentSnapShot, AirTempArray: airTemps)
        snapshotComponents["air"] = true
        checkDataComponentsThenRefresh()
    }
    
    func checkDataComponentsThenRefresh(){
        if !snapshotComponents.values.contains(false){
            setUIFromCurrentSnapshot(false)
        }
    }
    
    func setUIFromCurrentSnapshot(_ isFirstLoad : Bool){
        
        if isFirstLoad {
            let snapshotView = SurfSnapshotView.init(snapshot: self.currentSnapShot)
            self.view.addSubview(snapshotView)
            addFavoriteButton()
        }else{
            for view in self.view.subviews {
                if view is SurfSnapshotView {
                    view.removeFromSuperview()
                    let snapshotView = SurfSnapshotView.init(snapshot: self.currentSnapShot)
                    self.view.addSubview(snapshotView)
                    self.view.layer.addSublayer(self.shapeLayer)
                    addFavoriteButton()
                }
            }
        }
    }
    
}


