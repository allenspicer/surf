//
//  SurfSnapshotView.swift
//  surf
//
//  Created by Allen Spicer on 4/19/18.
//  Copyright © 2018 surf. All rights reserved.
//

import Foundation
import UIKit


private var windUnit = "MPH"

class SurfSnapshotView: UIScrollView {
    
    var currentSnapShot : Snapshot
    var label = UILabel()
    
    init(snapshot: Snapshot) {
        self.currentSnapShot = snapshot
        super.init(frame: UIScreen.main.bounds)
        loadAllSubviews()
        return
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadAllSubviews(){
        setBackgroundGradient()
        addWaveHeightLabels()
        addSpotDetails()
        addSpotTitleLabel()
        addDetailContainerView()
    }
    
    
    func setBackgroundGradient(){
        
        self.backgroundColor = #colorLiteral(red: 0.01176470588, green: 0.5294117647, blue: 0.5294117647, alpha: 1)
        let gradientLayer:CAGradientLayer = CAGradientLayer()
        gradientLayer.frame.size = self.frame.size
        let customYellow = #colorLiteral(red: 0.8666666667, green: 0.7529411765, blue: 0.1333333333, alpha: 1)
        gradientLayer.colors = [customYellow.cgColor, UIColor.clear.cgColor]
        self.layer.addSublayer(gradientLayer)
    }
    
    func addWaveHeightIndicator(){
        
        let centerY = self.bounds.height / 2
        var waveHeightMaxFloat: CGFloat = 0
        if let waveHeight = self.currentSnapShot.waveHgt{
            waveHeightMaxFloat = CGFloat(waveHeight * 10)
        }
        let waveTop = centerY - waveHeightMaxFloat - 14
        let waveHeightLabel = UILabel(frame: CGRect(x: 0, y: waveTop, width: 100, height: 20))
        if let waveHeight = self.currentSnapShot.waveHgt{
            waveHeightLabel.text = "__ \(waveHeight)ft"
        }
        waveHeightLabel.font = UIFont(name:"Damascus", size: 10.0)
        waveHeightLabel.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        waveHeightLabel.textAlignment = .left
        self.addSubview(waveHeightLabel)
        label = waveHeightLabel
    }
    
    func removeWaveHeightIndicator(){
        label.removeFromSuperview()
    }
    
    private func addWaveHeightLabels(){
        
        var waveHeightDigitCount = CGFloat(0)
        var waveHeight = 0.0
        if let wHeight = currentSnapShot.waveHgt{
            waveHeight = wHeight
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
        //        let offset: CGFloat = 45 * waveHeightDigitCount
        
        let widthPixels = 150 * waveHeightDigitCount + 200
        let distanceFromTop = self.frame.size.height/5
        
        let waveHeightLabel = UILabel(frame: CGRect(x: 0, y: 0, width: widthPixels, height: distanceFromTop))
        waveHeightLabel.text = "\(currentSnapShot.waveHgt ?? 0.0)ft"
        waveHeightLabel.font = UIFont(name:"Damascus", size: 80.0)
        waveHeightLabel.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        waveHeightLabel.center = CGPoint(x: self.frame.width/2, y: 200)
        waveHeightLabel.textAlignment = .center
        self.addSubview(waveHeightLabel)
        
        //        let feetLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        //        feetLabel.text = "ft"
        //        feetLabel.font = UIFont(name:"Damascus", size: 20.0)
        //        feetLabel.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        //        feetLabel.center = CGPoint(x: (self.frame.width - offset) + 20 + (waveHeightDigitCount * 20), y: 95)
        //        feetLabel.textAlignment = .center
        //        self.addSubview(feetLabel)
    }
    
    
    private func addSpotDetails(){
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        label.text = "Loading..."
        if let speed = currentSnapShot.windSpd, let direction = currentSnapShot.windCardinalDirection{
            label.text = "\(direction) WIND \(speed) \(windUnit)"
        }
        label.font = UIFont(name:"Damascus", size: 10.0)
        label.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        let yValue = (2 * self.frame.height/5) + 20
        label.center = CGPoint(x: self.frame.width/2, y:yValue)
        label.textAlignment = .center
        self.addSubview(label)
        
        let waveLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        if let direction = currentSnapShot.meanWaveDirection as String?{
            waveLabel.text =  direction + " SWELL"
        }
        waveLabel.font = UIFont(name:"Damascus", size: 10.0)
        waveLabel.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        waveLabel.center = CGPoint(x: self.frame.width/2, y:yValue + 20)
        waveLabel.textAlignment = .center
        self.addSubview(waveLabel)
        
        let waterTempLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        if let temp = currentSnapShot.waterTemp {
            waterTempLabel.text =  String(temp) + "°F WATER"
        }
        waterTempLabel.font = UIFont(name:"Damascus", size: 10.0)
        waterTempLabel.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        waterTempLabel.center = CGPoint(x: self.frame.width/2, y: yValue + 40)
        waterTempLabel.textAlignment = .center
        self.addSubview(waterTempLabel)
    }
    
    private func addSpotTitleLabel(){
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 200))
        if let name = currentSnapShot.nickname {
            titleLabel.text = "\(name)"
        }else if let name = currentSnapShot.stationName {
            titleLabel.text = "\(name)"
        }
        titleLabel.font = UIFont(name:"Damascus", size: 20.0)
        titleLabel.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        titleLabel.center = CGPoint(x: self.frame.width/2, y: 2 * self.frame.height/5)
        titleLabel.textAlignment = .center
        self.addSubview(titleLabel)
    }
    
