//
//  Parsing.swift
//  surf
//
//  Created by Allen Spicer on 5/11/18.
//  Copyright © 2018 surf. All rights reserved.
//

import Foundation
import UIKit

func createSnapshot(stationId: String, finished: () -> Void) -> (Snapshot){
    
    var snapshotArray = [Snapshot]()
    var bouyDictionary : [Int : [String]] = [Int: [String]]()
    let list = bouyDataServiceRequest(stationId)
    
    let lines = list.components(separatedBy: "\n")
    var rawStatArray : [String] = []
    
    for (index, line) in lines.enumerated(){
        if (index < 10 && index > 1){
            rawStatArray = line.components(separatedBy: " ")
            rawStatArray = rawStatArray.filter { $0 != "" }
            bouyDictionary[index] = rawStatArray
        }
    }
    
    guard bouyDictionary.count > 2 else {return Snapshot()}
    
    for index in 2..<bouyDictionary.count {
        var currentSnapShot = Snapshot.init()
        guard let bouy = bouyDictionary[index] else {return (currentSnapShot)}
        
        //wave height
        if let currentWaveHeight = Double(bouy[8]) as Double?{
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 1
            let heightInFeet = currentWaveHeight * 3.28
            if let heightWithPlaces = formatter.string(from: heightInFeet as NSNumber){
                currentSnapShot.waveHgt = Double(heightWithPlaces)
            }
        }
        //wave direction
        if let currentWaveDirectionDegrees = Float(bouy[11]) as Float?{
            currentSnapShot.meanWaveDirection = windDirectionFromDegrees(degrees: currentWaveDirectionDegrees)
        }
        //wind direction
        if let currentWindDirectionDegrees = Float(bouy[5]) as Float?{
            currentSnapShot.windDir = windDirectionFromDegrees(degrees: currentWindDirectionDegrees)
        }
        //wind speed
        if let currentWindSpeed = Int(bouy[6]) as Int?{
            currentSnapShot.windSpd = String(currentWindSpeed)
        }
        //water temp
        if let currentWaterTemp = Double(bouy[14]) as Double?{
            let currentWaterTempInFahrenheit = fahrenheitFromCelcius(temp: currentWaterTemp)
            currentSnapShot.waterTemp = currentWaterTempInFahrenheit
        }
        snapshotArray.append(currentSnapShot)
    }
    
    finished()
    return (snapshotArray.first ?? Snapshot.init())
}

func createTideDataArray() -> [Tide]{
    var tideArray = [Tide]()
    tideDataServiceRequest { (dataArray) -> () in
        
        guard let arrayOfTideData = dataArray else { return }
        for dataObject in arrayOfTideData {
            guard let valueString = dataObject["v"] as? String else { return }
            guard let value = Double(valueString) else { return }
            guard let key = dataObject["type"] as? String else { return }
            guard let timeStamp = dataObject["t"] as? String else { return }
            let tide = Tide.init(timeStamp: timeStamp, value: value, key: key)
            tideArray.append(tide)
        }
    }
    return tideArray
}





