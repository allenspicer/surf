//
//  BuoyClient.swift
//  surfbreak
//
//  Created by Allen Spicer on 7/26/18.
//  Copyright © 2018 surfbreak. All rights reserved.
//

import UIKit


protocol BuoyClientDelegate: AnyObject {
    func didFinishBuoyTask(sender: BuoyClient, buoys: [Buoy])
}

final class BuoyClient: NSObject {
    
    var delegate : BuoyClientDelegate?
    var dataArray = [[String: Any]]()
    var buoyArray = [Buoy]()
    var snapshotId = Int()
    var stationId = String()
    
    init(snapshotId:Int) {
        self.snapshotId = snapshotId
    }
    
    func createBuoyData() {
        DispatchQueue.global(qos:.utility).async {
            self.buoyDataServiceRequest()
        }
    }
    
    func didGetBuoyData() {
        delegate?.didFinishBuoyTask(sender: self, buoys: buoyArray)
    }
    
    
    private func buoyDataServiceRequest(){
        
            var dataString = String()
            do {
                dataString = try String(contentsOf: URL(string: "http://www.ndbc.noaa.gov/data/realtime2/\(self.stationId).txt")!)
            }catch{
                print("Bouy Data Retreival Error: \(error)")
            }

    }
    
    func getBuoyDataAsSnapshot()-> Snapshot {
        return Snapshot()
    }


}
