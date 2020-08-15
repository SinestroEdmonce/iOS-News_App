//
//  Articles.swift
//  csci571-news-app
//
//  Created by sinestro on 2020/4/22.
//  Copyright © 2020 us.usc. All rights reserved.
//

import Foundation

struct Articles: Codable {
    let all: [Article]
    
    // MARK: - Decoding rules
    enum CodingKeys: String, CodingKey {
        case all = "results"
    }
}
