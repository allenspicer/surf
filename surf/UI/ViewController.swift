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
    var waveHeightMax = 0.0
    var waveHeightMin = 0
    var windSpeed = ""
    var windDirection = ""
    var waveDirection = ""
    var windUnit = ""
    var path: UIBezierPath!
//    var forecast: [Snapshot] = []
    var width: CGFloat = 0
    var height: CGFloat = 0
    var finalStats : [String] = []
//    var stationReport: BreakSnapshot? = nil
    var locationManager = CLLocationManager()
    var userLongitude = 0.0
    var userLatitude = 0.0
    var latitudeLongitudeArray = [(Double,Double)]()
    var waterTemp = 0.0
    let colorArray = [#colorLiteral(red: 0.4, green: 0.3450980392, blue: 0.8549019608, alpha: 1), #colorLiteral(red: 0.2941176471, green: 0.6078431373, blue: 0.8274509804, alpha: 1), #colorLiteral(red: 0.2705882353, green: 0.8705882353, blue: 0.4745098039, alpha: 1), #colorLiteral(red: 1, green: 0.7019607843, blue: 0.3137254902, alpha: 1)]
    static var waterColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)

    
    /// The `CAShapeLayer` that will contain the animated path
    
     let shapeLayer: CAShapeLayer = {
        let _layer = CAShapeLayer()
        _layer.strokeColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        _layer.fillColor = UIColor.clear.cgColor
        _layer.lineWidth = 4
        return _layer
    }()

    
    override func viewWillAppear(_ animated: Bool) {
        bouyDataServiceRequest()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isAuthorizedtoGetUserLocation()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        }
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestLocation();
        }
        

        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        self.view.backgroundColor = #colorLiteral(red: 0.2705882353, green: 0.8705882353, blue: 0.4745098039, alpha: 1)
        view.layer.addSublayer(shapeLayer)
        self.startDisplayLink()
        
        self.width = self.view.frame.width
        self.height = self.view.frame.height
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        stopDisplayLink()
    }
    
    struct StationStat {
        let value: String
        var isEmpty: Bool { if (value == ""){ return true}else{return false}}
        var desc: String {
            return value
        }
    }
    
    func bouyDataServiceRequest(){
        
        // 41110 Masenboro Inlet ILM2
        // 41038 Wrightsville Beach Nearshore ILM2
        // JMPN7 Johnny Mercer Pier
        
        do {

            let list = try String(contentsOf: URL(string: "http://www.ndbc.noaa.gov/data/realtime2/41110.txt")!)
            let lines = list.components(separatedBy: "\n")
            var rawStatArray : [String] = []
            
            
            var bouyDictionary : [Int : [String]] = [Int: [String]]()
            
            for (index, line) in lines.enumerated(){
                if (index < 10 && index > 1){
                    rawStatArray = line.components(separatedBy: " ")
                    rawStatArray = rawStatArray.filter { $0 != "" }
                    bouyDictionary[index] = rawStatArray
                }
            }
            
            if let firstBouy = bouyDictionary[2]{
                print(firstBouy)
                if let currentWaveHeight = Double(firstBouy[8]) as Double?{
                    waveHeightMax = currentWaveHeight * 3.28
                    print(waveHeightMax)
                }
                //wave direction
                if let currentWaveDirectionDegrees = Float(firstBouy[11]) as Float?{
                    waveDirection = windDirectionFromDegrees(degrees: currentWaveDirectionDegrees)
                    print(waveDirection)
                }
                //wind direction
                if let currentWindDirectionDegrees = Float(firstBouy[5]) as Float?{
                    windDirection = windDirectionFromDegrees(degrees: currentWindDirectionDegrees)
                    print(windDirection)
                }
                //wind speed
                if let currentWindSpeed = Int(firstBouy[6]) as Int?{
                    windSpeed = String(currentWindSpeed)
                    print(windSpeed)
                }
                //water temp
                if let currentWaterTemp = Double(firstBouy[14]) as Double?{
                    let waterTempTuple = fahrenheitFromCelcius(temp: currentWaterTemp)
                    waterTemp = waterTempTuple.temp
                    shapeLayer.strokeColor = waterTempTuple.waterColor.cgColor
                    print(waterTemp)
                }
            }

            

        DispatchQueue.main.async{
            self.setDataModel()
            self.setUIValuesWithBouyData()
        }
            
        }catch{
            print("Bouy Data Retreival Error: \(error)")
        }
    }
    
    
    func findDataWithUserLocation(){
        var minDistance = 0.0
        var coordAtMinDistance = (0.0,0.0)
        
        if (userLatitude != 0 && userLongitude != 0) {
            for coord in latitudeLongitudeArray{
                
                //square root of difference in lats squared + difference in longs squared
                if let distanceFromNewPoint = pow((coord.0 - userLatitude), 2) + pow((coord.1 - userLongitude), 2) as Double?{
                    
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
        print(minDistance)
        print(coordAtMinDistance)
        
    }
    
    
    func setDataModel(){
        

    }
    
    
    func setUIValuesWithBouyData(){
        self.addWaveHeightLabels()
        self.addSpotTitleLabel()
        self.addSpotDetails()
    }
    
    func addWaveHeightLabels(){
        
        var waveHeightDigitCount = CGFloat(0)
        switch waveHeightMax {
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
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        waveHeightLabel.text = formatter.string(from: (waveHeightMax as NSNumber))
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
        label.text = windSpeed + " " + windUnit + " " + windDirection + " WIND"
        label.font = UIFont(name:"Damascus", size: 10.0)
        label.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        let yValue = (self.view.frame.height/5) + 20
        label.center = CGPoint(x: self.view.frame.width/2, y:yValue)
        label.textAlignment = .center
        view.addSubview(label)
        
        let waveLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        waveLabel.text =  waveDirection + " SWELL"
        waveLabel.font = UIFont(name:"Damascus", size: 10.0)
        waveLabel.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        waveLabel.center = CGPoint(x: self.view.frame.width/2, y:yValue + 20)
        waveLabel.textAlignment = .center
        view.addSubview(waveLabel)
        
        let waterTempLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        waterTempLabel.text =  waveDirection + " SWELL"
        waterTempLabel.font = UIFont(name:"Damascus", size: 10.0)
        waterTempLabel.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        waterTempLabel.center = CGPoint(x: self.view.frame.width/2, y:yValue + 20)
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
        let waveHeightMaxInt = Int(waveHeightMax * 10)
        if let path = wave(at: elapsed, waveHeightMax: waveHeightMaxInt, waveHeightMin: (waveHeightMin * 10)).cgPath as CGPath?{
            shapeLayer.path = path
        }
    }
    
    /// Create the wave at a given elapsed time.
    ///
    /// You should customize this as you see fit.
    ///
    /// - Parameter elapsed: How many seconds have elapsed.
    /// - Returns: The `UIBezierPath` for a particular point of time.
    
    private func wave(at elapsed: Double, waveHeightMax: Int, waveHeightMin: Int) -> UIBezierPath {
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
    
    //
    // Helpers
    //
    
    func windDirectionFromDegrees(degrees : Float) -> String {
        
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let i: Int = Int((degrees + 11.25)/22.5)
        return directions[i % 16]
    }
    
    func fahrenheitFromCelcius(temp : Double) -> (temp: Double, waterColor: UIColor) {
        
        let tempInF = 5.0 / 9.0 * (temp) - 32.0
        var tempIndex = Int()
        
        switch tempInF {
        case -140..<40:
            tempIndex = 0
        case 40..<65:
            tempIndex = 1
        case 65..<80:
            tempIndex = 2
        case 80..<1000:
            tempIndex = 0
        default:
            tempIndex = 2
        }
        return (tempInF, colorArray[tempIndex])
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

