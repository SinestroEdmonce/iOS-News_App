//
//  WeatherCell.swift
//  csci571-news-app
//
//  Created by sinestro on 2020/4/22.
//  Copyright © 2020 us.usc. All rights reserved.
//

import UIKit

class WeatherCell: UITableViewCell {
    @IBOutlet weak var weatherImageView: UIImageView!
    
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Set the spacing
        self.contentView.frame = self.contentView.frame.inset(by: UIEdgeInsets(top: 0, left: 5, bottom: 13, right: 5))
        // Set border style
        self.contentView.layer.borderWidth = 0
        self.contentView.layer.cornerRadius = 10
        // Set image border
        self.weatherImageView.layer.cornerRadius = 10
        self.weatherImageView.layer.masksToBounds = true
        self.weatherImageView.clipsToBounds = true
    }
    
    func load(from data: Weather?) {
        if let weather = data {
            self.cityLabel.text = weather.city
            self.summaryLabel.text = weather.summary
            self.stateLabel.text = weather.state
            self.temperatureLabel.text = weather.temperature
            
            self.loadImage(from: weather.summary)
        }
    }
    
    private func loadImage(from summary: String) {
        switch summary {
        case "Clouds":
            self.weatherImageView.image = UIImage(named: "cloudy_weather")
        case "Clear":
            self.weatherImageView.image = UIImage(named: "clear_weather")
        case "Snow":
            self.weatherImageView.image = UIImage(named: "snowy_weather")
        case "Rain":
            self.weatherImageView.image = UIImage(named: "rainy_weather")
        case "Thunderstorm":
            self.weatherImageView.image = UIImage(named: "thunder_weather")
        default:
            self.weatherImageView.image = UIImage(named: "sunny_weather")
        }
    }
}
