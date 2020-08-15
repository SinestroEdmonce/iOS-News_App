//
//  DataCommunication.swift
//  csci571-news-app
//
//  Created by sinestro on 2020/4/22.
//  Copyright © 2020 us.usc. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class DataCommunication: DataComm, ApiUrlGenerator {
    
    // MARK: - Generate autosuggest api url
    private let autosuggestAPIkey = "2a400e92065b4cd3ba2b9f5c540f55e8"
    var autosuggestAPI: String {
        return "https://api.cognitive.microsoft.com/bing/v7.0/suggestions"
    }
    
    // MARK: - Generate weather api url
    private let weatherAPIKey = "c7cad372f7fb6cc1546b21dcf79e91c7"
    var weatherAPI: String {
        return "https://api.openweathermap.org/data/2.5/weather"
    }
    
    // MARK: - Generate news api url
    var server: String {
        return "http://csci571-mobile-qiaoyiyin.us-east-1.elasticbeanstalk.com"
    }
    
    func generate(forTrends _: String? = nil) -> String {
        return self.server+"/api/google-trends"
    }
    
    func generate(forSection section: String) -> String {
        return self.server+"/G/"+section
    }
    
    func generate(forArticle _: String? = nil) -> String {
        return self.server+"/G/details/article"
    }
    
    func generate(forSearchResults _: String? = nil) -> String {
        return self.server+"/G/articles/search"
    }
    
    
    // MARK: - News API
    func request(to url: String, with params: [String : String]?,
                 endingWith completeHandler: @escaping ((Articles?, Bool) -> ())) {
        // Send GET request
        
        Alamofire.request(url, method: .get, parameters: params)
            .responseJSON { (response) in
                guard let value = response.value else {
                    completeHandler(nil, false)
                    return
                }

                // Decode
                let data = JSON(value)
                let articles = try? JSONDecoder().decode(Articles.self, from: data.rawData())

                // Others(eg. VC) handle the data
                completeHandler(articles, true)
            }
    }
    
    func request(to url: String, with params: [String : String]?,
                 endingWith completeHandler: @escaping ((Article?, Bool) -> ())) {
        // Send GET request
        Alamofire.request(url, method: .get, parameters: params)
            .responseJSON { (response) in
                guard let value = response.value else { return }
                
                // Decode
                let data = JSON(value)
                let article = try? JSONDecoder().decode(Article.self, from: data["result"].rawData())
                
                // Others(eg. VC) handle the data
                completeHandler(article, true)
            }
    }
    
    // MARK: - Weather API
    func request(forCity city: String?, inState state: String?,
                 endingWith completeHandler: @escaping ((Weather?) -> ())) {
        
        var weather: Weather = Weather()
        // Load location info in advance
        weather.loadLocation(from: ["city" : city ?? "Los Angeles",
                                    "state" : state ?? "California"])
        
        Alamofire.request(self.weatherAPI, method: .get,
                          parameters: ["units" : "metric",
                                       "appid" : self.weatherAPIKey,
                                       "q" : weather.city])
            .responseJSON { (response) in
                guard let value = response.value else {
                    completeHandler(nil)
                    return
                }
                
                // Decode
                weather.loadWeather(from: JSON(value))
                
                // Others(eg. VC) handle the data
                completeHandler(weather)
        }
          
    }
    
    // MARK: - Autosuggest API
    func request(forKeyword keyword: String,
                 endingWith completeHandler: @escaping (([String]) -> ())) {
        
        Alamofire.request(self.autosuggestAPI, method: .get,
                          parameters: ["mkt" : "fr-FR", "q" : keyword],
                          headers: ["Ocp-Apim-Subscription-Key" : self.autosuggestAPIkey])
            .responseJSON { (response) in
                guard let value = response.value else { return }
                
                // Decode
                let suggestions = JSON(value)["suggestionGroups"].arrayValue[0]["searchSuggestions"].arrayValue
                var options: [String] = []
                suggestions.forEach({ (suggestion) in
                    options.append(suggestion["displayText"].stringValue)
                })
                
                // Others(eg. VC) handle the data
                completeHandler(options)
        }
    }
    
    // MARK: - Request Google trends
    func request(to url: String, with params: [String: String],
                 endingWith completeHandler: @escaping ((Trends?) -> ())) {
        // Send GET request
        Alamofire.request(url, method: .get, parameters: params)
            .responseJSON { (response) in
                guard let value = response.value else {
                    completeHandler(nil)
                    return
                }
                
                // Decode
                let data = JSON(value)
                let trends = try? JSONDecoder().decode(Trends.self, from: data.rawData())
                
                // If the "results" entry is empty
                if trends?.all.count == 0 {
                    completeHandler(nil)
                    return
                }
                
                // Others(eg. VC) handle the data
                completeHandler(trends)
        }
    }
}
