//
//  SurfSnapshotView.swift
//  surf
//
//  Created by uBack on 4/19/18.
//  Copyright © 2018 surf. All rights reserved.
//

import Foundation
import UIKit


private var windUnit = "MPH"

 func addUIComponentsToView(currentSnapShot : Snapshot, view : UIView){
    
     func addWaveHeightLabels(){
    
        var waveHeightDigitCount = CGFloat(0)
        var waveHeight = 0.0
        if let wHeight = currentSnapShot.waveHgt as String?{
            waveHeight = Double(wHeight) ?? 0.0
        }
        
        switch waveHeight{
        case ...9:
            waveHeightDigitCount = 2
        case 10...99:
            waveHeightDigitCount = 3
        case 100...:
            waveHeightDigitCount = 4
        default:
            waveHeightDigitCount = 2
        }
        let offset: CGFloat = 45 * waveHeightDigitCount
        
        let widthPixels = 150 * waveHeightDigitCount + 100
        
        let waveHeightLabel = UILabel(frame: CGRect(x: 0, y: 0, width: widthPixels, height: 100))
        if let waveHeight = currentSnapShot.waveHgt as String?{
            waveHeightLabel.text = waveHeight
        }
        waveHeightLabel.font = UIFont(name:"Damascus", size: 80.0)
        waveHeightLabel.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        waveHeightLabel.center = CGPoint(x: view.frame.width - offset, y: 90)
        waveHeightLabel.textAlignment = .center
        view.addSubview(waveHeightLabel)
        
        let feetLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        feetLabel.text = "ft"
        feetLabel.font = UIFont(name:"Damascus", size: 20.0)
        feetLabel.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        feetLabel.center = CGPoint(x: (view.frame.width - offset) + 20 + (waveHeightDigitCount * 20), y: 95)
        feetLabel.textAlignment = .center
        view.addSubview(feetLabel)
    }
    addWaveHeightLabels()

    
    func addSpotDetails(){
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        if  let speed = currentSnapShot.windSpd as String?{
            if let direction = currentSnapShot.windDir as String?{
                label.text = speed + " " + windUnit + " " + direction + " WIND"
            }
        }
        label.font = UIFont(name:"Damascus", size: 10.0)
        label.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        let yValue = (view.frame.height/5) + 20
        label.center = CGPoint(x: view.frame.width/2, y:yValue)
        label.textAlignment = .center
        view.addSubview(label)
        
        let waveLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        if let direction = currentSnapShot.meanWaveDirection as String?{
            waveLabel.text =  direction + " SWELL"
        }
        waveLabel.font = UIFont(name:"Damascus", size: 10.0)
        waveLabel.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        waveLabel.center = CGPoint(x: view.frame.width/2, y:yValue + 20)
        waveLabel.textAlignment = .center
        view.addSubview(waveLabel)
        
        let waterTempLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        if let temp = currentSnapShot.waterTemp {
            waterTempLabel.text =  String(temp) + "°F WATER"
        }
        waterTempLabel.font = UIFont(name:"Damascus", size: 10.0)
        waterTempLabel.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        waterTempLabel.center = CGPoint(x: view.frame.width/2, y: yValue + 40)
        waterTempLabel.textAlignment = .center
        view.addSubview(waterTempLabel)
    }
    addSpotDetails()
    
    func addSpotTitleLabel(){
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 200))
        titleLabel.text = "Crystal Pier"
        titleLabel.font = UIFont(name:"Damascus", size: 40.0)
        titleLabel.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        titleLabel.center = CGPoint(x: view.frame.width/2, y: view.frame.height/5)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
    }
    addSpotTitleLabel()
    
}


func addWaveHeightIndicator(viewController : ViewController){
    
    let centerY = viewController.view.bounds.height / 2
    var waveHeightMaxInt: CGFloat = 0
    if let waveHeight = viewController.currentSnapShot?.waveHgt as String?{
        if let intValue = CGFloat(Double(waveHeight)! * 10) as CGFloat?{
            waveHeightMaxInt = intValue
        }
    }
    let waveTop = centerY - waveHeightMaxInt - 14
    let waveHeightLabel = UILabel(frame: CGRect(x: 0, y: waveTop, width: 100, height: 20))
    if let waveHeight = viewController.currentSnapShot?.waveHgt as String?{
        waveHeightLabel.text = "__ \(waveHeight)ft"
    }
    waveHeightLabel.font = UIFont(name:"Damascus", size: 10.0)
    waveHeightLabel.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    waveHeightLabel.textAlignment = .left
    waveHeightLabel.tag = 100
    viewController.view.addSubview(waveHeightLabel)
}

