//
//  TideClient.swift
//  surf
//
//  Created by Allen Spicer on 6/4/18.
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
    var windShoreDirection: String?
    
    init(currentSnapshot:Snapshot) {
        self.currentSnapshot = currentSnapshot
    }
    
    func createSurfQualityAssesment(){
        DispatchQueue.global(qos:.utility).async {
            if let windDirection = self.currentSnapshot?.windDir, let faceDirection = self.currentSnapshot?.beachFaceDirection{
                let diff = faceDirection - windDirection
                let absDiff = abs(diff)
                self.surfQualityColor = self.getColorFromDiff(absDiff)
                DispatchQueue.main.async {
                    print("The Current Wind Direciton is \(windDirection)")
                    print("The Beach Face Direciton is \(faceDirection)")
                    
                    self.didFinishSurfQualityAssesment()
                }
            }
        }
    }
    
    func didFinishSurfQualityAssesment() {
        delegate?.didFinishSurfQualityTask(sender: self, surfQualityColor: surfQualityColor)
    }
    
    func getColorFromDiff (_ diff : Double) -> UIColor{
        if diff > 0 && diff < 60 {
            print("The wind is onshore \(diff)")
            return UIColor.red
        } else if diff > 90 {
            print("The wind is offshore \(diff)")
            return UIColor.green
        }
    print("The wind is sideshore \(diff)")
    return UIColor.yellow
    }

}


