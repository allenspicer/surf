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
        var backgroundGradient = CAGradientLayer()

    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = 15
        self.layer.masksToBounds = true
        titleLabel.textColor = .white
        self.contentView.layer.borderWidth = 2
        self.contentView.layer.borderColor = #colorLiteral(red: 0.5058823529, green: 1, blue: 0.8274509804, alpha: 1)
        self.contentView.layer.cornerRadius = 15
        backgroundGradient = CAGradientLayer()
        let customBlack = #colorLiteral(red: 0.06274509804, green: 0.05098039216, blue: 0.1490196078, alpha: 1)
        backgroundGradient.colors = [UIColor.clear.cgColor, customBlack.cgColor]

        self.layer.insertSublayer(backgroundGradient, at: 0)
    }
    

}
