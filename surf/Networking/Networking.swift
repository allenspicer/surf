//
//  Networking.swift
//  surf
//
//  Created by Allen Spicer on 5/11/18.
//  Copyright © 2018 surf. All rights reserved.
//

import Foundation

func bouyDataServiceRequest (_ stationId: String) -> String{
    
    var dataString = String()
    do {
        dataString = try String(contentsOf: URL(string: "http://www.ndbc.noaa.gov/data/realtime2/\(stationId).txt")!)
    }catch{
        print("Bouy Data Retreival Error: \(error)")
    }
    return dataString
}



