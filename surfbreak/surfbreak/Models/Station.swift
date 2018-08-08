//
//  Station.swift
//  surfbreak
//
//  Created by Allen Spicer on 8/2/18.
//  Copyright © 2018 surfbreak. All rights reserved.
//

import Foundation
import UIKit

struct Station : Decodable{
    var id = Int()
    var station = Int()
    var bfd = Int()
    var name = String()
    var latitude = Double()
    var longitude = Double()
    var airWindTideId = Int()

}


