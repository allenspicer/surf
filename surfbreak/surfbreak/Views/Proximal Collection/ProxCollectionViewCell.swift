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
    
        self.layer.cornerRadius = 4
        self.layer.masksToBounds = true
        titleLabel.textColor = #colorLiteral(red: 0.6156862745, green: 0.9019607843, blue: 0.9019607843, alpha: 1)
        titleLabel.font = UIFont(name: "Teko-Light", size: 18)
        titleLabel.textAlignment = .left
        distanceLabel.textColor = #colorLiteral(red: 0.8862745098, green: 0.8862745098, blue: 0.8862745098, alpha: 1)
        distanceLabel.font = UIFont(name: "Montserrat-MediumItalic", size: 11)
        distanceLabel.textAlignment = .left
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.borderColor = #colorLiteral(red: 0.1568627451, green: 0.2549019608, blue: 0.4352941176, alpha: 1)
        self.contentView.layer.cornerRadius = 15
        self.backgroundColor = #colorLiteral(red: 0.0862745098, green: 0.0862745098, blue: 0.1490196078, alpha: 1)
    }
}
