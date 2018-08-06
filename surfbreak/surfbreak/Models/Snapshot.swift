//
//  Snapshot.swift
//  surfbreak
//
//  Created by Allen Spicer on 7/26/18.
//  Copyright © 2018 surfbreak. All rights reserved.
//

import Foundation
import UIKit

struct Snapshot : Codable{
    
    var waveHeight : Double
    var swellDirection : Int
    var period : Double
    var waterTemp : Double
    var beachFaceDirection : Int
    var id : Int
    var stationId : Int
    var windSpeed : Int
    var windCardinalDirection : Int
    var windDirectionString : String
    var swellDirectionString : String
    var nickname : String
    var stationName : String
    var airTemp : Double
    var nextTideTime : Date
    var nextTidePolar : String
    var tideDirectionString : String

    init(waveHeight : Double = 0.0,
         swellDirection : Int = 0,
         period : Double = 0.0,
         waterTemp : Double = 0.0,
         beachFaceDirection : Int = 0,
         id : Int = 0,
         stationId : Int = 0,
         windSpeed : Int = 0,
         windCardinalDirection : Int = 0,
         windDirectionString : String = "",
         swellDirectionString : String = "",
         nickname : String = "",
         stationName : String = "",
         airTemp : Double = 0.0,
         nextTideTime : Date = Date(),
         nextTidePolar : String = "",
         tideDirectionString : String = ""
        ) {
        self.waveHeight = waveHeight
        self.swellDirection = swellDirection
        self.period = period
        self.waterTemp = waterTemp
        self.beachFaceDirection = beachFaceDirection
        self.id = id
        self.stationId = stationId
        self.windSpeed = windSpeed
        self.windCardinalDirection = windCardinalDirection
        self.windDirectionString = windDirectionString
        self.swellDirectionString = swellDirectionString
        self.nickname = nickname
        self.stationName = stationName
        self.airTemp = airTemp
        self.nextTideTime = nextTideTime
        self.nextTidePolar = nextTidePolar
        self.tideDirectionString = tideDirectionString
    }
}
