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
    var waterTemp: Double?
    var DEWP: String?
    var VIS: String?
    var tide: String?
    var timeStamp: Date = Date()

}


