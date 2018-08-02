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
    var currentStation = Station()
    var snapshot : AnyObject?
    
    init(snapshotId:Int) {
        self.snapshotId = snapshotId
    }
    
    func createBuoyData() {
        DispatchQueue.global(qos:.utility).async {
            self.getStationDataFromFileWithSnapshotId(snapshotId: self.snapshotId)
        }
    }
    
    func didGetBuoyData() {
        delegate?.didFinishBuoyTask(sender: self, buoys: buoyArray)
    }
    
    //
    //MARK: - main data request
    //
    
    
    private func buoyDataServiceRequest(){
        
        var bouyDictionary : [Int : [String]] = [Int: [String]]()

        var dataString = String()
        guard let url = URL(string: urlString) else {return}

        do {
            dataString = try String(contentsOf: url)
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
                currentSnapShot.swellDirection = Int32(currentWaveDirectionDegrees)
//                currentSnapShot.swellDirectionString = directionFromDegrees(degrees: currentWaveDirectionDegrees)
        }
        //wave frequency/period
        if let waveAveragePeriod = Double(bouy[10]) as Double?{
            currentSnapShot.period = waveAveragePeriod
        }
        //water temp
        if let currentWaterTemp = Double(bouy[14]) as Double?{
                let currentWaterTempInFahrenheit = fahrenheitFromCelcius(temp: currentWaterTemp)
                currentSnapShot.waterTemp = currentWaterTempInFahrenheit
        }
        
        currentSnapShot.beachFaceDirection = Int32(currentStation.bfd)
        currentSnapShot.id = Int32(currentStation.id)
        currentSnapShot.stationId = Int32(currentStation.station)
        
//            currentSnapShot.nickname = name

        
        print(currentSnapShot)
        self.snapshot = currentSnapShot
        DispatchQueue.main.async {
            self.didGetBuoyData()
        }
    }
    
    func setUrlStringFromSnapshotId(){
        //after getStationDataFromFileWithSnapshotId
        //we have currentStation populated
        //use the station Id to retrieve data
        
        urlString = "http://www.ndbc.noaa.gov/data/realtime2/\(currentStation.station).txt"
        buoyDataServiceRequest()
    }
    

}

extension BuoyClient {
    
    //
    //MARK: - helpers to convert data
    //
    
    
    func fahrenheitFromCelcius(temp : Double) -> (Double){
        let tempInF = (9.0 / 5.0 * (temp)) + 32.0
        return (tempInF)
    }
    
    func directionFromDegrees(degrees : Float) -> String {
        
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let categoryInt: Int = Int((degrees + 11.25)/22.5)
        return directions[categoryInt % 16]
    }
}

extension BuoyClient {
    
    //
    //MARK: - station list handling
    //
    
    func getStationDataFromFileWithSnapshotId(snapshotId : Int){
        let fileName = "regionalBuoyList"
        guard let stations = loadJson(fileName) else {return}
        for station in stations where station.id == self.snapshotId {
            currentStation = station
            self.setUrlStringFromSnapshotId()
        }
    }

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

}





