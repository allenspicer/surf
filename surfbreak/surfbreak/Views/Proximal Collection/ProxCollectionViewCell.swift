//
//  ProxCollectionViewCell.swift
//  surf
//
//  Created by Allen Spicer on 6/6/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit

class ProxCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = 15
        self.layer.masksToBounds = true
        titleLabel.textColor = #colorLiteral(red: 0.6156862745, green: 0.9019607843, blue: 0.9019607843, alpha: 1)
        distanceLabel.textColor = #colorLiteral(red: 0.8862745098, green: 0.8862745098, blue: 0.8862745098, alpha: 1)
        self.contentView.layer.borderWidth = 2
        self.contentView.layer.borderColor = #colorLiteral(red: 0.1568627451, green: 0.2549019608, blue: 0.4352941176, alpha: 1)
        self.contentView.layer.cornerRadius = 15
        
        let backgroundView = UIImageView(frame: self.frame)
        backgroundView.image = #imageLiteral(resourceName: "nonfave_tile")
        backgroundView.contentMode = .center
        self.addSubview(backgroundView)
        self.sendSubview(toBack: backgroundView)

    }
    
    
}