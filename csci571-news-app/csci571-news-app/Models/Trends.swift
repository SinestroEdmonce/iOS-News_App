//
//  Trends.swift
//  csci571-news-app
//
//  Created by sinestro on 2020/4/30.
//  Copyright © 2020 us.usc. All rights reserved.
//

import Foundation

struct TimeData: Codable {
    let counter: Int
    let value: Int
    
    // MARK: - Decoding rules
    enum CodingKeys: String, CodingKey {
        case counter
        case value
    }
}

struct Trends: Codable {
    let all: [TimeData]
    
    // MARK: - Decoding rules
    enum CodingKeys: String, CodingKey {
        case all = "results"
    }
}
