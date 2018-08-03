//
//  Station.swift
//  surf
//
//  Created by Allen Spicer on 3/12/18.
//  Copyright © 2018 surf. All rights reserved.
//

import Foundation

//struct Station: Decodable {
//    let id = Int()
//    var station = Int()
//    let lat = Double()
//    let lon = Double()
//    var beachFaceDirection = Double()
//    var name = String()
//    let nickname = String()
//    var distanceInMiles = Int()
//}


struct Station : Decodable{
    var id = Int()
    var station = Int()
    var bfd = Int()
    var name = String()
}



