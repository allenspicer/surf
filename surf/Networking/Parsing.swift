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
    let networkRequest = NetworkRequest(stationId: stationId)
    let list = networkRequest.bouyDataServiceRequest()
    
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
            currentSnapShot.meanWaveDirection = directionFromDegrees(degrees: currentWaveDirectionDegrees)
        }
        //wave frequency/period
        if let waveAveragePeriod = Double(bouy[10]) as Double?{
            currentSnapShot.waveAveragePeriod = waveAveragePeriod
        }
        //water temp
        if let currentWaterTemp = Double(bouy[14]) as Double?{
            let currentWaterTempInFahrenheit = fahrenheitFromCelcius(temp: currentWaterTemp)
            currentSnapShot.waterTemp = currentWaterTempInFahrenheit
            //set color of wave
            if let waterColor = getWaterColorFromTempInF(currentWaterTempInFahrenheit){
                currentSnapShot.waterColor = waterColor
                //set color of background
                currentSnapShot.backgroundColor = colorComplement(color: waterColor)
            }
        }
        snapshotArray.append(currentSnapShot)
    }
    
    finished()
    return (snapshotArray.first ?? Snapshot.init())
}


func addTideDataToSnapshot(_ snapshotWithoutTide : Snapshot, tideArray : [Tide])-> Snapshot {
    
    var snapshot = snapshotWithoutTide
    var nextTideIndex = Int()
    let currentTimestamp = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
    
    //
    //turn this into function for all these to use
    for index in 0..<tideArray.count {
        if let tideTimeStamp = dateFormatter.date(from: tideArray[index].timeStamp){
            if tideTimeStamp > currentTimestamp {
                nextTideIndex = index
                break
            }
        }
    }
    //
    //
        
    if let tide = tideArray[nextTideIndex] as? Tide{
        snapshot.upcomingTidePolar = tide.key
        snapshot.upcomingTideTimestamp = dateFormatter.date(from: tideArray[nextTideIndex].timeStamp)
        snapshot.currentTideDirection = (tide.key == "H" ? "Rising" : "Dropping")
    }
    
    return snapshot
}

func addWindDataToSnapshot(_ snapshotWithoutWind : Snapshot, windArray : [Wind])-> Snapshot {
    
    var snapshot = snapshotWithoutWind
    var nextWindIndex = Int()
    let currentTimestamp = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
    
    for index in 0..<windArray.count {
        if let windTimeStamp = dateFormatter.date(from: windArray[index].timeStamp){
            if windTimeStamp > currentTimestamp {
                nextWindIndex = index
                break
            }
        }
    }
    
    if let wind = windArray[nextWindIndex] as? Wind{
        snapshot.windCardinalDirection = wind.cardinalDirection
        snapshot.windSpd = wind.speed
        snapshot.windDir = wind.direction
    }
    
    return snapshot
}

func addAirTempDataToSnapshot(_ snapshotWithoutAirTemp : Snapshot, AirTempArray : [AirTemp])-> Snapshot {
    
    var snapshot = snapshotWithoutAirTemp
    var nextAirTempIndex = Int()
    let currentTimestamp = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
    
    for index in 0..<AirTempArray.count {
        if let AirTempTimeStamp = dateFormatter.date(from: AirTempArray[index].timeStamp){
            if AirTempTimeStamp > currentTimestamp {
                nextAirTempIndex = index
                break
            }
        }
    }
    
    if let airTemp = AirTempArray[nextAirTempIndex] as? AirTemp{
        snapshot.airTemp = airTemp.value
    }
    
    return snapshot
}



