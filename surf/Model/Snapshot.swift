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
    var timeStamp: Date = Date()
    var id: Int?
    var year: String = ""
    var month: String = ""
    var day: String = ""
    var hour: String = ""
    var minute: String = ""
    var waveHgt: Double?
    var dominantWavePeriod: String?
    var waveAveragePeriod: Double?
    var meanWaveDirection: String?
    var waveDirection: Double?
    var PRES: String?
    var PTDY: String?
    var airTemp: Double?
    var waterTemp: Double?
    var waterColor: CGColor?
    var backgroundColor: UIColor?
    var DEWP: String?
    var VIS: String?
    var upcomingTidePolar: String?
    var upcomingTideTimestamp: Date?
    var currentTideDirection: String?
    var stationName : String?
    var stationId : Int?
    var beachFaceDirection : Double?
    var windDir: Double?
    var windSpd: Double?
    var windDirectionString: String?
    var windCardinalDirection: String?
    var nickname : String?
}


