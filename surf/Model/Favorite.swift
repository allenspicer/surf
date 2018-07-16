//
//  Station.swift
//  surf
//
//  Created by Allen Spicer on 3/12/18.
//  Copyright © 2018 surf. All rights reserved.
//

import Foundation

struct Favorite: Decodable {
    let id: Int
    var stationId: String
    var beachFaceDirection: Double
    var name: String
}

extension Favorite: Equatable {
    static func == (lhs: Favorite, rhs: Favorite) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Favorite: Hashable {
    var hashValue: Int {
        return id.hashValue ^ stationId.hashValue ^ beachFaceDirection.hashValue
    }
}
