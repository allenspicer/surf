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
    
    func setCellContent(waveHeight: Double, waveFrequency: Double, quality: Int, locationName: String, distanceFromUser: Int){

        heightLabel.text = "\(Int(waveHeight.rounded())) ft"
        heightLabel.addCharacterSpacing()
        frequencyLabel.text = "\(Int(waveFrequency.rounded()))s"
        locationLabel.text = locationName.uppercased()
        locationLabel.addCharacterSpacing(kernValue: 1.50)
        distanceLabel.text = distanceFromUser == 0 ? "Unknown Distance" : "\(distanceFromUser)mi"
        
        switch waveHeight{
        case ...0.5:
            imageView.image = #imageLiteral(resourceName: "flat_2pt_200px")
        case 0.5...1.0:
            imageView.image = #imageLiteral(resourceName: "bump_2pt_200px")
        case 1.0...3.0:
            imageView.image = #imageLiteral(resourceName: "littlewave_2pt_200px")
        case 3.0...6.0:
            imageView.image = #imageLiteral(resourceName: "wave_2pt_200px")
        case 6.0...:
            imageView.image = #imageLiteral(resourceName: "bigwave_2pt_200px")
        default:
            imageView.image = #imageLiteral(resourceName: "littlewave_2pt_200px")
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
        mainView = UIView(frame: mainViewFrame)
        backgroundImageView.frame = mainViewFrame
        backgroundImageView.layer.cornerRadius = 103
        backgroundImageView.layer.masksToBounds = true
        contentView.addSubview(mainView)
        
        
        let heightLabelFrame = CGRect(x: 0.0, y: 0.0, width: contentView.frame.width, height: 121.0)
        heightLabel = UILabel(frame: heightLabelFrame)
        heightLabel.backgroundColor = .clear
        heightLabel.textColor = #colorLiteral(red: 0.9803921569, green: 0.9803921569, blue: 0.9803921569, alpha: 1)
        heightLabel.textAlignment = .center
        heightLabel.font = UIFont(name: "Teko-Light", size: 85)
        contentView.addSubview(heightLabel)
        
        let frequencyLabelFrame = CGRect(x: 0, y: contentView.frame.height * 0.50, width: contentView.frame.width - 30.0, height: 18.0)
        frequencyLabel = UILabel(frame: frequencyLabelFrame)
        frequencyLabel.backgroundColor = .clear
        frequencyLabel.textColor = #colorLiteral(red: 0.9803921569, green: 0.9803921569, blue: 0.9803921569, alpha: 1)
        frequencyLabel.textAlignment = .right
        frequencyLabel.font = UIFont(name: "Montserrat-SemiBold", size: 18)
        contentView.addSubview(frequencyLabel)
        
        let locationLabelFrame = CGRect(x: 0.0, y: contentView.frame.height - 40, width: contentView.frame.width, height: 20.0)
        locationLabel = UILabel(frame: locationLabelFrame)
        locationLabel.backgroundColor = .clear
        locationLabel.textColor = #colorLiteral(red: 1, green: 0.9450980392, blue: 0.5058823529, alpha: 1)
        locationLabel.textAlignment = .center
        locationLabel.font = UIFont(name: "Teko-Regular", size: 25)
        contentView.addSubview(locationLabel)
        
        let distanceLabelFrame = CGRect(x: 0.0, y: contentView.frame.height - 20, width: contentView.frame.width, height: 20.0)
        distanceLabel = UILabel(frame: distanceLabelFrame)
        distanceLabel.backgroundColor = .clear
        distanceLabel.textColor = #colorLiteral(red: 0.8862745098, green: 0.8862745098, blue: 0.8862745098, alpha: 1)
        distanceLabel.textAlignment = .center
        distanceLabel.font = UIFont(name: "Montserrat-MediumItalic", size: 16)
        distanceLabel.tag = 1
        contentView.addSubview(distanceLabel)
        
        contentView.addSubview(imageView)
        
    }
    
}
