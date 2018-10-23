//
//  BuoyClient.swift
//  surfbreak
//
//  Created by Allen Spicer on 7/26/18.
//  Copyright © 2018 surfbreak. All rights reserved.
//

import UIKit


protocol BuoyClientDelegate: AnyObject {
    func didFinishBuoyTask(sender: BuoyClient, snapshot : Snapshot, stations : [Station])
}

final class BuoyClient: NSObject {
    
    var delegate : BuoyClientDelegate?
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
    
    
    private func buoyDataServiceRequestWith( url : URL){
        
        var dataString = String()
        do {
            dataString = try String(contentsOf: url)
        }catch{
            print("Bouy Data Retreival Error: \(error)")
            DispatchQueue.main.async {
                self.delegate?.didFinishBuoyTask(sender: self, snapshot: self.currentSnapshot, stations: self.allStations)
            }
        }
        
        let lines = dataString.components(separatedBy: "\n")
        let titles = lines[0].components(separatedBy: ",")
        let values = lines[1].components(separatedBy: ",")
        for index in 0..<values.count {
            print("item\(index) \(titles[index]): \(values[index])")
        }

        //wave height
        guard let currentWaveHeight = Double(values[5]) as Double? else {return}
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        var heightInFeet = currentWaveHeight * 3.28
        heightInFeet = (heightInFeet*10).rounded()/10

        //wave direction
        guard let currentWaveDirectionDegrees = Double(values[13]) as Double? else {return}
        let waveDirectionInt = Int(currentWaveDirectionDegrees)

        //wave frequency/period
        guard let waveAveragePeriod = Double(values[7]) as Double? else {return}

        //water temp
//        guard let currentWaterTemp = Double(values[12]) as Double? else {return}
//        var currentWaterTempInFahrenheit = fahrenheitFromCelcius(temp: currentWaterTemp)
//        currentWaterTempInFahrenheit = (currentWaterTempInFahrenheit*10).rounded()/10


       currentSnapshot.waveHeight = heightInFeet
       currentSnapshot.swellDirection = waveDirectionInt
       currentSnapshot.swellDirectionString = directionFromDegrees(degrees: Float(currentWaveDirectionDegrees))
       currentSnapshot.period = waveAveragePeriod
//       currentSnapshot.waterTemp = currentWaterTempInFahrenheit
       currentSnapshot.beachFaceDirection = currentStation.bfd
       currentSnapshot.id = currentStation.id
       currentSnapshot.stationId = currentStation.station
        currentSnapshot.stationName = currentStation.name
        currentSnapshot.airWindTideId = currentStation.airWindTideId
        currentSnapshot.windDirectionString = directionFromDegrees(degrees: Float(currentSnapshot.windCardinalDirection))
        
//            currentSnapShot.nickname = name

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
            guard let url = URL(string: urlString) else {return}
            buoyDataServiceRequestWith(url: url)
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
    
    func directionFromDegrees(degrees : Float) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let categoryInt: Int = Int((degrees + 11.25)/22.5)
        return directions[categoryInt % 16]
    }
    
    
    func appendDistanceToUserWith(userLocation : UserLocation){
        // Used to convert latitude and longitude into miles
        // both numbers are approximate. One longitude at 40 degrees is about 53 miles however the true
        // number of miles is up to 69 at the equator and down to zero at the poles
        let approxMilesToLon = 53.0
        let approxMilesToLat = 69.0
        let lon = userLocation.longitude
        let lat = userLocation.latitude
        let lonDiffAbs = abs(currentStation.longitude - lon) * approxMilesToLon
        let latDiffAbs = abs(currentStation.latitude - lat) * approxMilesToLat
        currentSnapshot.distance = Int((pow(lonDiffAbs, 2) + pow(latDiffAbs, 2)).squareRoot())
    }
}





