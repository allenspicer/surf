//
//  TideClient.swift
//  surf
//
//  Created by Allen Spicer on 6/4/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit


protocol TideClientDelegate: AnyObject {
    func didFinishTideTask(sender: TideClient, tides: [Tide], snapshot : Snapshot)
}

final class TideClient: NSObject {
    
    var delegate : TideClientDelegate?
    var dataArray = [[String: Any]]()
    var tideArray = [Tide]()
    var currentSnapshot : Snapshot
    
    init(currentSnapshot:Snapshot) {
        self.currentSnapshot = currentSnapshot
    }
    
    func createTideData() {
        DispatchQueue.global(qos:.utility).async {
            self.tideDataServiceRequest()
        }
    }
    
    func didGetTideData() {
        delegate?.didFinishTideTask(sender: self, tides: tideArray, snapshot: currentSnapshot)
    }
    
    
    private func tideDataServiceRequest(){
        
        let currentDateString = formattedCurrentDateString()
        let hoursNeeded = 36
        let stationId = "\(currentSnapshot.airWindTideId)"
        
        let filePathString = "https://tidesandcurrents.noaa.gov/api/datagetter?begin_date=\(currentDateString)&range=\(hoursNeeded)&station=\(stationId)&product=predictions&datum=msl&units=english&interval=hilo&time_zone=lst_ldt&application=web_services&format=json"
        
        guard let url = URL(string: filePathString) else { return }
        
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (theData, theResponse, theError) in
            do {
                
                guard let theData = theData else { return }
                print("tidesandcurrents.noaa.gov URL Request Succeeded for Tide")
                
                if let json = try JSONSerialization.jsonObject(with: theData, options: []) as? [String : Any]{
                    guard let arrayOfDataObjects = json["predictions"] else { return }
                    guard let dataArray = arrayOfDataObjects as? [[String: Any]] else { return }
                    self.dataArray = dataArray
                    self.createArrayOfTideDataObjects()
                }
            }catch let jsonError {
                print("Tide Client Data Request Failed With Error:\(jsonError)")
            }
        })
        task.resume()
        
    }
    
    
    private func createArrayOfTideDataObjects(){
        for dataObject in dataArray {
            guard let valueString = dataObject["v"] as? String else { return }
            guard let value = Double(valueString) else { return }
            guard let key = dataObject["type"] as? String else { return }
            guard let timeStampString = dataObject["t"] as? String else { return }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            dateFormatter.timeZone = TimeZone(abbreviation: "EST")
            guard let timeStamp = dateFormatter.date(from: timeStampString) else { return }
            let tide = Tide.init(timeStamp: timeStamp, value: value, key: key)
            tideArray.append(tide)
        }
        print("Tide Array Created with \(tideArray.count) Tide Objects")
        if self.tideArray.count > 0 {
            DispatchQueue.main.async {
                self.didGetTideData()
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
    
    func addTideDataToSnapshot(_ snapshotWithoutTide : Snapshot, tideArray : [Tide])-> Snapshot {
        var snapshot = snapshotWithoutTide
        let currentTimestamp = Date()
        let upcomingTides = tideArray.filter({$0.timeStamp > currentTimestamp})
        
        //tides are in order from API 
        //Take the lowest date stamp greater than current and add it plus the next tide based on their H/L key
        if (upcomingTides[0].key == "H"){
            snapshot.nextHighTide = upcomingTides[0].timeStamp
            if upcomingTides.indices.contains(1){
                snapshot.nextLowTide = upcomingTides[1].timeStamp
            }
        }else{
            snapshot.nextLowTide = upcomingTides[0].timeStamp
            if upcomingTides.indices.contains(1){
                snapshot.nextHighTide = upcomingTides[1].timeStamp
            }
        }
        return snapshot
    }
    
}

