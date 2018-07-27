//
//  BuoyClient.swift
//  surfbreak
//
//  Created by Allen Spicer on 7/26/18.
//  Copyright © 2018 surfbreak. All rights reserved.
//

import UIKit


protocol BuoyClientDelegate: AnyObject {
    func didFinishBuoyTask(sender: BuoyClient, buoys: [Buoy])
}

final class BuoyClient: NSObject {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var delegate : BuoyClientDelegate?
    var buoyArray = [Buoy]()
    var snapshotId = Int()
    var urlString = String()
    var snapshot = Snapshot.init()
    
    init(snapshotId:Int) {
        self.snapshotId = snapshotId
    }
    
    func createBuoyData() {
        DispatchQueue.global(qos:.utility).async {
            self.setUrlStringFromSnapshotId()
        }
    }
    
    func didGetBuoyData() {
        delegate?.didFinishBuoyTask(sender: self, buoys: buoyArray)
    }
    
    
    private func buoyDataServiceRequest(){
        
        var bouyDictionary : [Int : [String]] = [Int: [String]]()

        var dataString = String()
        let url = URL(string: urlString)

        do {
            dataString = try String(contentsOf: url!)
        }catch{
            print("Bouy Data Retreival Error: \(error)")
        }
        let lines = dataString.components(separatedBy: "\n")
        var rawStatArray : [String] = []
        
        for (index, line) in lines.enumerated(){
            if (index < 10 && index > 1){
                rawStatArray = line.components(separatedBy: " ")
                rawStatArray = rawStatArray.filter { $0 != "" }
                bouyDictionary[index] = rawStatArray
            }
        }
        
        guard bouyDictionary.count > 2 else {return}
        //determine how many buoy dictionaries are made. only make one the last one. don't loop through everything like below.
        
        let index = bouyDictionary.count - 1
        let currentSnapShot = Snapshot(context: self.context)
        guard let bouy = bouyDictionary[index] else {return}
        
        //wave height
        if let currentWaveHeight = Double(bouy[8]) as Double?{
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 1
            let heightInFeet = currentWaveHeight * 3.28
            currentSnapShot.waveHeight = heightInFeet
        }
        //wave direction
        if let currentWaveDirectionDegrees = Float(bouy[11]) as Float?{
//                currentSnapShot.swellDirection = Int32(0)
//                currentSnapShot.swellDirectionString = ""
            
//                currentSnapShot.swellDirection = Double(currentWaveDirectionDegrees)
//                currentSnapShot.swellDirectionString = directionFromDegrees(degrees: currentWaveDirectionDegrees)
        }
        //wave frequency/period
        if let waveAveragePeriod = Double(bouy[10]) as Double?{
            currentSnapShot.period = waveAveragePeriod
        }
        //water temp
        if let currentWaterTemp = Double(bouy[14]) as Double?{
//                let currentWaterTempInFahrenheit = fahrenheitFromCelcius(temp: currentWaterTemp)
            let currentWaterTempInFahrenheit = 0.0
            currentSnapShot.waterTemp = currentWaterTempInFahrenheit
            //set color of wave
//                if let waterColor = getWaterColorFromTempInF(currentWaterTempInFahrenheit){
//                    currentSnapShot.waterColor = waterColor
//                }
        }
        
        //station id
//            if let station = Int(stationId){
//                currentSnapShot.stationId = station
//            }
        
//            currentSnapShot.id = id
//            currentSnapShot.nickname = name
        
        //beach face direction
//            currentSnapShot.beachFaceDirection = beachFaceDirection
        
        print(currentSnapShot)
        self.snapshot = currentSnapShot
        DispatchQueue.main.async {
            self.didGetBuoyData()
        }
    }
    
    func getBuoyDataAsSnapshot()-> Snapshot {
        return self.snapshot
    }
    
    func setUrlStringFromSnapshotId(){
        
        //get all possible snapshots
        //use snapshot id
        //get station id to use for URL
        
        let stationId = "41110"
        urlString = "http://www.ndbc.noaa.gov/data/realtime2/\(stationId).txt"
        buoyDataServiceRequest()
    }
    

}
