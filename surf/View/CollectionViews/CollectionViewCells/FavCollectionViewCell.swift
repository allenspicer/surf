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
    var mainView = UIView()
    var heightLabel = UILabel()
    var frequencyLabel = UILabel()
    var locationLabel = UILabel()
    var distanceLabel = UILabel()
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setCellContent(waveHeight: Double, waveFrequency: Double, locationName: String, distanceFromUser: Double){
        heightLabel.text = "\(waveHeight) ft"
        frequencyLabel.text = "\(waveFrequency)sec"
        locationLabel.text = locationName
        distanceLabel.text = "\(distanceFromUser)mi"
        
        switch waveHeight{
        case ...0.5:
            imageView.image = #imageLiteral(resourceName: "Mini_Flat")
        case 0.5...1.0:
            imageView.image = #imageLiteral(resourceName: "Bump")
        case 1.0...3.0:
            imageView.image = #imageLiteral(resourceName: "Mini_littlewave")
        case 3.0...6.0:
            imageView.image = #imageLiteral(resourceName: "wave")
        case 6.0...:
            imageView.image = #imageLiteral(resourceName: "Mini_bigwave")
        default:
            imageView.image = #imageLiteral(resourceName: "Mini_Flat")
        }
        
        switch waveFrequency{
        case ...2:
            let customYellow = #colorLiteral(red: 0.8666666667, green: 0.7529411765, blue: 0.1333333333, alpha: 1)
            backgroundGradient.colors = [customYellow.cgColor, UIColor.clear.cgColor]
        case 2...4:
            let customYellow = #colorLiteral(red: 0.8666666667, green: 0.7529411765, blue: 0.1333333333, alpha: 1)
            backgroundGradient.colors = [customYellow.cgColor, UIColor.clear.cgColor]
        case 4...6:
            let customYellow = #colorLiteral(red: 0.8666666667, green: 0.7529411765, blue: 0.1333333333, alpha: 1)
            backgroundGradient.colors = [customYellow.cgColor, UIColor.clear.cgColor]
        case 6...9:
            let customYellow = #colorLiteral(red: 0.8666666667, green: 0.7529411765, blue: 0.1333333333, alpha: 1)
            backgroundGradient.colors = [customYellow.cgColor, UIColor.clear.cgColor]
        case 9...:
            let customYellow = #colorLiteral(red: 0.8666666667, green: 0.7529411765, blue: 0.1333333333, alpha: 1)
            backgroundGradient.colors = [customYellow.cgColor, UIColor.clear.cgColor]
        default:
            let customYellow = #colorLiteral(red: 0.8666666667, green: 0.7529411765, blue: 0.1333333333, alpha: 1)
            backgroundGradient.colors = [customYellow.cgColor, UIColor.clear.cgColor]
        }
        
        
        
        
    }

    func loadAllViews() {
        
            self.contentMode = .center
            let mainViewFrame = CGRect(x: 0.0, y: 0.0, width: 207.0, height: 207.0)
            mainView = CustomView(frame: mainViewFrame)
            mainView.layer.cornerRadius = 103
            mainView.layer.masksToBounds = true
            mainView.backgroundColor = #colorLiteral(red: 0.01176470588, green: 0.5294117647, blue: 0.5294117647, alpha: 1)
        
            backgroundGradient.frame.size = mainViewFrame.size
            mainView.layer.addSublayer(backgroundGradient)
            self.addSubview(mainView)
        
            self.addSubview(imageView)

        
            let heightLabelFrame = CGRect(x: 0.0, y: 24.0, width: self.frame.width, height: 80.0)
            heightLabel = UILabel(frame: heightLabelFrame)
            heightLabel.backgroundColor = .clear
            heightLabel.textColor = #colorLiteral(red: 0.9803921569, green: 0.9803921569, blue: 0.9803921569, alpha: 1)
            heightLabel.textAlignment = .center
            heightLabel.font = UIFont(name: "Avenir Next Condensed", size: 58)
            self.addSubview(heightLabel)
        
            let frequencyLabelFrame = CGRect(x: 0.0, y: mainViewFrame.height * 0.75, width: self.frame.width, height: 18.0)
            frequencyLabel = UILabel(frame: frequencyLabelFrame)
            frequencyLabel.backgroundColor = .clear
            frequencyLabel.textColor = #colorLiteral(red: 0.9803921569, green: 0.9803921569, blue: 0.9803921569, alpha: 1)
            frequencyLabel.textAlignment = .center
            frequencyLabel.font = UIFont(name: "Gotham", size: 18)
            self.addSubview(frequencyLabel)
        
            let locationLabelFrame = CGRect(x: 0.0, y: self.frame.height - 40, width: self.frame.width, height: 20.0)
            locationLabel = UILabel(frame: locationLabelFrame)
            locationLabel.backgroundColor = .clear
            locationLabel.textColor = #colorLiteral(red: 1, green: 0.9450980392, blue: 0.5058823529, alpha: 1)
            locationLabel.textAlignment = .center
            locationLabel.font = UIFont(name: "AdobeHeitiStd-Regular", size: 15)
            self.addSubview(locationLabel)

            let distanceLabelFrame = CGRect(x: 0.0, y: self.frame.height - 20, width: self.frame.width, height: 20.0)
            distanceLabel = UILabel(frame: distanceLabelFrame)
            distanceLabel.backgroundColor = .clear
            distanceLabel.textColor = #colorLiteral(red: 1, green: 0.9450980392, blue: 0.5058823529, alpha: 1)
            distanceLabel.textAlignment = .center
            distanceLabel.font = UIFont(name: "AdobeHeitiStd-Regular", size: 15)
            distanceLabel.tag = 1
            self.addSubview(distanceLabel)

        }

}
