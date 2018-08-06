//
//  UserLocation.swift
//  surfbreak
//
//  Created by Allen Spicer on 8/6/18.
//  Copyright © 2018 surfbreak. All rights reserved.
//

import Foundation
import UIKit

struct UserLocation : Codable {
    var latitude : Double
    var longitude : Double
    var timestamp : Date
}
