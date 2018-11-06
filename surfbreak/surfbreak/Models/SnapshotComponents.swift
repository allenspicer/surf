//
//  SnapshotComponents.swift
//  surfbreak
//
//  Created by Allen Spicer on 8/2/18.
//  Copyright © 2018 surfbreak. All rights reserved.
//

import Foundation
import UIKit

struct SnapshotComponents {
    var bouy : Bool
    var bouyTimeStamp: Date?
    var tide : Bool
    var tideTimeStamp: Date?
    var wind : Bool
    var windTimeStamp: Date?
    var air : Bool
    var airTimeStamp: Date?
    var quality : Bool
    var completeTimestamp: Date?
    var snapshot: Snapshot?
    
    
    init(bouy : Bool = false,
         bouyTimeStamp: Date? = nil,
         tide : Bool = false,
         tideTimeStamp: Date? = nil,
         wind : Bool = false,
         windTimeStamp: Date? = nil,
         air : Bool = false,
         airTimeStamp: Date? = nil,
         quality : Bool = false,
         completeTimestamp: Date? = nil,
         snapshot: Snapshot? = nil
        ) {
        self.bouy = bouy
        self.bouyTimeStamp = bouyTimeStamp
        self.tide = tide
        self.tideTimeStamp = tideTimeStamp
        self.wind = wind
        self.windTimeStamp = windTimeStamp
        self.air = air
        self.airTimeStamp = airTimeStamp
        self.quality = quality
        self.completeTimestamp = completeTimestamp
        self.snapshot = snapshot
    }
}
