//
//  DataHelpers.swift
//  surf
//
//  Created by Allen Spicer on 5/11/18.
//  Copyright © 2018 surf. All rights reserved.
//

import Foundation
import UIKit


func directionFromDegrees(degrees : Float) -> String {
    
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

//invert color components for complementary title color
func colorComplement(color: CGColor) -> UIColor{
    
    let colorArray = [#colorLiteral(red: 0.4, green: 0.3450980392, blue: 0.8549019608, alpha: 1), #colorLiteral(red: 0.2941176471, green: 0.6078431373, blue: 0.8274509804, alpha: 1), #colorLiteral(red: 0.2705882353, green: 0.8705882353, blue: 0.4745098039, alpha: 1), #colorLiteral(red: 1, green: 0.7019607843, blue: 0.3137254902, alpha: 1)]
    var returnIndex = 0

    for index in 0..<colorArray.count{
        if color == colorArray[index].cgColor {
            let halfCount = colorArray.count / 2
            if index + halfCount >= colorArray.count {
                returnIndex = index + halfCount - 4
            }else{
                returnIndex = index + halfCount
            }
        }
    }
    return colorArray[returnIndex]
}

extension UIColor {
    
    func lighter(by percentage:CGFloat=30.0) -> UIColor? {
        return self.adjust(by: abs(percentage) )
    }
    
    func darker(by percentage:CGFloat=30.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage) )
    }
    
    func adjust(by percentage:CGFloat=30.0) -> UIColor? {
        var r:CGFloat=0, g:CGFloat=0, b:CGFloat=0, a:CGFloat=0;
        if(self.getRed(&r, green: &g, blue: &b, alpha: &a)){
            return UIColor(red: min(r + percentage/100, 1.0),
                           green: min(g + percentage/100, 1.0),
                           blue: min(b + percentage/100, 1.0),
                           alpha: a)
        }else{
            return nil
        }
    }
}

