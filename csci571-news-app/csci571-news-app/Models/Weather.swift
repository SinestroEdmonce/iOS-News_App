//
//  Weather.swift
//  csci571-news-app
//
//  Created by sinestro on 2020/4/23.
//  Copyright © 2020 us.usc. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Weather {
    
    var temperature: String
    var city: String
    var state: String
    var summary: String
    
    // MARK: - Load data from JSON
    mutating func loadWeather(from data: JSON) {
        // JSON structure mapping:
        //      temperature (in Celsius) <- main~>temp (rounded to nearest integer)
        //      summary <- weather[0]~>main
        var temp = Double(data["main"]["temp"].stringValue)
        temp?.round(.toNearestOrEven)
        
        self.temperature = String(Int(temp ?? 0))+"°C"
        self.summary = data["weather"].arrayValue[0]["main"].stringValue
    }
    
    // MARK: - Store city and state
    mutating func loadLocation(from dict: [String: String]) {
        self.city = dict["city"]!
        self.state = dict["state"]!
    }
    
    // MARK: - Initializaion
    init() {
        self.temperature = ""
        self.city = ""
        self.state = ""
        self.summary = ""
    }
}
