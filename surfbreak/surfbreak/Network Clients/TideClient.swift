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
        let hoursNeeded = 24
        let stationId = "\(currentSnapshot.airWindTideId)"

        let filePathString = "https://tidesandcurrents.noaa.gov/api/datagetter?begin_date=\(currentDateString)&range=\(hoursNeeded)&station=\(stationId)&product=predictions&datum=msl&units=english&interval=hilo&time_zone=lst_ldt&application=web_services&format=json"
        
        guard let url = URL(string: filePathString) else { return }
        
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (theData, theResponse, theError) in
            do {
                
                guard let theData = theData else { return }
                print("tidesandcurrents.noaa.gov URL Request Succeeded")
                
                if let json = try JSONSerialization.jsonObject(with: theData, options: []) as? [String : Any]{
                    print("Tide Client JSON Available")
                    
                    guard let arrayOfDataObjects = json["predictions"] else { return }
                    guard let dataArray = arrayOfDataObjects as? [[String: Any]] else { return }
                    print("Tide Client Array of Tide Values Available with \(dataArray.count) Objects")
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
            guard let timeStamp = dataObject["t"] as? String else { return }
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
        var nextTideIndex = Int()
        let currentTimestamp = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        //
        //turn this into function for all these to use
        for index in 0..<tideArray.count {
            if let tideTimeStamp = dateFormatter.date(from: tideArray[index].timeStamp){
                if tideTimeStamp > currentTimestamp {
                    nextTideIndex = index
                    break
                }
            }
        }
        //
        //
        
        //        let tide = tideArray[nextTideIndex]
        //        snapshot.nextTidePolar = tide.key
        //        snapshot.nextTideTime = dateFormatter.date(from: tideArray[nextTideIndex].timeStamp)
        //        snapshot.tideDirectionString = (tide.key == "H" ? dateFormatter.date(from: tideArray[nextTideIndex].timeStamp) : dateFormatter.date(from: tideArray[nextTideIndex-1].timeStamp))
        
        guard let upcomingTideTimestamp =  dateFormatter.date(from: tideArray[nextTideIndex].timeStamp) else {return snapshot}
        if let previousTideTimestamp =  dateFormatter.date(from: tideArray[nextTideIndex-1].timeStamp){
            snapshot.nextHighTide = tideArray[nextTideIndex].key == "H" ? upcomingTideTimestamp : previousTideTimestamp
            snapshot.nextLowTide = tideArray[nextTideIndex].key == "L" ? upcomingTideTimestamp : previousTideTimestamp
        }else if let previousTideTimestamp =  dateFormatter.date(from: tideArray[nextTideIndex+1].timeStamp){
            snapshot.nextHighTide = tideArray[nextTideIndex].key == "H" ? upcomingTideTimestamp : previousTideTimestamp
            snapshot.nextLowTide = tideArray[nextTideIndex].key == "L" ? upcomingTideTimestamp : previousTideTimestamp
        }

        
        return snapshot
    }
    
    
}


