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
    func image() -> UIImage {
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

public enum Condition {
    case poor, fair, good, ideal
    init?(index: Int) {
        switch index {
        case 1: self = .ideal
        case 2: self = .good
        case 3: self = .fair
        case 4: self = .poor
        default: return nil
        }
    }
    var image : UIImage {
        switch self {
        case .poor:
            return #imageLiteral(resourceName: "Bkgd_4")
        case .fair:
            return #imageLiteral(resourceName: "Bkgd_3")
        case .good:
            return #imageLiteral(resourceName: "Bkgd_2")
        case .ideal:
            return #imageLiteral(resourceName: "Bkgd_1")
        }
    }
    var title : String {
        switch self {
        case .poor:
            return "POOR CONDITIONS"
        case .fair:
            return "FAIR CONDITIONS"
        case .good:
            return "GOOD CONDITIONS"
        case .ideal:
            return "IDEAL CONDITIONS"
        }
    }
    var quality : Int {
        switch self {
        case .poor:
            return 4
        case .fair:
            return 3
        case .good:
            return 2
        case .ideal:
            return 1
        }
    }
}

