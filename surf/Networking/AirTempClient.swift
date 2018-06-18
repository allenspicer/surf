//
//  TideClient.swift
//  surf
//
//  Created by uBack on 6/4/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit


protocol AirTempDelegate: AnyObject {
    func didFinishAirTempTask(sender: AirTempClient, airTemps: [AirTemp])
}

final class AirTempClient: NSObject {
    
    var delegate : AirTempDelegate?
    var dataArray = [[String: Any]]()
    var airTempArray = [AirTemp]()
    var currentSnapshot : Snapshot?
    
    init(currentSnapshot:Snapshot) {
        self.currentSnapshot = currentSnapshot
    }

    func createAirTempData() {
        DispatchQueue.global(qos:.utility).async {
            self.airTempDataServiceRequest()
        }
    }
    
    func didGetAirTempData() {
        delegate?.didFinishAirTempTask(sender: self, airTemps: airTempArray)
    }

    
    private func airTempDataServiceRequest(){
        
        let currentDateString = formattedCurrentDateString()
        let hoursNeeded = 24
        let stationId = "8658163"
        
        let filePathString = "https://tidesandcurrents.noaa.gov/api/datagetter?begin_date=\(currentDateString)&range=\(hoursNeeded)&station=\(stationId)&product=air_temperature&datum=msl&units=english&interval=h&time_zone=gmt&application=web_services&format=json"
        
        guard let url = URL(string: filePathString) else { return }
        
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (theData, theResponse, theError) in
            do {
                
                guard let theData = theData else { return }
                print("tidesandcurrents.noaa.gov URL Request Succeeded")
            
                if let json = try JSONSerialization.jsonObject(with: theData, options: []) as? [String : Any]{
                    print("AirTemp Client JSON Available")
                    
                    guard let arrayOfDataObjects = json["data"] else { return }
                    guard let dataArray = arrayOfDataObjects as? [[String: Any]] else { return }
                    print("AirTemp Client Array of Tide Values Available with \(dataArray.count) Objects")
                    self.dataArray = dataArray
                    self.createArrayOfAirTempDataObjects()
                }
            }catch let jsonError {
                print("AirTemp Client Data Request Failed With Error:\(jsonError)")
            }
        })
        task.resume()
        
    }
    
    
    private func createArrayOfAirTempDataObjects(){
            for dataObject in dataArray {
                guard let timeStamp = dataObject["t"] as? String else { return }
                guard let speedString = dataObject["v"] as? String else { return }
                guard let speed = Double(speedString) else { return }
                let airTemp = AirTemp.init(timeStamp: timeStamp, value: speed)
                airTempArray.append(airTemp)

            }
            print("AirTemp Array Created with \(airTempArray.count) Wind Objects")
            if self.airTempArray.count > 0 {
                DispatchQueue.main.async {
                self.didGetAirTempData()
                }
            }
    }
    
    ////
    //// Helpers
    ////
    
    private func formattedCurrentDateString () -> String {
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


}


