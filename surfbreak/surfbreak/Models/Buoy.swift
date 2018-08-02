//
//  Buoy.swift
//  surfbreak
//
//  Created by Allen Spicer on 7/26/18.
//  Copyright © 2018 surfbreak. All rights reserved.
//

import Foundation
import UIKit

struct Buoy {
    
    var waveHeight : Double
    var swellDirection : Int
    var period : Double
    var waterTemp : Double
    var beachFaceDirection : Int
    var id : Int
    var stationId : Int
    
    init(waveHeight : Double = 0.0, swellDirection : Int = 0, period : Double = 0.0, waterTemp : Double = 0.0, beachFaceDirection : Int = 0, id : Int = 0, stationId : Int = 0) {
        self.waveHeight = waveHeight
        self.swellDirection = swellDirection
        self.period = period
        self.waterTemp = waterTemp
        self.beachFaceDirection = beachFaceDirection
        self.id = id
        self.stationId = stationId
    }
}
