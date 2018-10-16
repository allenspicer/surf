//
//  FavCollectionViewCell.swift
//  surf
//
//  Created by Allen Spicer on 6/6/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit
import Foundation

class PlaceholderFavCollectionViewCell: UICollectionViewCell {
    
    private let mainTextColor = #colorLiteral(red: 0.8862745098, green: 0.8862745098, blue: 0.8862745098, alpha: 1)
    private let secondaryTextColor = #colorLiteral(red: 1, green: 0.9450980392, blue: 0.5058823529, alpha: 1)
    private let borderColor = #colorLiteral(red: 1, green: 0.9803921569, blue: 0.8196078431, alpha: 1)

    private var width : CGFloat = 210.0
    private var centerX = CGFloat()

    
    override func awakeFromNib() {
        centerX = self.contentView.center.x
        super.awakeFromNib()
        renderAllCellDetail()
    }
    
    func renderAllCellDetail(){
        self.addSubview(textView())
        self.addSubview(middleLabel())
        self.addSubview(bottomLabel())
        self.addSubview(favoriteImage())
        self.addSubview(backgroundWithBorder())
    }
    
    private func backgroundWithBorder() -> UIView{
        let view = UIView(frame: CGRect(x: 5, y: 0, width: 200, height: 200))
        view.layer.borderColor = borderColor.cgColor
        view.layer.borderWidth = 3.0
        view.layer.cornerRadius = 100
        return view
    }
    
    private func favoriteImage() -> UIView {
        let waterImageView = UIImageView(image: #imageLiteral(resourceName: "NonFavorite"))
        waterImageView.contentMode = .scaleAspectFit
        waterImageView.frame = CGRect(x: centerX - 21.0, y: 20, width: 42, height: 42)
        return waterImageView
    }
    
    private func textView() -> UIView {
        let textView = UIView(frame: CGRect(x: 0, y: 80, width: width, height: 24))
        textView.backgroundColor = .clear
        let firstLabel = UILabel()
        firstLabel.text = "MARK YOUR"
        firstLabel.font = UIFont(name:"Montserrat-BoldItalic", size: 9.0)
        firstLabel.textColor = mainTextColor
        firstLabel.textAlignment = .center
        firstLabel.frame = CGRect(x: 0, y: 0, width: width, height: 12)
        textView.addSubview(firstLabel)
        firstLabel.addCharacterSpacing()
        let secondLabel = UILabel()
        secondLabel.text = "GO-TO SURF SPOTS AS"
        secondLabel.font = UIFont(name:"Montserrat-BoldItalic", size: 9.0)
        secondLabel.textColor = mainTextColor
        secondLabel.textAlignment = .center
        secondLabel.frame = CGRect(x: 0, y: 12, width: width, height: 12)
        textView.addSubview(secondLabel)
        secondLabel.addCharacterSpacing()
        return textView
    }
    
    private func middleLabel() -> UILabel {
        let middleLabel = UILabel()
        middleLabel.text = "FAVORITES"
        middleLabel.font = UIFont(name:"Teko-Light", size: 28.0)
        middleLabel.textColor = secondaryTextColor
        middleLabel.textAlignment = .center
        middleLabel.frame = CGRect(x: 0, y: 111, width: width, height: 30)
        return middleLabel
    }
    
    private func bottomLabel() -> UILabel {
        let bottomLabel = UILabel()
        bottomLabel.text = "TO SEE THEM HERE"
        bottomLabel.font = UIFont(name:"Montserrat-BoldItalic", size: 9.0)
        bottomLabel.textColor = mainTextColor
        bottomLabel.textAlignment = .center
        bottomLabel.frame = CGRect(x: 0, y: 118, width: width, height: 60)
        bottomLabel.addCharacterSpacing()
        return bottomLabel
    }

    
}
