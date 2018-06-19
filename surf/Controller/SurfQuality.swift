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
    
    private func validateCompassDirection (_ direction : Double) -> Double {
        var finalDirection = direction
        if direction > 360 {
            finalDirection = direction - 360
        }else if direction < 0 {
            finalDirection = direction + 360
        }
        return finalDirection
    }
    
    private func rangeFromTuple(_ tuple: (Double, Double)) -> Range<Double>{
        if tuple.1 > tuple.0{
            return tuple.0..<tuple.1
        }
        return tuple.1..<tuple.0
    }
    
    private func valuesContainZero (_ values: (Double, Double)) -> Bool {
        let range : Range<Double> = rangeFromTuple(values)
        if range.contains(0.0){
            return true
        }
        return false
    }
    
    func getWindAngleWithBeachFaceDirection(_ beachFaceDirection : Double) -> String{
        let onshoreRangeValues = (validateCompassDirection(beachFaceDirection - 45), validateCompassDirection(beachFaceDirection + 45))
        let offshoreRangeValues = (validateCompassDirection(beachFaceDirection - 135), validateCompassDirection(beachFaceDirection + 135))
        
        //if range contains zero look for values above and below
        //otherwise look for values inside the range
        
        var helperRange = 0.0..<1
        var helperIntFlag = 0
        let onshoreRange : Range<Double> = {
            if valuesContainZero(onshoreRangeValues){
                helperRange = onshoreRangeValues.1..<360.0
                helperIntFlag = 1
                return onshoreRangeValues.0..<0.0
            }
            return rangeFromTuple(onshoreRangeValues)
        }()
        let offshoreRange : Range<Double> = {
            if valuesContainZero(offshoreRangeValues){
                helperRange = offshoreRangeValues.1..<360.0
                helperIntFlag = 2
                return offshoreRangeValues.0..<0.0
            }
            return rangeFromTuple(offshoreRangeValues)
        }()
        if let windDirection = currentSnapshot?.windDir {

            if helperIntFlag == 1 {
                if onshoreRange.contains(windDirection) || helperRange.contains(windDirection){
                    return "onshore"
                }
            }
            if helperIntFlag == 2 {
                if offshoreRange.contains(windDirection) || helperRange.contains(windDirection){
                    return "offshore"
                }
            }
        
            switch windDirection {
            case onshoreRange:
                return "onshore"
            case offshoreRange:
                return "offshore"
            default:
                return "sideshore"
            }
        }
        return "error"
    }
    
    func didFinishSurfQualityAssesment() {
        delegate?.didFinishSurfQualityTask(sender: self, surfQualityColor: surfQualityColor)
    }

}


