//
//  SnapshotViewController.swift
//  surf
//
//  Created by Allen Spicer on 3/4/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit
import AudioToolbox.AudioServices
import Disk


final class ViewController: UIViewController, UIGestureRecognizerDelegate {
    
    private var displayLink: CADisplayLink?
    private var startTime: CFAbsoluteTime?
    private var path: UIBezierPath!
    var currentSnapShot = Snapshot()
    var stationName = String()
    private var waterColor: CGColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    var activityIndicatorView = ActivityIndicatorView()
    var favoriteButton = UIButton()
    var favoriteFlag = false
    var favoritesArray = [Favorite]()
    var currentIndexInFavoritesArray = Int()
    let feedbackGenerator: (notification: UINotificationFeedbackGenerator, impact: (light: UIImpactFeedbackGenerator, medium: UIImpactFeedbackGenerator, heavy: UIImpactFeedbackGenerator), selection: UISelectionFeedbackGenerator) = {
        return (notification: UINotificationFeedbackGenerator(), impact: (light: UIImpactFeedbackGenerator(style: .light), medium: UIImpactFeedbackGenerator(style: .medium), heavy: UIImpactFeedbackGenerator(style: .heavy)), selection: UISelectionFeedbackGenerator())
    }()
    
    
    
    /// The `CAShapeLayer` that will contain the animated path
    private let shapeLayer: CAShapeLayer = {
        let _layer = CAShapeLayer()
        _layer.strokeColor = #colorLiteral(red: 1, green: 0.9803921569, blue: 0.8196078431, alpha: 1)
        _layer.fillColor = UIColor.clear.cgColor
        _layer.lineWidth = 4
        return _layer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadFavoritesAndSetFavoriteButton()
        setupGestureRecognizer()
        setUIFromCurrentSnapshot(true)
        if currentSnapShot.waveHeight != 0.0 {
            setupAnimatedWaveWithBouyData()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        stopDisplayLink()
    }
    
    
    func loadFavoritesAndSetFavoriteButton(){
        do{
            favoritesArray = try Disk.retrieve(DefaultConstants.favorites, from: .caches, as: [Favorite].self)
        }catch{
            print("Retrieving from favorite automatic storage with Disk failed. Error is: \(error)")
        }
        for index in 0..<favoritesArray.count where favoritesArray[index].id == currentSnapShot.id {
            favoriteFlag = true
            currentIndexInFavoritesArray = index
        }
    }
    
    func setupAnimatedWaveWithBouyData(){
//        if let color = currentSnapShot.waterColor{
//            waterColor = color
//            self.shapeLayer.strokeColor = waterColor
//        }
        self.view.layer.addSublayer(self.shapeLayer)
        self.startDisplayLink()
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
                let pop2 = SystemSoundID(1520)
                AudioServicesPlaySystemSoundWithCompletion(pop2, {
                })
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
    /// - Parameter displayLink: The display link.
    
    @objc func handleDisplayLink(_ displayLink: CADisplayLink) {
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime!
        var waveHeightFloat :CGFloat = 0.0
        let rounded = (currentSnapShot.waveHeight * 10).rounded() / 10
        waveHeightFloat = CGFloat(rounded * 10)
        if let path = wave(at: elapsed, waveHeightMax: waveHeightFloat).cgPath as CGPath?{
            shapeLayer.path = path
        }
    }
    
    /// Create the wave at a given elapsed time
    /// You should customize this as you see fit
    /// - Parameter elapsed: How many seconds have elapsed.
    /// - Returns: The `UIBezierPath` for a particular point of time.
    
    private func wave(at elapsed: Double, waveHeightMax: CGFloat) -> UIBezierPath {
        let centerY = view.bounds.height / 2
        var amplitude = CGFloat(0)
        var frequency = elapsed * 2
        frequency = elapsed * 2 / currentSnapShot.period
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
        self.performSegue(withIdentifier: "segueDetailToInitial", sender: self)
    }
    
    func setButton(){
        favoriteButton.setBackgroundImage(favoriteFlag ? #imageLiteral(resourceName: "Favorite") : #imageLiteral(resourceName: "NonFavorite") , for: .normal)
    }
    
    func addFavoriteButton(){
        favoriteButton.frame = CGRect(x: view.frame.width - 40.0, y: 32, width: 24, height: 37)
        favoriteButton.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        setButton()
        favoriteButton.addTarget(self, action: #selector(favoriteButtonAction), for: .touchUpInside)
        for view in self.view.subviews {
            if view is SurfSnapshotView {
                view.addSubview(favoriteButton)
            }
        }
    }
    
    
    
    @objc func favoriteButtonAction(){
        
        let id = currentSnapShot.id
        if favoriteFlag {
            feedbackGenerator.notification.notificationOccurred(.warning)
            let alert = UIAlertController.init(title: "This station has been removed from your favorites", message: nil, preferredStyle: .alert)
            let doneAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(doneAction)
            self.present(alert, animated: true, completion: nil)
            favoritesArray.remove(at: currentIndexInFavoritesArray)
            do{
                try Disk.save(favoritesArray, to: .caches, as: DefaultConstants.favorites)
            }catch{
                print("Removing from favorite automatic storage with Disk failed. Error is: \(error)")
            }
        }else{
            feedbackGenerator.notification.notificationOccurred(.success)
            addFavorite()
        }
        favoriteFlag = !favoriteFlag
        setButton()
        self.reloadInputViews()
    }
    
    
    func addFavorite(){
        let alert = UIAlertController.init(title: "Pick a nickname", message: "What would you like to call this station?", preferredStyle: .alert)
        alert.addTextField { (textField) in textField.text = self.currentSnapShot.stationName}
        let okayAction = UIAlertAction(title: "Okay", style: .default){ (_) in
            guard let textFields = alert.textFields, textFields.count > 0 else {return}
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
        DispatchQueue.global(qos:.utility).async{
            let id = self.currentSnapShot.id
            let newFavoriteInArray = Favorite(id: id, nickname: nickname)
            if Disk.exists(DefaultConstants.favorites, in: .caches) {
                do {
                    try Disk.append(newFavoriteInArray, to: DefaultConstants.favorites, in: .caches)
                }catch{
                    print("Appending to automatic storage with Disk failed. Error is: \(error)")
                }
            }else{
                do {
                    try Disk.save(newFavoriteInArray, to: .caches, as: DefaultConstants.favorites)
                }catch{
                    print("Saving to automatic storage with Disk failed. Error is: \(error)")
                }
            }
        }
    }
}

extension ViewController{
    
    
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
