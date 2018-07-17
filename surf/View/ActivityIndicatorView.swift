//
//  activityIndicatorView.swift
//  surf
//
//  Created by Allen Spicer on 5/31/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit

class ActivityIndicatorView: UIView {
    
    func setupActivityIndicator(view: UIView, widthView: CGFloat?,backgroundColor: UIColor?, textColor:UIColor?, message: String?) -> ActivityIndicatorView{
        //Config UIView
        let customBlue = #colorLiteral(red: 0.01568627451, green: 0.6509803922, blue: 0.6509803922, alpha: 1)
        self.backgroundColor = customBlue //Background color of your view which you want to set
        var selfWidth = view.frame.width
        if widthView != nil{
            selfWidth = widthView ?? selfWidth
        }
        
        let selfHeight = view.frame.height
        let loopImages = UIImageView()
        
        let imageListArray = [#imageLiteral(resourceName: "Flat_Loading"),#imageLiteral(resourceName: "Bump_loading"),#imageLiteral(resourceName: "LittleWave_loading"),#imageLiteral(resourceName: "Wave_loading"),#imageLiteral(resourceName: "BigWave_Loading")] // Put your desired array of images in a specific order the way you want to display animation.
        
        loopImages.animationImages = imageListArray
        loopImages.animationDuration = TimeInterval(0.9)
        loopImages.startAnimating()
        
        let imageFrameX = (selfWidth / 2) - 30
        let imageFrameY = (selfHeight / 2) - 60
        var imageWidth = CGFloat(60)
        var imageHeight = CGFloat(60)
        
        if widthView != nil{
            imageWidth = widthView ?? imageWidth
            imageHeight = widthView ?? imageHeight
        }
        
        //ConfigureLabel
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .gray
        //        label.font = UIFont(name: "SFUIDisplay-Regular", size: 17.0)! // Your Desired UIFont Style and Size
        label.numberOfLines = 0
        //        label.text = message ?? ""
        //        label.textColor = textColor ?? UIColor.clear
        
        //Config frame of label
        let labelFrameX = (selfWidth / 2) - 100
        let labelFrameY = (selfHeight / 2) - 10
        let labelWidth = CGFloat(200)
        let labelHeight = CGFloat(70)
        
        self.frame = view.frame
        
        //ImageFrame
        loopImages.frame = CGRect(x: imageFrameX, y: imageFrameY, width: imageWidth, height: imageHeight)
        
        //LabelFrame
        label.frame = CGRect(x: labelFrameX, y: labelFrameY, width: labelWidth, height: labelHeight)
        
        //add loading and label to customView
        self.addSubview(loopImages)
        self.addSubview(label)
        
        let gradientView = GradientView(frame: self.frame)
        gradientView.firstColor = #colorLiteral(red: 0.01568627451, green: 0.6509803922, blue: 0.6509803922, alpha: 1)
        gradientView.secondColor = #colorLiteral(red: 0.01960784314, green: 0.01960784314, blue: 0.05098039216, alpha: 1)
        self.addSubview(gradientView)
        self.sendSubview(toBack: gradientView)
        
        return self
    }
}
