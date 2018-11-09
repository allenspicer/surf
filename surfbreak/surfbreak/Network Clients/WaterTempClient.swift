//
//  BuoyClient.swift
//  surfbreak
//
//  Created by Allen Spicer on 7/26/18.
//  Copyright © 2018 surfbreak. All rights reserved.
//

import UIKit


protocol WaterTempClientDelegate: AnyObject {
    func didFinishBuoyTask(sender: WaterTempClient, snapshot : Snapshot, stations : [Station])
}

final class WaterTempClient: NSObject {
    
    var delegate : WaterTempClientDelegate?
    var currentSnapshot = Snapshot()
    var snapshotId = Int()
    var currentStation = Station()
    var allStations = [Station]()
    
    
    init(snapshotId:Int, allStations: [Station]) {
        self.snapshotId = snapshotId
        self.allStations = allStations
    }
    
    func createBuoyData() {
        DispatchQueue.global(qos:.utility).async {
            self.setUrlStringFromSnapshotId()
        }
    }
    
    //
    //MARK: - main data request
    //
    
    
    private func waterTempDataServiceRequestWith(waterTempurl : URL){
        
        var waterTempDataString = String()
        do {
            waterTempDataString = try String(contentsOf: waterTempurl)
        }catch{
            print("Water Temp Data Retreival Error: \(error)")
            DispatchQueue.main.async {
                self.delegate?.didFinishBuoyTask(sender: self, snapshot: self.currentSnapshot, stations: self.allStations)
            }
        }
        
        let waterTempLines = waterTempDataString.components(separatedBy: "\n")
        let waterTempValues = waterTempLines[1].components(separatedBy: ",")

        //water temp
        guard let currentWaterTemp = Double(waterTempValues[6]) as Double? else {return}
        var currentWaterTempInFahrenheit = fahrenheitFromCelcius(temp: currentWaterTemp)
        currentWaterTempInFahrenheit = (currentWaterTempInFahrenheit*10).rounded()/10

        currentSnapshot.waterTemp = currentWaterTempInFahrenheit

        DispatchQueue.main.async {
            self.delegate?.didFinishBuoyTask(sender: self, snapshot: self.currentSnapshot, stations: self.allStations)
        }
    }
    
    func setUrlStringFromSnapshotId(){
        //after getStationDataFromFileWithSnapshotId
        //we have currentStation populated
        //use the station Id to retrieve data
        
        for station in allStations where station.id == self.snapshotId {
            currentStation = station
            
            let waterTempurlString = "https://sdf.ndbc.noaa.gov/sos/server.php?request=GetObservation&service=SOS&version=1.0.0&offering=urn:ioos:station:wmo:\(currentStation.station)&observedproperty=sea_water_temperature&responseformat=text/csv&eventtime=latest"
            guard let waterTempurl = URL(string: waterTempurlString) else {return}
            
            waterTempDataServiceRequestWith(waterTempurl: waterTempurl)
        }
    }
}

extension WaterTempClient {
    
    //
    //MARK: - helpers to convert data
    //
    
    
    func fahrenheitFromCelcius(temp : Double) -> (Double){
        let tempInF = (9.0 / 5.0 * (temp)) + 32.0
        return (tempInF)
    }
}





