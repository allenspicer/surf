//
//  Parsing.swift
//  surf
//
//  Created by uBack on 5/11/18.
//  Copyright © 2018 surf. All rights reserved.
//

import Foundation
import UIKit

func bouyDataServiceRequest(finished: () -> Void) -> (Snapshot, CGColor){
    
    var snapshotArray = [Snapshot]()
    var bouyDictionary : [Int : [String]] = [Int: [String]]()
    var waterColor: CGColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    
    // 41110 Masenboro Inlet ILM2
    // 41038 Wrightsville Beach Nearshore ILM2
    // JMPN7 Johnny Mercer Pier
    
    
    let list = getBouyData(41110)
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
            let currentWaterTempInFahrenheit = fahrenheitFromCelcius(temp: currentWaterTemp)
            currentSnapShot.waterTemp = "\(currentWaterTempInFahrenheit)"
            waterColor = getWaterColorFromTempInF(currentWaterTempInFahrenheit)
        }
        snapshotArray.append(currentSnapShot)
    }
    
    finished()
    return (snapshotArray.first ?? Snapshot.init(), waterColor)
}

