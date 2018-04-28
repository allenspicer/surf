//
//  Snapshot.swift
//  surf
//
//  Created by uBack on 3/12/18.
//  Copyright © 2018 surf. All rights reserved.
//

import Foundation
import UIKit

struct Snapshot {
    var id: String = ""
    var year: String = ""
    var month: String = ""
    var day: String = ""
    var hour: String = ""
    var minute: String = ""
    var windDir: String?
    var windSpd: String?
    var gusts: String?
    var waveHgt: String?
    var dominantWavePeriod: String?
    var waveAveragePeriod: String?
    var meanWaveDirection: String?
    var PRES: String?
    var PTDY: String?
    var airTemp: String?
    var waterTemp: String?
    var DEWP: String?
    var VIS: String?
    var tide: String?
    var timeStamp: Date = Date()

}

func bouyDataServiceRequest(finished: () -> Void) -> (Snapshot, CGColor){
    
    var snapshotArray = [Snapshot]()
    var bouyDictionary : [Int : [String]] = [Int: [String]]()
    var waterColor: CGColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    
    // 41110 Masenboro Inlet ILM2
    // 41038 Wrightsville Beach Nearshore ILM2
    // JMPN7 Johnny Mercer Pier
    
    do {
        
        let list = try String(contentsOf: URL(string: "http://www.ndbc.noaa.gov/data/realtime2/41110.txt")!)
        let lines = list.components(separatedBy: "\n")
        var rawStatArray : [String] = []
        
        
        for (index, line) in lines.enumerated(){
            if (index < 10 && index > 1){
                rawStatArray = line.components(separatedBy: " ")
                rawStatArray = rawStatArray.filter { $0 != "" }
                bouyDictionary[index] = rawStatArray
            }
        }
        
        for index in 2..<bouyDictionary.count {
            var currentSnapShot = Snapshot.init()
            guard let bouy = bouyDictionary[index] else {return (currentSnapShot , waterColor)}
            
            //wave height
            if let currentWaveHeight = Double(bouy[8]) as Double?{
                let formatter = NumberFormatter()
                formatter.maximumFractionDigits = 1
                let heightInFeet = currentWaveHeight * 3.28
                currentSnapShot.waveHgt = formatter.string(from: heightInFeet as NSNumber)
                
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
                let tuple = fahrenheitFromCelcius(temp: currentWaterTemp)
                currentSnapShot.waterTemp = String(tuple.0)
                waterColor = tuple.1
            }
            snapshotArray.append(currentSnapShot)
        }
        
    }catch{
        print("Bouy Data Retreival Error: \(error)")
    }
    
    finished()
    return (snapshotArray.first ?? Snapshot.init(), waterColor)
}

func windDirectionFromDegrees(degrees : Float) -> String {
    
    let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
    let i: Int = Int((degrees + 11.25)/22.5)
    return directions[i % 16]
}


func fahrenheitFromCelcius(temp : Double) -> (Double, CGColor){
    
    let colorArray = [#colorLiteral(red: 0.4, green: 0.3450980392, blue: 0.8549019608, alpha: 1), #colorLiteral(red: 0.2941176471, green: 0.6078431373, blue: 0.8274509804, alpha: 1), #colorLiteral(red: 0.2705882353, green: 0.8705882353, blue: 0.4745098039, alpha: 1), #colorLiteral(red: 1, green: 0.7019607843, blue: 0.3137254902, alpha: 1)]
    let tempInF = (9.0 / 5.0 * (temp)) + 32.0
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

    return (tempInF, colorArray[tempIndex].cgColor)
}



