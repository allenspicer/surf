//
//  DataHelpers.swift
//  surf
//
//  Created by uBack on 5/11/18.
//  Copyright © 2018 surf. All rights reserved.
//

import Foundation
import UIKit


func windDirectionFromDegrees(degrees : Float) -> String {
    
    let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
    let i: Int = Int((degrees + 11.25)/22.5)
    return directions[i % 16]
}


func fahrenheitFromCelcius(temp : Double) -> (Double){
    let tempInF = (9.0 / 5.0 * (temp)) + 32.0
    return (tempInF)
}

func getWaterColorFromTempInF(_ temp: Double) -> CGColor?{
    var color : CGColor? = nil
    var tempIndex = Int()
    
    switch temp {
    case -140..<40:
        tempIndex = 0
    case 40..<65:
        tempIndex = 1
    case 65..<80:
        tempIndex = 2
    case 80..<1000:
        tempIndex = 0
    default:
        tempIndex = 2
    }
    
    let colorArray = [#colorLiteral(red: 0.4, green: 0.3450980392, blue: 0.8549019608, alpha: 1), #colorLiteral(red: 0.2941176471, green: 0.6078431373, blue: 0.8274509804, alpha: 1), #colorLiteral(red: 0.2705882353, green: 0.8705882353, blue: 0.4745098039, alpha: 1), #colorLiteral(red: 1, green: 0.7019607843, blue: 0.3137254902, alpha: 1)]
    color = colorArray[tempIndex].cgColor
    
    return color
}

