//
//  PublicEnums.swift
//  surfbreak
//
//  Created by Allen Spicer on 10/11/18.
//  Copyright © 2018 surfbreak. All rights reserved.
//

import Foundation
import UIKit

public enum Coastline {
    case cb, duck, ei, hat, mase, sc, va, wb
    var image : UIImage {
        switch self {
        case .cb: return #imageLiteral(resourceName: "CarolinaBeach")
        case .duck: return #imageLiteral(resourceName: "Duck")
        case .ei: return #imageLiteral(resourceName: "EmeraldIsle")
        case .hat: return #imageLiteral(resourceName: "Hatteras")
        case .mase: return #imageLiteral(resourceName: "Masonboro")
        case .sc: return #imageLiteral(resourceName: "SurfCity")
        case .va: return #imageLiteral(resourceName: "VirginiaBeach")
        case .wb: return #imageLiteral(resourceName: "WrightsvilleBeach")
        }
    }
}

