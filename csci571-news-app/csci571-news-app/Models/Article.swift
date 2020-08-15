//
//  NewsData.swift
//  csci571-news-app
//
//  Created by sinestro on 2020/4/22.
//  Copyright © 2020 us.usc. All rights reserved.
//

import Foundation

struct Article: Codable {
    
    // MARK: - Attributes for a news article
    let title: String
    let imageURL: String
    let thumbnail: String
    let sectionId: String
    let articleId: String
    let publishedAt: String
    let description: String
    let url: String
    let timeDiff: String
    let publicationDate: String
    
    // MARK: - Decoding rules
    enum CodingKeys: String, CodingKey {
        case title
        case imageURL
        case thumbnail
        case sectionId
        case articleId
        case publishedAt
        case description
        case url
        case timeDiff
        case publicationDate
    }
}
