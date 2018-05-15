//
//  Station.swift
//  surf
//
//  Created by uBack on 3/12/18.
//  Copyright © 2018 surf. All rights reserved.
//

import Foundation

struct Station: Decodable {
    let id: Int
    let lat: String
    let lon: String
    let owner: String?
    let name: String?
//    let snapshots: [Snapshot]
    
}


