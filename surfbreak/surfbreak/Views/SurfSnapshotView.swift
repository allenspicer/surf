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
    let textColor = #colorLiteral(red: 0.9803921569, green: 0.9803921569, blue: 0.9803921569, alpha: 1)
    
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
        
        let backgroundView = UIImageView(frame: self.frame)
        backgroundView.image = #imageLiteral(resourceName: "Bkgd_main")
        backgroundView.contentMode = .center
        self.addSubview(backgroundView)
        self.sendSubview(toBack: backgroundView)
    }
    
    func addWaveHeightIndicator(){
        
        let centerY = self.bounds.height / 2
        var waveHeightMaxFloat: CGFloat = 0
        waveHeightMaxFloat = CGFloat(self.currentSnapShot.waveHeight * 10)
        let waveTop = centerY - waveHeightMaxFloat - 14
        let waveHeightLabel = UILabel(frame: CGRect(x: 0, y: waveTop, width: 100, height: 20))
        waveHeightLabel.text = "__ \(self.currentSnapShot.waveHeight)ft"
        waveHeightLabel.font = UIFont(name:"Damascus", size: 10.0)
        waveHeightLabel.textColor =  textColor
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
            waveHeight = currentSnapShot.waveHeight
        
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
        waveHeightLabel.text = "\(currentSnapShot.waveHeight)ft"
        waveHeightLabel.font = UIFont(name:"Damascus", size: 80.0)
        waveHeightLabel.textColor =  textColor
        waveHeightLabel.center = CGPoint(x: self.frame.width/2, y: 200)
        waveHeightLabel.textAlignment = .center
        self.addSubview(waveHeightLabel)
        
        //        let feetLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        //        feetLabel.text = "ft"
        //        feetLabel.font = UIFont(name:"Damascus", size: 20.0)
        //        feetLabel.textColor =  textColor
        //        feetLabel.center = CGPoint(x: (self.frame.width - offset) + 20 + (waveHeightDigitCount * 20), y: 95)
        //        feetLabel.textAlignment = .center
        //        self.addSubview(feetLabel)
    }
    
    
    private func addSpotDetails(){
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        label.text = "Loading..."
        label.text = "\(currentSnapShot.windCardinalDirection) WIND \(currentSnapShot.windSpeed) \(windUnit)"
        label.font = UIFont(name:"Damascus", size: 10.0)
        label.textColor =  textColor
        let yValue = (2 * self.frame.height/5) + 20
        label.center = CGPoint(x: self.frame.width/2, y:yValue)
        label.textAlignment = .center
        self.addSubview(label)
        
        let waveLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        if let direction = currentSnapShot.swellDirectionString as String?{
            waveLabel.text =  direction + " SWELL"
        }
        waveLabel.font = UIFont(name:"Damascus", size: 10.0)
        waveLabel.textColor =  textColor
        waveLabel.center = CGPoint(x: self.frame.width/2, y:yValue + 20)
        waveLabel.textAlignment = .center
        self.addSubview(waveLabel)
        
        let waterTempLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        waterTempLabel.text =  String(currentSnapShot.waterTemp) + "°F WATER"
        waterTempLabel.font = UIFont(name:"Damascus", size: 10.0)
        waterTempLabel.textColor =  textColor
        waterTempLabel.center = CGPoint(x: self.frame.width/2, y: yValue + 40)
        waterTempLabel.textAlignment = .center
        self.addSubview(waterTempLabel)
    }
    
    private func addSpotTitleLabel(){
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 200))
        titleLabel.text = "\(currentSnapShot.nickname)"
//        }else if let name = currentSnapShot.stationName {
//            titleLabel.text = "\(name)"
//        }
        titleLabel.font = UIFont(name:"Damascus", size: 20.0)
        titleLabel.textColor =  textColor
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
        frequencyAmountLabel.text = "\(currentSnapShot.period)"
        frequencyLabel.textColor = textColor
        stack.addArrangedSubview(frequencyAmountLabel)
        return stack
    }
    
    private func addAirTempStackView() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        let airLabel = UILabel()
        airLabel.text = "AIR"
        airLabel.textColor = textColor
        airLabel.font = UIFont(name:"Damascus", size: 10.0)
        stack.addArrangedSubview(airLabel)
        let airTempLabel = UILabel()
        airTempLabel.text = "Loading..."
        airTempLabel.text = "\(currentSnapShot.airTemp)° F"
        airTempLabel.textColor = textColor
        stack.addArrangedSubview(airTempLabel)
        return stack
    }
    
    private func addWaterTempStackView() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        let waterLabel = UILabel()
        waterLabel.text = "WATER"
        waterLabel.textColor = textColor
        waterLabel.font = UIFont(name:"Damascus", size: 10.0)
        stack.addArrangedSubview(waterLabel)
        let waterTempLabel = UILabel()
        waterTempLabel.text = "\(currentSnapShot.waterTemp)° F"
        waterTempLabel.textColor = textColor
        stack.addArrangedSubview(waterTempLabel)
        return stack
    }
    
    private func addTideStackView() -> UIView {
        let stack = UIStackView()
        stack.distribution = .fillProportionally
        stack.axis = .vertical
        let tideLabel = UILabel()
        tideLabel.text = "TIDE"
        tideLabel.textColor = textColor
        tideLabel.font = UIFont(name:"Damascus", size: 10.0)
        stack.addArrangedSubview(tideLabel)
        let tideDirectionLabel = UILabel()
        tideDirectionLabel.text = "\(currentSnapShot.tideDirectionString)"
        tideDirectionLabel.textColor = textColor
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
        nextTideLabel.textColor = textColor
        stack.addArrangedSubview(nextTideLabel)
        let nextTideContentLabel = UILabel()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        let time = dateFormatter.string(from: currentSnapShot.nextTideTime)
        nextTideContentLabel.text = "\(currentSnapShot.nextTidePolar) @ \(time)"
        nextTideContentLabel.textColor = textColor
        stack.addArrangedSubview(nextTideContentLabel)
        return stack
    }
    
    private func addWindStackView() -> UIView {
        let stack = UIStackView()
        stack.distribution = .fillProportionally
        stack.axis = .vertical
        let windLabel = UILabel()
        windLabel.text = "WIND"
        windLabel.textColor = textColor
        windLabel.font = UIFont(name:"Damascus", size: 10.0)
        stack.addArrangedSubview(windLabel)
        let windContentLabel = UILabel()
        windContentLabel.text = "Loading..."
        windContentLabel.textColor = textColor
        windContentLabel.text = "\(currentSnapShot.windDirectionString) \(currentSnapShot.windSpeed) MPH"
        stack.addArrangedSubview(windContentLabel)
        return stack
    }
    
}
