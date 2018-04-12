//
//  Station.swift
//  surf
//
//  Created by uBack on 3/12/18.
//  Copyright © 2018 surf. All rights reserved.
//

import Foundation

struct Station: Decodable {
    let id: String
    let lat: String
    let lon: String
    let owner: String?
    let name: String?
    let snapshots: [Snapshot]
    
    init(id: String, lat: String, lon: String) {
        self.id = id
        self.lat = lat
        self.lon = lon
        self.owner = owner
        self.name = name
        self.snapshots = snapshots
        
    }
}


