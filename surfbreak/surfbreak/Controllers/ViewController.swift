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
    
    var currentSnapShot = Snapshot()
    var favoriteForUnwind : Favorite? = nil
    
    private var displayLink: CADisplayLink?
    private var startTime: CFAbsoluteTime?
    private var currentFavorite : Favorite? = nil
    private var favoriteButton = UIButton()
    private var favoriteFlag = false
    private var favoritesArray = [Favorite]()
    private var mainView = UIView(frame: UIScreen.main.bounds)
    private var backgroundImageView = UIImageView()
    
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
        self.view.addSubview(mainView)
        self.view.backgroundColor = .clear
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
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    func loadFavoritesAndSetFavoriteButton(){
        
        if Disk.exists(DefaultConstants.favorites, in: .caches) {
            do{
                favoritesArray = try Disk.retrieve(DefaultConstants.favorites, from: .caches, as: [Favorite].self)
            }catch{
                print("Retrieving from favorite automatic storage with Disk failed. Error is: \(error)")
            }
            for index in 0..<favoritesArray.count where favoritesArray[index].id == currentSnapShot.id {
                favoriteFlag = true
                currentFavorite = favoritesArray[index]
            }
        }
    }
    
    private func setupAnimatedWaveWithBouyData(){
        //        if let color = currentSnapShot.waterColor{
        //            waterColor = color
        //            self.shapeLayer.strokeColor = waterColor
        //        }
        mainView.layer.addSublayer(self.shapeLayer)
        self.startDisplayLink()
    }
    
    
    //
    //Gesture Recognizer
    //
    
    func setupGestureRecognizer() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didSwipe))
        panGesture.delegate = self
        mainView.addGestureRecognizer(panGesture)
        let tapGesture = UILongPressGestureRecognizer(target: self, action: #selector(didTap))
        tapGesture.minimumPressDuration = 0
        tapGesture.delegate = self
        mainView.addGestureRecognizer(tapGesture)
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
    
    
    //
    //Animation Components
    //
    
    @objc func didTap(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            for subview in mainView.subviews {
                if let view = subview as? SurfSnapshotView {
                    view.toggleMainLabel()
                    let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
                    selectionFeedbackGenerator.prepare()
                    selectionFeedbackGenerator.selectionChanged()
                }
            }
        }
    }
    
    
    @objc func didSwipe(gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else {return}
        let height = mainView.frame.height/2
        
        if gesture.state == .began || gesture.state == .changed {
            let translation = gesture.translation(in: mainView)
            if(view.center.y < (height * 1.5)) && (view.center.y >= height){
                view.center = CGPoint(x: view.center.x, y: view.center.y + translation.y)
            }else if (view.center.y >= (height * 1.5)){
                //height has hit max boundary
                let pop2 = SystemSoundID(1520)
                AudioServicesPlaySystemSoundWithCompletion(pop2, {})
                returnToTableView()
                self.backgroundImageView.removeFromSuperview()
            }
            gesture.setTranslation(CGPoint(x: 0, y: 0), in: mainView)
        }
        
        if gesture.state == .ended {
            UIView.animate(withDuration: 0.2, delay: 0,  options: .curveEaseInOut , animations: {
                view.center = CGPoint(x: view.center.x, y: height)
            }) { _ in
            }
        }
        
    }
    
    
    /// Start the display link
    
    private func startDisplayLink() {
        startTime = CFAbsoluteTimeGetCurrent()
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector:#selector(handleDisplayLink(_:)))
        displayLink?.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
    }
    
    /// Stop the display link
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    /// Handle the display link timer.
    /// - Parameter displayLink: The display link.
    
    @objc func handleDisplayLink(_ displayLink: CADisplayLink) {
        guard let startTime = startTime else {return}
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
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
        let centerY = mainView.bounds.height / 2
        var amplitude = CGFloat(0)
        var frequency = elapsed * 2
        frequency = elapsed * 2 / currentSnapShot.period
        amplitude = CGFloat(waveHeightMax)
        
        func f(_ x: Int) -> CGFloat {
            return sin(((CGFloat(x) / mainView.bounds.width) + CGFloat(frequency)) * .pi) * amplitude + centerY
        }
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: f(0)))
        for x in stride(from: 0, to: Int(mainView.bounds.width + 9), by: 10) {
            path.addLine(to: CGPoint(x: CGFloat(x), y: f(x)))
        }
        
        return path
    }
    
    private func returnToTableView(){
        self.performSegue(withIdentifier: "unwindToHomeSegue", sender: self)
    }
    
    private func setButton(){
        favoriteButton.setBackgroundImage(favoriteFlag ? #imageLiteral(resourceName: "Favorite") : #imageLiteral(resourceName: "NonFavorite") , for: .normal)
    }
    
    private func addFavoriteButton(){
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        setButton()
        favoriteButton.addTarget(self, action: #selector(favoriteButtonAction), for: .touchUpInside)
        for view in mainView.subviews {
            if view is SurfSnapshotView {
                mainView.addSubview(favoriteButton)
                favoriteButton.heightAnchor.constraint(equalToConstant: 37).isActive = true
                favoriteButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
                favoriteButton.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 8).isActive = true
                favoriteButton.rightAnchor.constraint(equalTo: view.safeRightAnchor, constant: -20).isActive = true
            }
        }
    }
    
    
    @objc func favoriteButtonAction(){
        if favoriteFlag {
            if let favorite = currentFavorite {
                //remove the favorite from local data
                favoritesArray = favoritesArray.filter({$0.id != favorite.id})
                
                //set up favorite removal for unwind segue
                favoriteForUnwind = favorite
            }
            do{
                //update persistence with local data to remove favorite
                try Disk.save(favoritesArray, to: .caches, as: DefaultConstants.favorites)
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                let alert = UIAlertController.init(title: "Success", message: "This station has been removed from your favorites", preferredStyle: .alert)
                let doneAction = UIAlertAction(title: "Okay", style: .default)
                alert.addAction(doneAction)
                self.present(alert, animated: true, completion: nil)
                favoriteFlag = !favoriteFlag
                setButton()
            }catch{
                print("Removing from favorite automatic storage with Disk failed. Error is: \(error)")
            }
        }else{
            addFavorite()
        }
    }
    
    
    private func addFavorite(){
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        favoriteFlag = !favoriteFlag
        setButton()
        saveStationAndNameToFavoritesDefaults(nickname: currentSnapShot.stationName)
        
        let alert = UIAlertController.init(title: "Success", message: "This station has been added to your favorites", preferredStyle: .alert)
        //        alert.addTextField { (textField) in textField.text = self.currentSnapShot.stationName}
        let okayAction = UIAlertAction(title: "Okay", style: .default){ (_) in
            //            guard let textFields = alert.textFields, textFields.count > 0 else {return}
            //            if let text = textFields[0].text {
            //                self.currentSnapShot.nickname = text
            //                for view in self.mainView.subviews {
            //                    if view is SurfSnapshotView {
            //                        if let surfView = view as? SurfSnapshotView{
            //                            surfView.titleLabel.text = text
            //                            self.favoriteFlag = !self.favoriteFlag
            //                            self.setButton()
            //                            self.feedbackGenerator.notification.notificationOccurred(.success)
            //                        }
            //                    }
            //                }
            //              self.saveStationAndNameToFavoritesDefaults(nickname: text)
            
            //            }
        }
        alert.addAction(okayAction)
        //        let doneAction = UIAlertAction(title: "Cancel", style: .destructive)
        //        alert.addAction(doneAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func saveStationAndNameToFavoritesDefaults(nickname : String){
        DispatchQueue.global(qos:.utility).async{
            let id = self.currentSnapShot.id
            let newFavorite = Favorite(id: id, nickname: nickname)
            self.currentFavorite = newFavorite
            self.favoriteForUnwind = newFavorite
            if Disk.exists(DefaultConstants.favorites, in: .caches) {
                do {
                    try Disk.append([newFavorite], to: DefaultConstants.favorites, in: .caches)
                }catch{
                    print("Appending to automatic storage with Disk failed. Error is: \(error)")
                }
            }else{
                do {
                    try Disk.save([newFavorite], to: .caches, as: DefaultConstants.favorites)
                }catch{
                    print("Saving to automatic storage with Disk failed. Error is: \(error)")
                }
            }
        }
    }
}

extension ViewController{
    private func setUIFromCurrentSnapshot(_ isFirstLoad : Bool){
        if isFirstLoad {
            let snapshotView = SurfSnapshotView.init(snapshot: self.currentSnapShot)
            mainView.addSubview(snapshotView)
            backgroundImageView = UIImageView(image: #imageLiteral(resourceName: "Bkgd_main"))
            backgroundImageView.frame = mainView.frame
            self.view.insertSubview(backgroundImageView, belowSubview: mainView)
            addFavoriteButton()
        }else{
            for view in mainView.subviews {
                if view is SurfSnapshotView {
                    view.removeFromSuperview()
                    let snapshotView = SurfSnapshotView.init(snapshot: self.currentSnapShot)
                    mainView.addSubview(snapshotView)
                    mainView.layer.addSublayer(self.shapeLayer)
                    addFavoriteButton()
                }
            }
        }
    }
    
}
