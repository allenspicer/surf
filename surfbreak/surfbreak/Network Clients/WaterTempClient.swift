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
    
    
    private func buoyDataServiceRequestWith(waveurl : URL, waterTempurl : URL){
        
        var dataString = String()
        do {
            dataString = try String(contentsOf: waveurl)
        }catch{
            print("Wave Bouy Data Retreival Error: \(error)")
            DispatchQueue.main.async {
                self.delegate?.didFinishBuoyTask(sender: self, snapshot: self.currentSnapshot, stations: self.allStations)
            }
            return
        }
        
        var lines = dataString.components(separatedBy: "\n")
        var values = lines[1].components(separatedBy: ",")

        //wave height
        guard let currentWaveHeight = Double(values[5]) as Double? else {return}
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        var heightInFeet = currentWaveHeight * 3.28
        heightInFeet = (heightInFeet*10).rounded()/10

        //wave direction
        guard let waveToDirectionDegrees = Double(values[13]) as Double? else {return}
        let waveToDirectionInt = Int(waveToDirectionDegrees)
        let waveFromDirectionInt = abs(360 - waveToDirectionInt)

        //wave frequency/period
        guard let waveAveragePeriod = Double(values[7]) as Double? else {return}

        currentSnapshot.waveHeight = heightInFeet
        currentSnapshot.swellDirection = waveFromDirectionInt
//        currentSnapshot.swellDirectionString = directionFromDegrees(degrees: Float(waveFromDirectionInt))
        currentSnapshot.period = waveAveragePeriod
        currentSnapshot.beachFaceDirection = currentStation.bfd
        currentSnapshot.id = currentStation.id
        currentSnapshot.stationId = currentStation.station
        currentSnapshot.stationName = currentStation.name
        currentSnapshot.airWindTideId = currentStation.airWindTideId
        
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
            let urlString = "https://sdf.ndbc.noaa.gov/sos/server.php?request=GetObservation&service=SOS&version=1.0.0&offering=urn:ioos:station:wmo:\(currentStation.station)&observedproperty=Waves&responseformat=text/csv&eventtime=latest"
            guard let waveurl = URL(string: urlString) else {return}
            
            let waterTempurlString = "https://sdf.ndbc.noaa.gov/sos/server.php?request=GetObservation&service=SOS&version=1.0.0&offering=urn:ioos:station:wmo:\(currentStation.station)&observedproperty=sea_water_temperature&responseformat=text/csv&eventtime=latest"
            guard let waterTempurl = URL(string: waterTempurlString) else {return}
            
            buoyDataServiceRequestWith(waveurl: waveurl, waterTempurl: waterTempurl)
        }
    }
}

extension BuoyClient {
    
    //
    //MARK: - helpers to convert data
    //
    
    
    func fahrenheitFromCelcius(temp : Double) -> (Double){
        let tempInF = (9.0 / 5.0 * (temp)) + 32.0
        return (tempInF)
    }
}





