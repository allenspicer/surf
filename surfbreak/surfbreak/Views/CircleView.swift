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
    var snapshot = Snapshot()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setAndAssign(){
        resetCircle()
        addSubview(circle)
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
        circle.backgroundColor = .clear
        circle.layer.cornerRadius = rectSide/2
        circle.layer.borderWidth = 2
        circle.layer.borderColor = #colorLiteral(red: 1, green: 0.9803921569, blue: 0.8196078431, alpha: 1)
        
        switch snapshot.quality{
        case 4:
            self.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "Lrg_Bkgds_Poor"))
        case 3:
            self.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "Lrg_Bkgd_Fair"))
        case 2:
            self.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "Lrg_Bkgd_Good"))
        case 1:
            self.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "Lrg_Bkgd_Ideal"))
        default:
            self.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "Lrg_Bkgds_Poor"))
        }
        self.layer.cornerRadius = self.frame.height/2
        self.clipsToBounds = true
    }
    
    func resizeCircle (summand: CGFloat) {
        frame.origin.x -= summand/2
        frame.origin.y -= summand/2
        
        frame.size.height += summand
        frame.size.width += summand
        
        circle.frame.size.height += summand
        circle.frame.size.width += summand
        
        frame.origin.y = frame.origin.y + 150
        self.frame.size = circle.frame.size
        self.layer.cornerRadius = self.frame.height/2
        
    }
    
    func animateChangingCornerRadius (toValue: Any?, duration: TimeInterval) {
        let animation = CABasicAnimation(keyPath:"cornerRadius")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
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
