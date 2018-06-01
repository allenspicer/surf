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


func tideDataServiceRequest(completion: @escaping ([[String: Any]]?) -> ()){
    
    var dataArray = [[String: Any]]()

    let currentDateString = formattedCurrentDateString()
    let hoursNeeded = 24
    let stationId = "8658163"
    
    let filePathString = "https://tidesandcurrents.noaa.gov/api/datagetter?begin_date=\(currentDateString)&range=\(hoursNeeded)&station=\(stationId)&product=predictions&datum=msl&units=english&interval=hilo&time_zone=gmt&application=web_services&format=json"

    
    guard let url = URL(string: filePathString) else { return }
    URLSession.shared.dataTask(with: url) { (data, response, error) in
        if error != nil {
            print(error!.localizedDescription)
        }
        guard let data = data else { return }
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let dictionary = json as? [String: Any] {

                if let arrayOfDataObjects = dictionary["predictions"] as? [[String: Any]] {
                    dataArray = arrayOfDataObjects
                }
            }
        completion(dataArray)

        } catch let jsonError {
            print(jsonError)
        }
    }.resume()
}