    private func addDetailContainerView(){
        let containerStackView = UIStackView(frame: CGRect(x: 10, y: ( 6 * self.bounds.size.height / 10) , width: (self.bounds.size.width - 10), height: ( 2 * self.bounds.size.height / 10)))
        containerStackView.axis = .horizontal
        containerStackView.distribution = .fillEqually
        let leftStack = UIStackView()
        leftStack.axis = .vertical
        leftStack.distribution = .fillEqually
        leftStack.spacing = 20
        leftStack.addArrangedSubview(addFrequencyStackView())
        leftStack.addArrangedSubview(addAirTempStackView())
        leftStack.addArrangedSubview(addWaterTempStackView())
        let rightStack = UIStackView()
        rightStack.axis = .vertical
        rightStack.distribution = .fillEqually
        rightStack.spacing = 20
        rightStack.addArrangedSubview(addTideStackView())
        rightStack.addArrangedSubview(addTideNextStackView())
        rightStack.addArrangedSubview(addWindStackView())
        
        containerStackView.addArrangedSubview(leftStack)
        containerStackView.addArrangedSubview(rightStack)
        
        self.addSubview(containerStackView)
    }
    
    private func addFrequencyStackView() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        let frequencyLabel = UILabel()
        frequencyLabel.text = "SECONDS BETWEEN WAVES"
        frequencyLabel.font = UIFont(name:"Damascus", size: 10.0)
        stack.addArrangedSubview(frequencyLabel)
        let frequencyAmountLabel = UILabel()
        frequencyAmountLabel.text = "\(currentSnapShot.waveAveragePeriod ?? 0.0)"
        stack.addArrangedSubview(frequencyAmountLabel)
        return stack
    }
    
    private func addAirTempStackView() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        let airLabel = UILabel()
        airLabel.text = "AIR"
        airLabel.font = UIFont(name:"Damascus", size: 10.0)
        stack.addArrangedSubview(airLabel)
        let airTempLabel = UILabel()
        airTempLabel.text = "Loading..."
        if let airTemp = currentSnapShot.airTemp {
            airTempLabel.text = "\(airTemp)° F"
        }
        stack.addArrangedSubview(airTempLabel)
        return stack
    }
    
    private func addWaterTempStackView() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        let waterLabel = UILabel()
        waterLabel.text = "WATER"
        waterLabel.font = UIFont(name:"Damascus", size: 10.0)
        stack.addArrangedSubview(waterLabel)
        let waterTempLabel = UILabel()
        waterTempLabel.text = "\(currentSnapShot.waterTemp ?? 0.0)° F"
        stack.addArrangedSubview(waterTempLabel)
        return stack
    }
    
    private func addTideStackView() -> UIView {
        let stack = UIStackView()
        stack.distribution = .fillProportionally
        stack.axis = .vertical
        let tideLabel = UILabel()
        tideLabel.text = "TIDE"
        tideLabel.font = UIFont(name:"Damascus", size: 10.0)
        stack.addArrangedSubview(tideLabel)
        let tideDirectionLabel = UILabel()
        tideDirectionLabel.text = "Loading..."
        if let tideFlow = currentSnapShot.currentTideDirection {
            tideDirectionLabel.text = "\(tideFlow)"
        }
        stack.addArrangedSubview(tideDirectionLabel)
        return stack
    }
    
    private func addTideNextStackView() -> UIView {
        let stack = UIStackView()
        stack.distribution = .fillProportionally
        stack.axis = .vertical
        let nextTideLabel = UILabel()
        nextTideLabel.text = "NEXT TIDE"
        nextTideLabel.font = UIFont(name:"Damascus", size: 10.0)
        stack.addArrangedSubview(nextTideLabel)
        let nextTideContentLabel = UILabel()
        nextTideContentLabel.text = "Loading..."
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        if let letter = currentSnapShot.upcomingTidePolar, let dateTime = currentSnapShot.upcomingTideTimestamp {
            let time = dateFormatter.string(from: dateTime)
            nextTideContentLabel.text = "\(letter) @ \(time)"
        }
        stack.addArrangedSubview(nextTideContentLabel)
        return stack
    }
    
    private func addWindStackView() -> UIView {
        let stack = UIStackView()
        stack.distribution = .fillProportionally
        stack.axis = .vertical
        let windLabel = UILabel()
        windLabel.text = "WIND"
        windLabel.font = UIFont(name:"Damascus", size: 10.0)
        stack.addArrangedSubview(windLabel)
        let windContentLabel = UILabel()
        windContentLabel.text = "Loading..."
        if let direction = currentSnapShot.windDirectionString, let speed = currentSnapShot.windSpd {
            windContentLabel.text = "\(direction) \(speed) MPH"
        }
        stack.addArrangedSubview(windContentLabel)
        return stack
    }
    
}
