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

func formattedCurrentDateString () -> String {
    let currentDate = Date()
    let calendar = Calendar.current
    let year = calendar.component(.year, from: currentDate), month = calendar.component(.month, from: currentDate), day = calendar.component(.day, from: currentDate)
    
    var monthString = String()
    if month < 10 {
        monthString = "0\(month)"
    }else{
        monthString = "\(month)"
    }
    
    var dayString = String()
    if day < 10 {
        dayString = "0\(day)"
    }else{
        dayString = "\(day)"
    }
    
    return "\(year)\(monthString)\(dayString)"
}



