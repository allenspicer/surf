//
//  Station.swift
//  surf
//
//  Created by Allen Spicer on 3/12/18.
//  Copyright © 2018 surf. All rights reserved.
//

import Foundation

struct Station: Decodable {
    let id: String
    let stationId: String
    let lat: Double
    let lon: Double
    let beachFaceDirection: Double
    let name: String
    let nickname: String?
    var distanceInMiles : Int
}


