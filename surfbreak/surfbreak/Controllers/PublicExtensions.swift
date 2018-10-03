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


extension UILabel {
    func addCharacterSpacing(kernValue: Double = 2.0) {
        if let labelText = text, labelText.count > 0 {
            let attributedString = NSMutableAttributedString(string: labelText)
            attributedString.addAttribute(NSAttributedStringKey.kern, value: kernValue, range: NSRange(location: 0, length: attributedString.length - 1))
            attributedText = attributedString
        }
    }
}
