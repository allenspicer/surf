//
//  Networking.swift
//  surf
//
//  Created by Allen Spicer on 5/11/18.
//  Copyright © 2018 surf. All rights reserved.
//

import Foundation

final class NetworkRequest: NSObject {

    let stationId : String
    
    init(stationId:String){
        self.stationId = stationId
        }
    
    func bouyDataServiceRequest() -> String{
        var dataString = String()
        do {
            dataString = try String(contentsOf: URL(string: "http://www.ndbc.noaa.gov/data/realtime2/\(self.stationId).txt")!)
        }catch{
            print("Bouy Data Retreival Error: \(error)")
        }
        return dataString
    }
    
    
}








