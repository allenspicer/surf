//
//  TideClient.swift
//  surf
//
//  Created by Allen Spicer on 6/4/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit


protocol WindClientDelegate: AnyObject {
    func didFinishWindTask(sender: WindClient, winds: [Wind], snapshot: Snapshot)
}

final class WindClient: NSObject {
    
    var delegate : WindClientDelegate?
    var dataArray = [[String: Any]]()
    var windArray = [Wind]()
    var currentSnapshot : Snapshot
    
    init(currentSnapshot:Snapshot) {
        self.currentSnapshot = currentSnapshot
    }
    
    func createWindData() {
        DispatchQueue.global(qos:.utility).async {
            self.windDataServiceRequest()
        }
    }
    
    func didGetWindData() {
        delegate?.didFinishWindTask(sender: self, winds: windArray, snapshot : currentSnapshot)
    }
    
    
    private func windDataServiceRequest(){
        
        let currentDateString = formattedCurrentDateString()
        let hoursNeeded = 2
        let stationId = "\(currentSnapshot.airWindTideId)"
        
        let filePathString = "https://tidesandcurrents.noaa.gov/api/datagetter?begin_date=\(currentDateString)&range=\(hoursNeeded)&station=\(stationId)&product=wind&datum=msl&units=english&interval=h&time_zone=gmt&application=web_services&format=json"
        
        guard let url = URL(string: filePathString) else { return }
        
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (theData, theResponse, theError) in
            do {
                
                guard let theData = theData else { return }
                print("tidesandcurrents.noaa.gov URL Request Succeeded")
                
                if let json = try JSONSerialization.jsonObject(with: theData, options: []) as? [String : Any]{
                    print("Wind Client JSON Available")
                    
                    guard let arrayOfDataObjects = json["data"] else { return }
                    guard let dataArray = arrayOfDataObjects as? [[String: Any]] else { return }
                    print("Wind Client Array of Tide Values Available with \(dataArray.count) Objects")
                    self.dataArray = dataArray
                    self.createArrayOfWindDataObjects()
                }
            }catch let jsonError {
                print("Wind Client Data Request Failed With Error:\(jsonError)")
            }
        })
        task.resume()
        
    }
    
    
    private func createArrayOfWindDataObjects(){
        for dataObject in dataArray {
            guard let timeStamp = dataObject["t"] as? String else { return }
            guard let speedString = dataObject["s"] as? String else { return }
            guard let speed = Double(speedString) else { return }
            guard let directionString = dataObject["d"] as? String else { return }
            guard let direction = Double(directionString) else { return }
            guard let cardinalDirection = dataObject["dr"] as? String else { return }
            
            let wind = Wind.init(timeStamp: timeStamp, speed: speed, direction: direction, windDirectionString: cardinalDirection)
            windArray.append(wind)
        }
        print("Wind Array Created with \(windArray.count) Wind Objects")
        if self.windArray.count > 0 {
            DispatchQueue.main.async {
                self.didGetWindData()
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
    
    
    func addWindDataToSnapshot(_ snapshotWithoutWind : Snapshot, windArray : [Wind])-> Snapshot {
        
        var snapshot = snapshotWithoutWind
        var nextWindIndex = Int()
        let currentTimestamp = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        for index in 0..<windArray.count {
            if let windTimeStamp = dateFormatter.date(from: windArray[index].timeStamp){
                if windTimeStamp > currentTimestamp {
                    nextWindIndex = index
                    break
                }
            }
        }
        
        let wind = windArray[nextWindIndex]
        snapshot.windDirectionString = wind.windDirectionString
        snapshot.windSpeed = Int(wind.speed)
        snapshot.windCardinalDirection = Int(wind.direction)
        
        return snapshot
    }
}


