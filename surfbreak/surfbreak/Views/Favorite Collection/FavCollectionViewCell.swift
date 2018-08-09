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
    
    var mainView = UIView()
    var heightLabel = UILabel()
    var frequencyLabel = UILabel()
    var locationLabel = UILabel()
    var distanceLabel = UILabel()
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setCellContent(waveHeight: Double, waveFrequency: Double, quality: Int, locationName: String, distanceFromUser: Double){
        heightLabel.text = "\(waveHeight) ft"
        frequencyLabel.text = "\(waveFrequency)s"
        locationLabel.text = locationName
        distanceLabel.text = "\(distanceFromUser)mi"
        
        switch waveHeight{
        case ...0.5:
            imageView.image = #imageLiteral(resourceName: "Flat")
        case 0.5...1.0:
            imageView.image = #imageLiteral(resourceName: "Bump")
        case 1.0...3.0:
            imageView.image = #imageLiteral(resourceName: "littlewave")
        case 3.0...6.0:
            imageView.image = #imageLiteral(resourceName: "wave")
        case 6.0...:
            imageView.image = #imageLiteral(resourceName: "bigwave")
        default:
            imageView.image = #imageLiteral(resourceName: "Flat")
        }
        
        switch quality{
        case 4:
            backgroundImageView.image = #imageLiteral(resourceName: "Bkgd_4")
        case 3:
            backgroundImageView.image = #imageLiteral(resourceName: "Bkgd_3")
        case 2:
            backgroundImageView.image = #imageLiteral(resourceName: "Bkgd_2")
        case 1:
            backgroundImageView.image = #imageLiteral(resourceName: "Bkgd_1")
        default:
            backgroundImageView.image = #imageLiteral(resourceName: "Bkgd_4")
        }

        
    }
    
    func loadAllViews() {
        
        if contentView.subviews.contains(mainView){return}
        
        self.contentMode = .center
        let mainViewFrame = CGRect(x: 0.0, y: 0.0, width: 206.0, height: 206.0)
        mainView = CustomView(frame: mainViewFrame)
        backgroundImageView.frame = mainViewFrame
        backgroundImageView.layer.cornerRadius = 103
        backgroundImageView.layer.masksToBounds = true
        contentView.addSubview(mainView)
        
        
        let heightLabelFrame = CGRect(x: 0.0, y: contentView.frame.height * 0.06, width: contentView.frame.width, height: 80.0)
        heightLabel = UILabel(frame: heightLabelFrame)
        heightLabel.backgroundColor = .clear
        heightLabel.textColor = #colorLiteral(red: 0.9803921569, green: 0.9803921569, blue: 0.9803921569, alpha: 1)
        heightLabel.textAlignment = .center
        heightLabel.font = UIFont(name: "Avenir Next Condensed", size: 58)
        contentView.addSubview(heightLabel)
        
        let frequencyLabelFrame = CGRect(x: 0, y: contentView.frame.height * 0.50, width: contentView.frame.width - 30.0, height: 18.0)
        frequencyLabel = UILabel(frame: frequencyLabelFrame)
        frequencyLabel.backgroundColor = .clear
        frequencyLabel.textColor = #colorLiteral(red: 0.9803921569, green: 0.9803921569, blue: 0.9803921569, alpha: 1)
        frequencyLabel.textAlignment = .right
        frequencyLabel.font = UIFont(name: "Gotham", size: 18)
        contentView.addSubview(frequencyLabel)
        
        let locationLabelFrame = CGRect(x: 0.0, y: contentView.frame.height - 40, width: contentView.frame.width, height: 20.0)
        locationLabel = UILabel(frame: locationLabelFrame)
        locationLabel.backgroundColor = .clear
        locationLabel.textColor = #colorLiteral(red: 1, green: 0.9450980392, blue: 0.5058823529, alpha: 1)
        locationLabel.textAlignment = .center
        locationLabel.font = UIFont(name: "Montserrat-SemiBold", size: 15)
        contentView.addSubview(locationLabel)
        
        let distanceLabelFrame = CGRect(x: 0.0, y: contentView.frame.height - 20, width: contentView.frame.width, height: 20.0)
        distanceLabel = UILabel(frame: distanceLabelFrame)
        distanceLabel.backgroundColor = .clear
        distanceLabel.textColor = #colorLiteral(red: 1, green: 0.9450980392, blue: 0.5058823529, alpha: 1)
        distanceLabel.textAlignment = .center
        distanceLabel.font = UIFont(name: "Montserrat-SemiBold", size: 15)
        distanceLabel.tag = 1
        contentView.addSubview(distanceLabel)
        
        contentView.addSubview(imageView)
        
    }
    
}
