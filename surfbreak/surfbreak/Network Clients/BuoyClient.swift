//
//  BuoyClient.swift
//  surfbreak
//
//  Created by Allen Spicer on 7/26/18.
//  Copyright © 2018 surfbreak. All rights reserved.
//

import UIKit


protocol BuoyClientDelegate: AnyObject {
    func didFinishBuoyTask(sender: BuoyClient, snapshot : Snapshot, stations : [Station])
}

final class BuoyClient: NSObject {
    
    var delegate : BuoyClientDelegate?
    var currentSnapshot = Snapshot()
    var snapshotId = Int()
    var urlString = String()
    var currentStation = Station()
    var allStations = [Station]()
    
    
    init(snapshotId:Int, allStations: [Station]) {
        self.snapshotId = snapshotId
        self.allStations = allStations
    }
    
    func createBuoyData() {
        DispatchQueue.global(qos:.utility).async {
            self.setUrlStringFromSnapshotId()
        }
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
            DispatchQueue.main.async {
                self.delegate?.didFinishBuoyTask(sender: self, snapshot: self.currentSnapshot, stations: self.allStations)
            }
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
        guard let bouy = bouyDictionary[index] else {return}
        
        //wave height
        guard let currentWaveHeight = Double(bouy[8]) as Double? else {return}
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        var heightInFeet = currentWaveHeight * 3.28
        heightInFeet = (heightInFeet*10).rounded()/10

        //wave direction
        guard let currentWaveDirectionDegrees = Int(bouy[11]) as Int? else {return}

        //wave frequency/period
        guard let waveAveragePeriod = Double(bouy[10]) as Double? else {return}

        //water temp
        guard let currentWaterTemp = Double(bouy[14]) as Double? else {return}
        var currentWaterTempInFahrenheit = fahrenheitFromCelcius(temp: currentWaterTemp)
        currentWaterTempInFahrenheit = (currentWaterTempInFahrenheit*10).rounded()/10

        
       currentSnapshot.waveHeight = heightInFeet
       currentSnapshot.swellDirection = currentWaveDirectionDegrees
//       currentSnapshot.swellDirectionString = directionFromDegrees(degrees: currentWaveDirectionDegrees)
       currentSnapshot.period = waveAveragePeriod
       currentSnapshot.waterTemp = currentWaterTempInFahrenheit
       currentSnapshot.beachFaceDirection = currentStation.bfd
       currentSnapshot.id = currentStation.id
       currentSnapshot.stationId = currentStation.station
        currentSnapshot.stationName = currentStation.name
        currentSnapshot.airWindTideId = currentStation.airWindTideId
        currentSnapshot.windDirectionString = directionFromDegrees(degrees: Float(currentSnapshot.windCardinalDirection))
        
//            currentSnapShot.nickname = name

        DispatchQueue.main.async {
            self.delegate?.didFinishBuoyTask(sender: self, snapshot: self.currentSnapshot, stations: self.allStations)
        }
    }
    
    func setUrlStringFromSnapshotId(){
        //after getStationDataFromFileWithSnapshotId
        //we have currentStation populated
        //use the station Id to retrieve data
        
        for station in allStations where station.id == self.snapshotId {
            currentStation = station
            urlString = "http://www.ndbc.noaa.gov/data/realtime2/\(currentStation.station).txt"
            buoyDataServiceRequest()
        }
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
    
    
    func appendDistanceToUserWith(userLocation : UserLocation){
        // Used to convert latitude and longitude into miles
        // both numbers are approximate. One longitude at 40 degrees is about 53 miles however the true
        // number of miles is up to 69 at the equator and down to zero at the poles
        let approxMilesToLon = 53.0
        let approxMilesToLat = 69.0
        let lon = userLocation.longitude
        let lat = userLocation.latitude
        let lonDiffAbs = abs(currentStation.longitude - lon) * approxMilesToLon
        let latDiffAbs = abs(currentStation.latitude - lat) * approxMilesToLat
        currentSnapshot.distance = Int((pow(lonDiffAbs, 2) + pow(latDiffAbs, 2)).squareRoot())
    }
}





