//
//  CircleView.swift
//  surf
//
//  Created by Allen Spicer on 7/18/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit

class CircleView: UIView {
    
    var circle = UIView()
    var isAnimating = false
    let gradientLayer:CAGradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        resetCircle()
        addSubview(circle)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func resetCircle() {
        
        var rectSide: CGFloat = 0
        if (frame.size.width > frame.size.height) {
            rectSide = frame.size.height
        } else {
            rectSide = frame.size.width
        }
        
        let circleRect = CGRect(x: (frame.size.width-rectSide)/2, y: (frame.size.height-rectSide)/2, width: rectSide, height: rectSide)
        circle = UIView(frame: circleRect)
        circle.backgroundColor = #colorLiteral(red: 0.01176470588, green: 0.5294117647, blue: 0.5294117647, alpha: 1)
        circle.layer.cornerRadius = rectSide/2
        circle.layer.borderWidth = 4
        circle.layer.borderColor = #colorLiteral(red: 0.3529411765, green: 0.9882352941, blue: 0.5725490196, alpha: 1)
        
        gradientLayer.frame.size = circle.frame.size
        let customYellow = #colorLiteral(red: 0.8666666667, green: 0.7529411765, blue: 0.1333333333, alpha: 1)
        gradientLayer.colors = [customYellow.cgColor, UIColor.clear.cgColor]
        circle.layer.addSublayer(gradientLayer)
        circle.layer.masksToBounds = true
        
    }
    
    func resizeCircle (summand: CGFloat) {
        
        frame.origin.x -= summand/2
        frame.origin.y -= summand/2
        
        frame.size.height += summand
        frame.size.width += summand
        
        circle.frame.size.height += summand
        circle.frame.size.width += summand
        
        gradientLayer.frame.size = circle.frame.size
    }
    
    func animateChangingCornerRadius (toValue: Any?, duration: TimeInterval) {
        
        let animation = CABasicAnimation(keyPath:"cornerRadius")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.fromValue = circle.layer.cornerRadius
        animation.toValue =  toValue
        animation.duration = duration
        circle.layer.cornerRadius = self.circle.frame.size.width/2
        circle.layer.add(animation, forKey:"cornerRadius")
    }
    
    
    func growCircleTo(_ summand: CGFloat, duration: TimeInterval, completionBlock:@escaping ()->()) {
        
        UIView.animate(withDuration: duration, delay: 0,  options: .curveEaseInOut, animations: {
            self.resizeCircle(summand: summand)
        }) { _ in
            completionBlock()
        }
        animateChangingCornerRadius(toValue: circle.frame.size.width/2, duration: duration)
        
    }
    
}
