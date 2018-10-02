//
//  PublicExtensions.swift
//  surfbreak
//
//  Created by Allen Spicer on 8/10/18.
//  Copyright © 2018 surfbreak. All rights reserved.
//

import Foundation
import UIKit


public extension Sequence where Element: Equatable {
    var uniqueElements: [Element] {
        return self.reduce(into: []) {
            uniqueElements, element in
            
            if !uniqueElements.contains(element) {
                uniqueElements.append(element)
            }
        }
    }
}



extension UIApplication {
    
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
