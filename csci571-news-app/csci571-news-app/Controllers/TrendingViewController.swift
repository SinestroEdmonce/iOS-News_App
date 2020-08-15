//
//  TrendingViewController.swift
//  csci571-news-app
//
//  Created by sinestro on 2020/4/20.
//  Copyright © 2020 us.usc. All rights reserved.
//

import UIKit
import Charts

class TrendingViewController: UIViewController {
    
    // MARK: - Chart view
    @IBOutlet weak var searchLabel: UILabel!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var lineChartView: LineChartView!
    
    // MARK: - Default settings
    private let defaultKeyword: String = "Coronavirus"
    private let defaultDotColor: UIColor = UIColor(red: 45/255.0, green: 128/255.0, blue: 240/255.0, alpha: 1)
    
    // MARK: - Data communcation
    private let dataComm: DataCommunication = DataCommunication()
    
    // MARK: - Trends data
    private var trends: Trends?
    
    // MARK: - View control functions
    override func viewDidLoad() {
        // Setup Chart styles and textfield delegate
        self.setupConfig()
        
        super.viewDidLoad()
        
        // Search for the default keyword
        self.search(forKeyword: self.defaultKeyword)
    }
    
    func setupConfig() {
        // Setup chart styles
        if let font = UIFont(name: "Helvetica", size: 15.0) {
            self.lineChartView.noDataFont = font
        }
        // Setup delegate
        self.searchTextField.delegate = self
    }
    
    func setChart(forKeyword keyword: String) {
        
        let values = self.trends?.all.map { (item) -> ChartDataEntry in
            //circleColors.append(self.defaultDotColor)
            return ChartDataEntry(x: Double(item.counter), y: Double(item.value))
        }
        
        let trendingLine = LineChartDataSet(entries: values, label: "Trending Chart for \(keyword)")
        // Set line style
        trendingLine.circleColors = [self.defaultDotColor]
        trendingLine.colors = [self.defaultDotColor]
        trendingLine.circleRadius = 4.0
        trendingLine.circleHoleRadius = 0.0
        
        let data = LineChartData(dataSet: trendingLine)
        
        self.lineChartView.data = data
        
    }
    
    func fetchData(forKeyword keyword: String, with completeHandler: @escaping () -> Void) {
        // Fetch trends data from the server
        self.dataComm.request(to: self.dataComm.generate(forTrends: nil), with: ["q" : keyword],
                              endingWith: { (trends: Trends?) in
                                // Store the trends regardless
                                self.trends = trends
                                // Draw the chart
                                completeHandler()
        })
    }
    
    func search(forKeyword keyword: String?) {
        if let keyword = keyword {
            self.fetchData(forKeyword: keyword, with: { [weak self] () in
                self?.setChart(forKeyword: keyword)
            })
        }
    }
    
}

extension TrendingViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.searchTextField {
            // Search for trends
            self.search(forKeyword: textField.text)
            
            textField.resignFirstResponder()
            return false
        }
        return true
    }
    
    
}
