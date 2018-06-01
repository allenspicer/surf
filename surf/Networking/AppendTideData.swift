//
//  AppendTideData.swift
//  surf
//
//  Created by uBack on 6/1/18.
//  Copyright © 2018 surf. All rights reserved.
//

import Foundation


func test (_ snapshotWithoutTide : Snapshot, tideArray : [Tide])-> Snapshot{
    
    var snapshot = snapshotWithoutTide
    var nextTideIndex = Int()
    let currentTimestamp = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
    
    for index in 0..<tideArray.count {
        if let tideTimeStamp = dateFormatter.date(from: tideArray[index].timeStamp){
            if tideTimeStamp > currentTimestamp {
                nextTideIndex = index
                break
            }
        }
        
        if let tide = tideArray[nextTideIndex] as? Tide{
            snapshot.upcomingTidePolar = tide.key
            snapshot.upcomingTideTimestamp = dateFormatter.date(from: tideArray[nextTideIndex].timeStamp)
            snapshot.currentTideDirection = (tide.key == "H" ? "Rising" : "Dropping")
        }
    }
    
    return snapshot
}
