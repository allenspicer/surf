//
//  ViewController.swift
//  surf
//
//  Created by uBack on 3/4/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit
import CoreLocation


class ViewController: UIViewController, CLLocationManagerDelegate {

    private var displayLink: CADisplayLink?
    private var startTime: CFAbsoluteTime?
    var windUnit = "MPH"
    var path: UIBezierPath!
    var locationManager = CLLocationManager()
    var userLongitude = 0.0
    var userLatitude = 0.0
    var latitudeLongitudeArray = [(Double,Double)]()
    var bouyDictionary : [Int : [String]] = [Int: [String]]()
    var currentSnapShot : Snapshot? = nil
    var waveIsLabeled = false
    
    /// The `CAShapeLayer` that will contain the animated path
     let shapeLayer: CAShapeLayer = {
        let _layer = CAShapeLayer()
        _layer.strokeColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        _layer.fillColor = UIColor.clear.cgColor
        _layer.lineWidth = 4
        return _layer
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        
        DispatchQueue.main.async{
            let dataTuple = bouyDataServiceRequest{}
            self.currentSnapShot = dataTuple.0
            self.shapeLayer.strokeColor = dataTuple.1
            self.setUIValuesWithBouyData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addGestureRecognizer()
        isAuthorizedtoGetUserLocation()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        }
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestLocation();
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
    
    //TODO: The five functions contained in setUIValuesWithBouyData are all UI. They need to be moved to a view layer
    
    func setUIValuesWithBouyData(){
        self.addWaveHeightLabels()
        self.addSpotTitleLabel()
        self.addSpotDetails()
        self.view.layer.addSublayer(self.shapeLayer)
        self.startDisplayLink()
    }
    
    func addWaveHeightLabels(){
        
        var waveHeightDigitCount = CGFloat(0)
        var waveHeight = 0.0
        if let wHeight = currentSnapShot?.waveHgt as String?{
            waveHeight = Double(wHeight) ?? 0.0
        }
        
        switch waveHeight{
        case ...9:
            waveHeightDigitCount = 2
        case 10...99:
            waveHeightDigitCount = 3
        case 100...:
            waveHeightDigitCount = 4
        default:
            waveHeightDigitCount = 2
        }
        let offset: CGFloat = 45 * waveHeightDigitCount
        
        let widthPixels = 150 * waveHeightDigitCount + 100
        
        let waveHeightLabel = UILabel(frame: CGRect(x: 0, y: 0, width: widthPixels, height: 100))
        if let waveHeight = currentSnapShot?.waveHgt as String?{
            waveHeightLabel.text = waveHeight
        }
        waveHeightLabel.font = UIFont(name:"Damascus", size: 80.0)
        waveHeightLabel.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        waveHeightLabel.center = CGPoint(x: self.view.frame.width - offset, y: 90)
        waveHeightLabel.textAlignment = .center
        view.addSubview(waveHeightLabel)
        
        let feetLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        feetLabel.text = "ft"
        feetLabel.font = UIFont(name:"Damascus", size: 20.0)
        feetLabel.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        feetLabel.center = CGPoint(x: (self.view.frame.width - offset) + 20 + (waveHeightDigitCount * 20), y: 95)
        feetLabel.textAlignment = .center
        view.addSubview(feetLabel)
    }
    
    func addSpotDetails(){
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        if  let speed = currentSnapShot?.windSpd as String?{
            if let direction = currentSnapShot?.windDir as String?{
                label.text = speed + " " + windUnit + " " + direction + " WIND"
            }
        }
        label.font = UIFont(name:"Damascus", size: 10.0)
        label.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        let yValue = (self.view.frame.height/5) + 20
        label.center = CGPoint(x: self.view.frame.width/2, y:yValue)
        label.textAlignment = .center
        view.addSubview(label)
        
        let waveLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        if let direction = currentSnapShot?.meanWaveDirection as String?{
            waveLabel.text =  direction + " SWELL"
        }
        waveLabel.font = UIFont(name:"Damascus", size: 10.0)
        waveLabel.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        waveLabel.center = CGPoint(x: self.view.frame.width/2, y:yValue + 20)
        waveLabel.textAlignment = .center
        view.addSubview(waveLabel)
        
        let waterTempLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        if let temp = currentSnapShot?.waterTemp {
            waterTempLabel.text =  temp + "°F WATER"
        }
        waterTempLabel.font = UIFont(name:"Damascus", size: 10.0)
        waterTempLabel.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        waterTempLabel.center = CGPoint(x: self.view.frame.width/2, y: yValue + 40)
        waterTempLabel.textAlignment = .center
        view.addSubview(waterTempLabel)
    }
    
    func addSpotTitleLabel(){
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 200))
        titleLabel.text = "Crystal Pier"
        titleLabel.font = UIFont(name:"Damascus", size: 40.0)
        titleLabel.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        titleLabel.center = CGPoint(x: self.view.frame.width/2, y: self.view.frame.height/5)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
    }
    
    
    func addWaveHeightIndicator(){
        
        let centerY = view.bounds.height / 2
        var waveHeightMaxInt: CGFloat = 0
        if let waveHeight = currentSnapShot?.waveHgt as String?{
            if let intValue = CGFloat(Double(waveHeight)! * 10) as CGFloat?{
                waveHeightMaxInt = intValue
            }
        }
        let waveTop = centerY - waveHeightMaxInt - 14
        let waveHeightLabel = UILabel(frame: CGRect(x: 0, y: waveTop, width: 100, height: 20))
        if let waveHeight = currentSnapShot?.waveHgt as String?{
            waveHeightLabel.text = "__ \(waveHeight)ft"
        }
        waveHeightLabel.font = UIFont(name:"Damascus", size: 10.0)
        waveHeightLabel.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        waveHeightLabel.textAlignment = .left
        waveHeightLabel.tag = 100
        view.addSubview(waveHeightLabel)
    }
    
    
    func addGestureRecognizer(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tap(_:)))
        view.addGestureRecognizer(tap)
        view.isUserInteractionEnabled = true

    }
    
    @objc func tap(_ sender: UITapGestureRecognizer) {
        
        if (waveIsLabeled){
            if let viewWithTag = self.view.viewWithTag(100) {
                viewWithTag.removeFromSuperview()
                waveIsLabeled = false
            }
        }else{
            addWaveHeightIndicator()
            waveIsLabeled = true
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
    
    
}

