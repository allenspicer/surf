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
        switch currentSnapShot.quality{
        case 4:
            backgroundView.image = #imageLiteral(resourceName: "Bkgd_4")
        case 3:
            backgroundView.image = #imageLiteral(resourceName: "Bkgd_3")
        case 2:
            backgroundView.image = #imageLiteral(resourceName: "Bkgd_2")
        case 1:
            backgroundView.image = #imageLiteral(resourceName: "Bkgd_1")
        default:
            backgroundView.image = #imageLiteral(resourceName: "Bkgd_4")
        }
        backgroundView.contentMode = .center
        self.addSubview(backgroundView)
        self.sendSubview(toBack: backgroundView)
    }
    
    private func addDetailContainerView(){
        let widthIncement = self.bounds.size.width/10
        let heightIncement = self.bounds.size.height/10

        let containerStackView = UIStackView(frame: CGRect(x: widthIncement * 0.8, y: ( 7 * heightIncement) , width: (widthIncement * 3.5), height: ( 2 * self.bounds.size.height / 12)))
        containerStackView.axis = .horizontal
        containerStackView.distribution = .fillEqually
        containerStackView.spacing = -15
        let leftStack = getSubContainerStack()
        leftStack.addArrangedSubview(addFrequencyImage())
        leftStack.addArrangedSubview(addWaterTempImage())
        leftStack.addArrangedSubview(addAirTempImage())

        let leftCenterStack = getSubContainerStack()
        leftCenterStack.addArrangedSubview(addFrequencyText())
        leftCenterStack.addArrangedSubview(addWaterTempText())
        leftCenterStack.addArrangedSubview(addAirTempText())
        
        containerStackView.addArrangedSubview(leftStack)
        containerStackView.addArrangedSubview(leftCenterStack)
        
        
        let secondContainerStackView = UIStackView(frame: CGRect(x: widthIncement * 5.3, y: ( 7 * heightIncement) , width: (widthIncement * 3.7), height: ( 2 * self.bounds.size.height / 12)))
        secondContainerStackView.axis = .horizontal
        secondContainerStackView.distribution = .fillEqually
        secondContainerStackView.spacing = -15

        let rightCenterStack = getSubContainerStack()
        rightCenterStack.addArrangedSubview(addHighTideImage())
        rightCenterStack.addArrangedSubview(addLowTideImage())
        rightCenterStack.addArrangedSubview(addWindImage())
        
        let rightStack = getSubContainerStack()
        rightStack.addArrangedSubview(addHighTideText())
        rightStack.addArrangedSubview(addLowTideText())
        rightStack.addArrangedSubview(addWindText())
        
        secondContainerStackView.addArrangedSubview(rightCenterStack)
        secondContainerStackView.addArrangedSubview(rightStack)

        self.addSubview(containerStackView)
        self.addSubview(secondContainerStackView)

    }
    
    func getSubContainerStack() -> UIStackView{
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 18
        return stack
    }
    
    func addWaveHeightIndicator(){
        
        let centerY = self.bounds.height / 2
        var waveHeightMaxFloat: CGFloat = 0
        waveHeightMaxFloat = CGFloat(self.currentSnapShot.waveHeight * 10)
        let waveTop = centerY - waveHeightMaxFloat - 14
        let waveHeightLabel = UILabel(frame: CGRect(x: 0, y: waveTop, width: 100, height: 20))
        waveHeightLabel.text = "__ \(self.currentSnapShot.waveHeight)ft"
        waveHeightLabel.font = UIFont(name:"Montserrat-SemiBold", size: 10.0)
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
        
        let widthPixels = 150 * waveHeightDigitCount + 200
        let distanceFromTop = self.frame.size.height/5
        let waveHeightLabel = UILabel(frame: CGRect(x: 0, y: 0, width: widthPixels, height: distanceFromTop))
        waveHeightLabel.text = "\(currentSnapShot.waveHeight)ft"
        waveHeightLabel.font = UIFont(name:"Avenir Next Condensed-Medium", size: 75.0)
        waveHeightLabel.textColor =  textColor
        waveHeightLabel.center = CGPoint(x: self.frame.width/2, y: 200)
        waveHeightLabel.textAlignment = .center
        self.addSubview(waveHeightLabel)
    }
    
    
    private func addSpotDetails(){
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        label.text = "10mi"
//        label.text = "\(currentSnapShot.) WIND \(currentSnapShot.windSpeed) \(windUnit)"
        label.font = UIFont(name:"Montserrat-Medium", size: 15.0)
        label.textColor =  textColor
        let yValue = 6 * self.frame.height/10 + 20
        label.center = CGPoint(x: self.frame.width/2, y:yValue)
        label.textAlignment = .center
        self.addSubview(label)
    }
    
    private func addSpotTitleLabel(){
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 200))
        titleLabel.text = currentSnapShot.nickname.isEmpty ? currentSnapShot.stationName : currentSnapShot.nickname
        titleLabel.font = UIFont(name:"Montserrat-Medium", size: 15.0)
        titleLabel.textColor =  #colorLiteral(red: 1, green: 0.9450980392, blue: 0.5058823529, alpha: 1)
        titleLabel.center = CGPoint(x: self.frame.width/2, y: 6 * self.frame.height/10)
        titleLabel.textAlignment = .center
        self.addSubview(titleLabel)
    }
    
    private func addFrequencyImage() -> UIView {
    let frequencyImageView = UIImageView(image: #imageLiteral(resourceName: "period"))
    frequencyImageView.frame.size = CGSize(width: 40, height: 40)
    frequencyImageView.contentMode = .scaleAspectFit
        return frequencyImageView
    }
    
    private func addFrequencyText() -> UIView {
        let frequencyAmountLabel = UILabel()
        frequencyAmountLabel.text = "\(currentSnapShot.period) sec"
        frequencyAmountLabel.textColor = textColor
        frequencyAmountLabel.font = UIFont(name:"Montserrat-SemiBold", size: 16.0)
        return frequencyAmountLabel
    }
    
    private func addAirTempImage() -> UIView {
        let airTempImageView = UIImageView(image: #imageLiteral(resourceName: "wind_temp"))
        airTempImageView.contentMode = .scaleAspectFit
        airTempImageView.frame.size = CGSize(width: 40, height: 40)
        return airTempImageView
    }
    
    private func addAirTempText() -> UIView {
        let airTempLabel = UILabel()
        airTempLabel.text = "Loading..."
        airTempLabel.text = "\(currentSnapShot.airTemp)° F"
        airTempLabel.textColor = textColor
        airTempLabel.font = UIFont(name:"Montserrat-SemiBold", size: 16.0)
        return airTempLabel
    }
    
    private func addWaterTempImage() -> UIView {
        let waterImageView = UIImageView(image: #imageLiteral(resourceName: "water_temp"))
        waterImageView.contentMode = .scaleAspectFit
        waterImageView.frame.size = CGSize(width: 40, height: 40)
        return waterImageView
    }
    
    private func addWaterTempText() -> UIView {
        let waterTempLabel = UILabel()
        waterTempLabel.text = "\(currentSnapShot.waterTemp)° F"
        waterTempLabel.textColor = textColor
        waterTempLabel.font = UIFont(name:"Montserrat-SemiBold", size: 16.0)
        return waterTempLabel
    }
    
    private func addHighTideImage() -> UIView {
        let tideImageView = UIImageView(image: #imageLiteral(resourceName: "high_tide"))
        tideImageView.contentMode = .scaleAspectFit
        return tideImageView
    }
    
    private func addHighTideText() -> UIView {
        let tideDirectionLabel = UILabel()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        let time = dateFormatter.string(from: currentSnapShot.nextHighTide)
        tideDirectionLabel.text = "\(time)"
        tideDirectionLabel.font = UIFont(name:"Montserrat-SemiBold", size: 16.0)
        tideDirectionLabel.textColor = textColor
        return tideDirectionLabel
    }
    
    private func addLowTideImage() -> UIView {
        let tideImageView = UIImageView(image: #imageLiteral(resourceName: "low_tide"))
        tideImageView.contentMode = .scaleAspectFit
        return tideImageView
    }
    
    private func addLowTideText() -> UIView {
        let tideDirectionLabel = UILabel()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        let time = dateFormatter.string(from: currentSnapShot.nextLowTide)
        tideDirectionLabel.text = "\(time)"
        tideDirectionLabel.font = UIFont(name:"Montserrat-SemiBold", size: 16.0)
        tideDirectionLabel.textColor = textColor
        return tideDirectionLabel
    }

    private func addWindImage() -> UIView {
        let waterImageView = UIImageView(image: #imageLiteral(resourceName: "wind_direction"))
        waterImageView.contentMode = .scaleAspectFit
        waterImageView.frame.size = CGSize(width: 40, height: 40)
        return waterImageView
    }
    
    private func addWindText() -> UIView {
        let waterTempLabel = UILabel()
//        waterTempLabel.text = "\(currentSnapShot.windDirectionString) @ \(currentSnapShot.windSpeed)"
        waterTempLabel.text = "\(currentSnapShot.windDirectionString)"
        waterTempLabel.font = UIFont(name:"Montserrat-SemiBold", size: 16.0)
        waterTempLabel.textColor = textColor
        return waterTempLabel
    }
    
}
