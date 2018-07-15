//
//  FavCollectionViewCell.swift
//  surf
//
//  Created by Allen Spicer on 6/6/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit
import Foundation

class FavCollectionViewCell: UICollectionViewCell {
    
    var backgroundGradient = CAGradientLayer()
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func loadAllViews(waveHeight: Double, waveFrequency: Double, locationName: String, distanceFromUser: Double) {

            var mainView: UIView
            var heightLabel: UILabel
            var frequencyLabel: UILabel
            var locationLabel: UILabel
            var distanceLabel: UILabel

            self.contentMode = .center
            
            let mainViewFrame = CGRect(x: 0.0, y: 0.0, width: 207.0, height: 207.0)
            mainView = UIView(frame: mainViewFrame)
            mainView.layer.cornerRadius = 103
            mainView.layer.masksToBounds = true
            mainView.layer.borderWidth = 4
            mainView.layer.borderColor = #colorLiteral(red: 0.3529411765, green: 0.9882352941, blue: 0.5725490196, alpha: 1)
            mainView.backgroundColor = #colorLiteral(red: 0.01176470588, green: 0.5294117647, blue: 0.5294117647, alpha: 1)
        
            let gradientLayer:CAGradientLayer = CAGradientLayer()
            gradientLayer.frame.size = mainViewFrame.size
            let customYellow = #colorLiteral(red: 0.8666666667, green: 0.7529411765, blue: 0.1333333333, alpha: 1)
            gradientLayer.colors = [customYellow.cgColor, UIColor.clear.cgColor]
            mainView.layer.addSublayer(gradientLayer)
            self.addSubview(mainView)
        
        
            let heightLabelFrame = CGRect(x: 0.0, y: 24.0, width: self.frame.width, height: 80.0)
            heightLabel = UILabel(frame: heightLabelFrame)
            heightLabel.backgroundColor = .clear
            heightLabel.textColor = #colorLiteral(red: 0.9803921569, green: 0.9803921569, blue: 0.9803921569, alpha: 1)
            heightLabel.textAlignment = .center
            heightLabel.font = UIFont(name: "Avenir Next Condensed", size: 58)
            self.addSubview(heightLabel)
            heightLabel.text = "\(waveHeight) ft"
        
            let frequencyLabelFrame = CGRect(x: 0.0, y: mainViewFrame.height * 0.75, width: self.frame.width, height: 18.0)
            frequencyLabel = UILabel(frame: frequencyLabelFrame)
            frequencyLabel.backgroundColor = .clear
            frequencyLabel.textColor = #colorLiteral(red: 0.9803921569, green: 0.9803921569, blue: 0.9803921569, alpha: 1)
            frequencyLabel.textAlignment = .center
            frequencyLabel.font = UIFont(name: "Gotham", size: 18)
            self.addSubview(frequencyLabel)
            frequencyLabel.text = "\(waveFrequency)sec"
        
            let locationLabelFrame = CGRect(x: 0.0, y: self.frame.height - 40, width: self.frame.width, height: 20.0)
            locationLabel = UILabel(frame: locationLabelFrame)
            locationLabel.backgroundColor = .clear
            locationLabel.textColor = #colorLiteral(red: 1, green: 0.9450980392, blue: 0.5058823529, alpha: 1)
            locationLabel.textAlignment = .center
            locationLabel.font = UIFont(name: "AdobeHeitiStd-Regular", size: 15)
            self.addSubview(locationLabel)
            locationLabel.text = locationName

            let distanceLabelFrame = CGRect(x: 0.0, y: self.frame.height - 20, width: self.frame.width, height: 20.0)
            distanceLabel = UILabel(frame: distanceLabelFrame)
            distanceLabel.backgroundColor = .clear
            distanceLabel.textColor = #colorLiteral(red: 1, green: 0.9450980392, blue: 0.5058823529, alpha: 1)
            distanceLabel.textAlignment = .center
            distanceLabel.font = UIFont(name: "AdobeHeitiStd-Regular", size: 15)
            distanceLabel.tag = 1
            self.addSubview(distanceLabel)
            distanceLabel.text = "\(distanceFromUser)mi"

        }

}
