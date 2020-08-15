//
//  Protocols.swift
//  csci571-news-app
//
//  Created by sinestro on 2020/4/21.
//  Copyright © 2020 us.usc. All rights reserved.
//

import Foundation
import SwiftyJSON

// MARK: - Segue delegate for selected autosuggest cell
protocol SelectedAutosuggestCellProtocol {
    func didSelectedCell(named keyword: String?)
}

// MARK: - Segue delegate for selected news cell
protocol SelectedNewsCellProtocol {
    func didSelectedCell(of article: Article?)
}

// MARK: - Data communication protocol
protocol DataComm {
    func request(to url: String, with params: [String: String]?,
                 endingWith completeHandler: @escaping ((_ jsonArray: Articles?, _ isSuccess: Bool) -> ()))
    
    func request(to url: String, with params: [String: String]?,
                 endingWith completeHandler: @escaping ((_ json: Article?, _ isSuccess: Bool) -> ()))
    
    func request(forCity city: String?, inState state: String?,
                 endingWith completeHandler: @escaping ((Weather?) -> ()))
    
    func request(forKeyword keyword: String,
                 endingWith completeHandler: @escaping (([String]) -> ()))
    
    func request(to url: String, with params: [String: String],
                 endingWith completeHandler: @escaping ((Trends?) -> ()))
}

// MARK: - Different url for API
protocol ApiUrlGenerator {
    var server: String { get }
    var weatherAPI: String { get }
    var autosuggestAPI: String { get }
    
    func generate(forSection section: String) -> String
    func generate(forArticle _: String?) -> String
    func generate(forSearchResults _: String?) -> String
    func generate(forTrends _: String?) -> String
}
   
