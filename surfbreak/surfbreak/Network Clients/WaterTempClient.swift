//
//  WaterTempClient.swift
//  surfbreak
//
//  Created by Allen Spicer on 7/26/18.
//  Copyright © 2018 surfbreak. All rights reserved.
//

import UIKit


protocol WaterTempClientDelegate: AnyObject {
    func didFinishWaterTempTask(sender: WaterTempClient, snapshot : Snapshot)
}

final class WaterTempClient: NSObject {
    
    var delegate : WaterTempClientDelegate?
    var currentSnapshot = Snapshot()
    var waterTemp = Double()
    
    init(currentSnapshot:Snapshot) {
        self.currentSnapshot = currentSnapshot
    }
    
    func createWaterTempData() {
        DispatchQueue.global(qos:.utility).async {
            let waterTempurlString = "https://sdf.ndbc.noaa.gov/sos/server.php?request=GetObservation&service=SOS&version=1.0.0&offering=urn:ioos:station:wmo:\(self.currentSnapshot.stationId)&observedproperty=sea_water_temperature&responseformat=text/csv&eventtime=latest"
            guard let waterTempurl = URL(string: waterTempurlString) else {return}
            
            self.waterTempDataServiceRequestWith(waterTempurl: waterTempurl)
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
                self.delegate?.didFinishWaterTempTask(sender: self, snapshot: self.currentSnapshot)
            }
        }
        
        let waterTempLines = waterTempDataString.components(separatedBy: "\n")
        let waterTempValues = waterTempLines[1].components(separatedBy: ",")

        //water temp
        guard let currentWaterTemp = Double(waterTempValues[6]) as Double? else {return}
        var currentWaterTempInFahrenheit = fahrenheitFromCelcius(temp: currentWaterTemp)
        currentWaterTempInFahrenheit = (currentWaterTempInFahrenheit*10).rounded()/10
        waterTemp = currentWaterTempInFahrenheit

        DispatchQueue.main.async {
            self.delegate?.didFinishWaterTempTask(sender: self, snapshot: self.currentSnapshot)
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
    
    func addWaterTempDataToSnapshot(_ snapshotWithoutWaterTemp : Snapshot, waterTemp : Double)-> Snapshot {
        var snapshot = snapshotWithoutWaterTemp
        snapshot.waterTemp = waterTemp
        return snapshot
    }
}





