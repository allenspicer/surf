//
//  Parsing.swift
//  surf
//
//  Created by Allen Spicer on 5/11/18.
//  Copyright © 2018 surf. All rights reserved.
//

import Foundation
import UIKit

func createSnapshot(stationId: String, beachFaceDirection : Double, finished: () -> Void) -> (Snapshot){
    
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
            currentSnapShot.waveDirection = Double(currentWaveDirectionDegrees)
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
//                currentSnapShot.backgroundColor = colorComplement(color: waterColor)
            }
        }
        
        //station id
        if let station = Int(stationId){
            currentSnapShot.stationId = station
        }
        
        //beach face direction
        currentSnapShot.beachFaceDirection = beachFaceDirection
        
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
        snapshot.windDirectionString = wind.windDirectionString
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


func directionFromDegrees(degrees : Float) -> String {
    
    let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
    let i: Int = Int((degrees + 11.25)/22.5)
    return directions[i % 16]
}


func fahrenheitFromCelcius(temp : Double) -> (Double){
    let tempInF = (9.0 / 5.0 * (temp)) + 32.0
    return (tempInF)
}

func getWaterColorFromTempInF(_ temp: Double) -> CGColor?{
    var color : CGColor? = nil
    var tempIndex = Int()
    
    switch temp {
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
    
    let colorArray = [#colorLiteral(red: 0.4, green: 0.3450980392, blue: 0.8549019608, alpha: 1), #colorLiteral(red: 0.2941176471, green: 0.6078431373, blue: 0.8274509804, alpha: 1), #colorLiteral(red: 0.2705882353, green: 0.8705882353, blue: 0.4745098039, alpha: 1), #colorLiteral(red: 1, green: 0.7019607843, blue: 0.3137254902, alpha: 1)]
    color = colorArray[tempIndex].cgColor
    
    return color
}

//invert color components for complementary title color
func colorComplement(color: CGColor) -> UIColor{
    
    let colorArray = [#colorLiteral(red: 0.4, green: 0.3450980392, blue: 0.8549019608, alpha: 1), #colorLiteral(red: 0.2941176471, green: 0.6078431373, blue: 0.8274509804, alpha: 1), #colorLiteral(red: 0.2705882353, green: 0.8705882353, blue: 0.4745098039, alpha: 1), #colorLiteral(red: 1, green: 0.7019607843, blue: 0.3137254902, alpha: 1)]
    var returnIndex = 0
    
    for index in 0..<colorArray.count{
        if color == colorArray[index].cgColor {
            let halfCount = colorArray.count / 2
            if index + halfCount >= colorArray.count {
                returnIndex = index + halfCount - 4
            }else{
                returnIndex = index + halfCount
            }
        }
    }
    return colorArray[returnIndex]
}



