//
//  Snapshot.swift
//  surf
//
//  Created by uBack on 3/12/18.
//  Copyright © 2018 surf. All rights reserved.
//

import Foundation

struct Snapshot: Decodable {
    let timestamp: Int
    let swell: Swell
    let wind: Wind

    enum CodingKeys : String, CodingKey {
        case timestamp = "timestamp"
        case swell = "swell"
        case wind = "wind"
    }
}

struct Swell: Decodable {
    let absMinBreakingHeight: Double
    let absMaxBreakingHeight : Double
    let probability : Int
    let unit : String
    let minBreakingHeight : Double
    let maxBreakingHeight : Double
//    let components : [SwellComponents]
}

//struct SwellComponents: Decodable {
//
//}

struct Wind: Decodable {
    let speed : Int
    let compassDirection : String
    let gusts : Int
    let unit : String
}
