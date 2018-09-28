//
//  FallBackData.swift
//  surfbreak
//
//  Created by Allen Spicer on 8/9/18.
//  Copyright © 2018 surfbreak. All rights reserved.
//

import UIKit
import Disk

final class FallBackData: NSObject {
    
    var allStations = [Station]()
    var fallbackSnapshots = [Snapshot]()

    init(allStations : [Station]) {
        super.init()
        self.allStations = allStations
        self.createData()
    }
    
    func createData(){
        
        let date = Date()
        let nextDate = Calendar.current.date(byAdding: .hour, value: 6, to: date) ?? date
        for station in allStations{
            let snapshot = Snapshot(waveHeight: 1.0, swellDirection: 264, period: 5.0, waterTemp: 70.0, beachFaceDirection: station.bfd, id: station.id, stationId: station.station, windSpeed: 10, windCardinalDirection: 264, windDirectionString: "W", swellDirectionString: "", nickname: station.name, stationName: station.name, airTemp: 80.0, nextTideTime: date, nextTidePolar: "H", tideDirectionString: "Rising", timeStamp: date, quality: 4, airWindTideId: 0, nextHighTide: date, nextLowTide: nextDate, distance: 10, isFallback: true)
            fallbackSnapshots.append(snapshot)
        }
        saveSnapshotsToPersistence()

    }
    
    func saveSnapshotsToPersistence(){
        DispatchQueue.global(qos:.utility).async{
            do {
                try Disk.save(self.fallbackSnapshots, to: .documents, as: DefaultConstants.fallBackSnapshots)
            }catch{
                print("Saving to automatic storage with Disk failed. Error is: \(error)")
            }
        }
    }
    
}
