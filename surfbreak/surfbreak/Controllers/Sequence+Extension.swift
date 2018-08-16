//
//  Sequence+Extension.swift
//  surfbreak
//
//  Created by Allen Spicer on 8/10/18.
//  Copyright © 2018 surfbreak. All rights reserved.
//

import Foundation

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
