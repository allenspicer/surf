//
//  FavCollectionViewCell.swift
//  surf
//
//  Created by Allen Spicer on 6/6/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit
import Foundation

class FavCollectionViewCell: UIView {
    
    private var mainView = UIView()
    private var gradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadAllViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadAllViews() {

            var distanceLabel: UILabel

            self.contentMode = .center
            
            let mainViewFrame = CGRect(x: 0.0, y: 0.0, width: 207.0, height: 207.0)
            mainView = UIView(frame: mainViewFrame)
            mainView.layer.cornerRadius = 103
            mainView.layer.masksToBounds = true
            mainView.layer.borderWidth = 4
            mainView.layer.borderColor = #colorLiteral(red: 0.3529411765, green: 0.9882352941, blue: 0.5725490196, alpha: 1)

            let distanceLabelFrame = CGRect(x: 0.0, y: self.frame.height - 20, width: self.frame.width, height: 20.0)
            distanceLabel = UILabel(frame: distanceLabelFrame)
            distanceLabel.backgroundColor = .clear
            distanceLabel.textColor = #colorLiteral(red: 1, green: 0.9450980392, blue: 0.5058823529, alpha: 1)
            distanceLabel.textAlignment = .center
            distanceLabel.font = distanceLabel.font.withSize(15)
            distanceLabel.tag = 1
            self.addSubview(distanceLabel)
            distanceLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
            distanceLabel.text = "10mi"
        }
    
    func setGradientColors(firstColor : UIColor, secondColor : UIColor){
        mainView.backgroundColor = firstColor
        gradientLayer.frame = mainView.frame
        gradientLayer.colors = [secondColor.cgColor, UIColor.clear.cgColor]
        mainView.layer.addSublayer(gradientLayer)
        self.addSubview(mainView)
    }

}
