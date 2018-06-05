//
//  Snapshot.swift
//  surf
//
//  Created by Allen Spicer on 3/12/18.
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
    var waveHgt: Double?
    var dominantWavePeriod: String?
    var waveAveragePeriod: Double?
    var meanWaveDirection: String?
    var PRES: String?
    var PTDY: String?
    var airTemp: String?
    var waterTemp: Double?
    var DEWP: String?
    var VIS: String?
    var upcomingTidePolar: String?
    var upcomingTideTimestamp: Date?
    var currentTideDirection: String?
    var timeStamp: Date = Date()
    var stationName : String?
    var stationId : Int?
    var waterColor : CGColor?
    
    
}


