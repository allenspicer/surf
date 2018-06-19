//
//  TideClient.swift
//  surf
//
//  Created by uBack on 6/4/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit


protocol SurfQualityDelegate: AnyObject {
    func didFinishSurfQualityTask(sender: SurfQuality, surfQualityColor: UIColor)
}

final class SurfQuality: NSObject {
    
    var delegate : SurfQualityDelegate?
    var surfQualityColor = UIColor()
    var currentSnapshot : Snapshot?
    var isOnshore : Bool?
    enum WindShoreDirection: String {
        case onshore, offshore, sideshore
    }
    
    init(currentSnapshot:Snapshot) {
        self.currentSnapshot = currentSnapshot
    }
    
    func validateCompassDirection (_ direction : Double) -> Double {
        var finalDirection = direction
        if direction > 360 {
            finalDirection = direction - 360
        }else if direction < 0 {
            finalDirection = direction + 360
        }
        return finalDirection
    }
    
    func valuesContainZero (_ values: (Double, Double)) -> Bool {
        let range = values.0..<values.1
        if range.contains(0.0){
            return true
        }
        return false
    }
    
    func processSnapshotForWaveQuality(_ beachFaceDirection : Double){
//        let wBBeachFaceDirection = 143.0
        var windShoreDirection = String()
        let onshoreRangeValues = (validateCompassDirection(beachFaceDirection - 45), validateCompassDirection(beachFaceDirection + 45))
        let offshoreRangeValues = (validateCompassDirection(beachFaceDirection - 135), validateCompassDirection(beachFaceDirection + 135))
        //if range contains zero look for values above and below
        //otherwise look for values inside the range
        
        var helperRange = 0.0..<1
        let onshoreRange : Range<Double> = {
            if valuesContainZero(onshoreRangeValues){
                helperRange = onshoreRangeValues.1..<360.0
                return onshoreRangeValues.0..<0.0
            }
            return onshoreRangeValues.0..<onshoreRangeValues.1
        }()
        let offshoreRange : Range<Double> = {
            if valuesContainZero(offshoreRangeValues){
                helperRange = offshoreRangeValues.1..<360.0
                return offshoreRangeValues.0..<0.0
            }
            return offshoreRangeValues.0..<offshoreRangeValues.1
        }()
        
        
        if let windDirection = currentSnapshot?.windDir {
            switch windDirection {
            case onshoreRange:
                windShoreDirection = "onshore"
            case offshoreRange:
                windShoreDirection = "offshore"
            default:
                windShoreDirection = "sideshore"
            }
        }
        
        
        
        
    }
    
    func didFinishSurfQualityAssesment() {
        delegate?.didFinishSurfQualityTask(sender: self, surfQualityColor: surfQualityColor)
    }

}


