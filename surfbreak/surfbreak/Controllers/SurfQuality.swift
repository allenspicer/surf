//
//  TideClient.swift
//  surf
//
//  Created by Allen Spicer on 6/4/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit


protocol SurfQualityDelegate: AnyObject {
    func didFinishSurfQualityTask(sender: SurfQuality, snapshot: Snapshot)
}

final class SurfQuality: NSObject {
    
    var delegate : SurfQualityDelegate?
    var surfQualityColor = UIColor()
    var currentSnapshot : Snapshot
    var isOnshore : Bool?
    var windShoreDirection: String?
    
    init(currentSnapshot:Snapshot) {
        self.currentSnapshot = currentSnapshot
    }
    
    func createSurfQualityAssesment(){
        DispatchQueue.global(qos:.utility).async {
            let windSpeed = self.currentSnapshot.windSpeed
            let windDirection = self.currentSnapshot.windCardinalDirection
            let faceDirection = self.currentSnapshot.beachFaceDirection
            let period = self.currentSnapshot.period
            let waveHeight = self.currentSnapshot.waveHeight
            let absDiff = Double(abs(faceDirection - windDirection))
            let directionInt = self.getDirectionFromDiff(absDiff)
            self.currentSnapshot.quality = 1
            
            //1 - ideal
            //2 - good
            //3 - fair
            //4 - poor
            
            //use the wave height to set the quality measure - indicating better conditions
            switch waveHeight{
            case ...1.5:
                self.currentSnapshot.quality = 5
            case ...2.0:
                self.currentSnapshot.quality = 4
            case 2.0...3.0:
                self.currentSnapshot.quality = 2
            case 3.0...15.0:
                self.currentSnapshot.quality = 1
            case 15.0...:
                self.currentSnapshot.quality = 2
            default:
                self.currentSnapshot.quality = self.currentSnapshot.quality
            }
            
            //use the swell period to detract from the quality measure - indicating better conditions
            switch period{
            case ...4:
                self.currentSnapshot.quality += 10
            case 4...7:
                self.currentSnapshot.quality += 4
            case 7...9:
                self.currentSnapshot.quality -= 1
            case 9...:
                self.currentSnapshot.quality -= 3
            default:
                self.currentSnapshot.quality = self.currentSnapshot.quality
            }
            
            //if the wind is strong or from a bad direction
            //heavily increment the quality measure to show
            
            switch directionInt{
            case 1:
                //if wind is onshore and greater than 5
                if windSpeed > 5{
                    self.currentSnapshot.quality += 4
                }
                if windSpeed < 5{
                    self.currentSnapshot.quality -= 2
                }
            case 2:
                //if wind is offshore and greater than 20
                if windSpeed > 20{
                    self.currentSnapshot.quality += 4
                }
                if windSpeed > 15{
                    self.currentSnapshot.quality += 1
                }
                if 5 < windSpeed && windSpeed < 10{
                    self.currentSnapshot.quality -= 1
                }
                if windSpeed < 5{
                    self.currentSnapshot.quality -= 2
                }
                
            case 3:
                //if wind is sideshore and greater than 10
                if windSpeed > 5{
                    self.currentSnapshot.quality += 4
                }
                if windSpeed < 5{
                    self.currentSnapshot.quality -= 2
                }
            default:
                self.currentSnapshot.quality = self.currentSnapshot.quality
            }
            
            //ensure that the quality measure is within bounds
            switch self.currentSnapshot.quality{
            case ...1:
                self.currentSnapshot.quality = 1
            case 4...:
                self.currentSnapshot.quality = 4
            default:
                self.currentSnapshot.quality = self.currentSnapshot.quality
            }
            self.currentSnapshot.quality = self.currentSnapshot.quality + 2
                //was setting background color here with wind direction
                //                self.currentSnapshot.backgroundColor = self.getColorFromDiff(absDiff)
                DispatchQueue.main.async {
                    print("The Current Wind Direciton is \(windDirection)")
                    print("The Beach Face Direciton is \(faceDirection)")
                    self.didFinishSurfQualityAssesment()
            }
        }
    }
    
    func didFinishSurfQualityAssesment() {
        self.delegate?.didFinishSurfQualityTask(sender: self, snapshot: self.currentSnapshot)
    }
    
    func getDirectionFromDiff (_ diff : Double) -> Int{
        if diff > 0 && diff < 60 {
//            self.currentSnapshot.windDirectionString = "ON"
            return 1
        } else if diff > 90 {
//            self.currentSnapshot.windDirectionString = "OFF"
            return 2
        }
//        self.currentSnapshot.windDirectionString = "SIDE"
        return 3
    }
    
    func getSnapshotWithSurfQuality ()-> Snapshot {
        return self.currentSnapshot
    }
    
}

