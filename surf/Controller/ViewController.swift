//
//  SnapshotViewController.swift
//  surf
//
//  Created by uBack on 3/4/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit
import CoreLocation


final class ViewController: UIViewController, CLLocationManagerDelegate {

    private var displayLink: CADisplayLink?
    private var startTime: CFAbsoluteTime?
    private var path: UIBezierPath!
    private var locationManager = CLLocationManager()
    private var userLongitude = 0.0
    private var userLatitude = 0.0
    private var latitudeLongitudeArray = [(Double,Double)]()
    private var bouyDictionary : [Int : [String]] = [Int: [String]]()
    var currentSnapShot : Snapshot? = nil
    private var waveIsLabeled = false
    private var waterColor: CGColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)

    
    /// The `CAShapeLayer` that will contain the animated path
     private let shapeLayer: CAShapeLayer = {
        let _layer = CAShapeLayer()
        _layer.strokeColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        _layer.fillColor = UIColor.clear.cgColor
        _layer.lineWidth = 4
        return _layer
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        
        startActivityIndicator()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupGestureRecognizer()
        isAuthorizedtoGetUserLocation()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        }
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestLocation();
        }
        
        DispatchQueue.main.async{
            let data = bouyDataServiceRequest(stationId: 41110, finished: {})
            self.currentSnapShot = data
            
            if let temp = self.currentSnapShot?.waterTemp {
                if let color = getWaterColorFromTempInF(temp){
                    self.shapeLayer.strokeColor = color
                }
            }
            self.stopActivityIndicator()
            self.setUIValuesWithBouyData()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        stopDisplayLink()
    }
    
    func findDataWithUserLocation(){
        var minDistance = 0.0
        var coordAtMinDistance = (0.0,0.0)
        
        if (userLatitude != 0 && userLongitude != 0) {
            for coord in latitudeLongitudeArray{
                
                guard let distanceFromNewPoint = pow((coord.0 - userLatitude), 2) + pow((coord.1 - userLongitude), 2) as Double? else {
                    return
                }
                    //calculate distance from point to user and previous point to user
                    //if new point is closer than previous point
                if (minDistance == 0.0 || minDistance > distanceFromNewPoint){
                    //save coorindates of new point over top
                    minDistance = distanceFromNewPoint
                        coordAtMinDistance = coord
                }
            }
        }
    }
    
    func setUIValuesWithBouyData(){
        
        guard let currentSnapShot  = currentSnapShot else {return}
        addUIComponentsToView(currentSnapShot: currentSnapShot, view: self.view)
        self.view.layer.addSublayer(self.shapeLayer)
        self.startDisplayLink()
    }
    
    func setupGestureRecognizer() {
        let touchDown = UILongPressGestureRecognizer(target:self, action: #selector(didTouchDown))
        touchDown.minimumPressDuration = 0
        view.addGestureRecognizer(touchDown)
    }
    
    @objc func didTouchDown(gesture: UILongPressGestureRecognizer) {
        if (gesture.state == .began){
            addWaveHeightIndicator(viewController: self)
            waveIsLabeled = true
        }
        if (gesture.state == .ended){
            if let subview = view.viewWithTag(100){
                subview.removeFromSuperview()
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
        var waveHeightMaxInt = 0
        if let waveHeight = currentSnapShot?.waveHgt as String?{
            if let intValue = Int(Double(waveHeight)! * 10) as Int?{
                waveHeightMaxInt = intValue
            }
        }
        
        if let path = wave(at: elapsed, waveHeightMax: waveHeightMaxInt).cgPath as CGPath?{
            shapeLayer.path = path
        }
    }
    
    /// Create the wave at a given elapsed time.
    ///
    /// You should customize this as you see fit.
    ///
    /// - Parameter elapsed: How many seconds have elapsed.
    /// - Returns: The `UIBezierPath` for a particular point of time.
    
    private func wave(at elapsed: Double, waveHeightMax: Int) -> UIBezierPath {
        let centerY = view.bounds.height / 2
        var amplitude = CGFloat(0)
        let shorten = fabs(fmod(CGFloat(elapsed), 3) - 1.5) * 40
        amplitude = CGFloat(waveHeightMax)
        
        func f(_ x: Int) -> CGFloat {
            return sin(((CGFloat(x) / view.bounds.width) + CGFloat(elapsed)) * .pi) * amplitude + centerY
        }
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: f(0)))
        for x in stride(from: 0, to: Int(view.bounds.width + 9), by: 10) {
            path.addLine(to: CGPoint(x: CGFloat(x), y: f(x)))
        }
        
        return path
    }
    
    
    ////
    //Location Services
    ////
    
    
    //if we have no permission to access user location, then ask user for permission.
    func isAuthorizedtoGetUserLocation() {
        
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse     {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    
    //this method will be called each time when a user change his location access preference.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            print("User allowed us to access location")
            locationManager.requestLocation();
        }
    }
    
    
    //this method is called by the framework on         locationManager.requestLocation();
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Did location updates is called")
        print(locations)
        setLocationDataFromResponse()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Did location updates is called but failed getting location \(error)")
    }
    
    
    func setLocationDataFromResponse(){
        if  let currentLocation = locationManager.location{
            userLatitude = currentLocation.coordinate.latitude
            userLongitude = currentLocation.coordinate.latitude
            findDataWithUserLocation()
//            self.setDataModel()
//            self.setUIValuesWithBouyData()
        }
    }
    
    
    func startActivityIndicator(){
        let ai = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        ai.tag = 200
        ai.color = .black
        view.addSubview(ai)
        ai.frame = view.bounds
        ai.startAnimating()
    }
    
    func stopActivityIndicator(){
        if let ai = view.viewWithTag(200) as? UIActivityIndicatorView{
            ai.stopAnimating()
            ai.removeFromSuperview()
        }
    }
    
}

