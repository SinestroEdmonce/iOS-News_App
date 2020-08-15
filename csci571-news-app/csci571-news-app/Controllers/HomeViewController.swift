//
//  ViewController.swift
//  csci571-news-app
//
//  Created by sinestro on 2020/4/19.
//  Copyright © 2020 us.usc. All rights reserved.
//

import UIKit
import MapKit
import SwiftSpinner

class HomeViewController: UIViewController {
        
    // MARK: - Main table view for news and weather
    @IBOutlet weak var newsCellTableView: UITableView!
    private let newsCellIdentifier: String = "NewsCell"
    private let weatherCellIdentifier: String = "WeatherCell"
    
    // MARK: - Search controller for home page
    var searchController: UISearchController!
    // Default attributes for search controller
    private let defaultPlaceholder: String = "Enter keyword..."
    private let resultControllerName: String = "AutosuggestResultsVC"
    
    // Search results controller for search controller
    var autosuggestResultsVC: AutosuggestResultsViewController?
    
    // MARK: - Refresh controller for table view
    private let refreshControl: UIRefreshControl = UIRefreshControl()
    
    // MARK: - Data communication API
    private let dataComm: DataCommunication = DataCommunication()
    
    // MARK: - News data
    private var articles: Articles?
    
    // MARK: - Navigation controller
    private var backItem: UIBarButtonItem = UIBarButtonItem()
    
    // MARK: - Location manager
    private var locationManager: CLLocationManager = CLLocationManager()
    
    // MARK: - Notification manager
    private let refreshNotification: Notification.Name = Notification.Name(rawValue: "refresh")
    
    // MARK: - Weather data
    private var weather: Weather?
    
    // MARK: - View control functions
    override func viewDidLoad() {
        // Setup search controller
        self.setupSearchController(withResultsControllerNamed: self.resultControllerName)
        // Setup refresh control
        self.setupRefreshControl()
        // Setup spinner
        SwiftSpinner.show("Loading Home Page...")
        
        super.viewDidLoad()
        
        // Setup location manager
        self.setupLocationManager()
        // Setup table view configuration
        self.setupTableViewConfig()
        // Setup notification manager
        self.setupNotification()
        // Fetch data from the server
        self.fetchData(withCompleteHandler: { [weak self] (isFinished: Bool) in
            if isFinished {
                SwiftSpinner.hide()
                DispatchQueue.main.async {
                    self?.newsCellTableView.reloadData()
                }
            }
        })
    }
    
    func setupSearchController(withResultsControllerNamed identifier: String) {
        // Instantiate the search results view controller
        self.autosuggestResultsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: identifier) as? AutosuggestResultsViewController
        // Setup the delegate of search results controller to self
        self.autosuggestResultsVC?.segueDelegate = self

        // Setup the search controller
        self.searchController = UISearchController(searchResultsController: self.autosuggestResultsVC)
        self.searchController.delegate = self
        self.searchController.searchResultsUpdater = self.autosuggestResultsVC
        self.searchController.obscuresBackgroundDuringPresentation = true
        self.searchController.searchBar.placeholder = self.defaultPlaceholder
        self.searchController.searchBar.delegate = self

        // Put the search controller into the navigation item
        navigationItem.searchController = searchController
        // Make the search bar invisible when scrolling
        navigationItem.hidesSearchBarWhenScrolling = true

        definesPresentationContext = true
    }
    
    func setupRefreshControl() {
        self.refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
    }
    
    func setupTableViewConfig() {
        self.newsCellTableView.register(UINib(nibName: "WeatherCell", bundle: nil),
                                        forCellReuseIdentifier: self.weatherCellIdentifier)
        self.newsCellTableView.register(UINib(nibName: "NewsCell", bundle: nil),
                                        forCellReuseIdentifier: self.newsCellIdentifier)
        self.newsCellTableView.delegate = self
        self.newsCellTableView.dataSource = self
        // No separator between cells
        self.newsCellTableView.separatorStyle = .none
        self.newsCellTableView.estimatedRowHeight = 0
        // Add a refresh control
        self.newsCellTableView.addSubview(self.refreshControl)
    }
    
    @objc func refresh(_ sender: Any) {
        // Re-fetch data from tthe server
        self.fetchData(withCompleteHandler: { [weak self] (isFinished: Bool) in
            if isFinished {
                DispatchQueue.main.async {
                    self?.newsCellTableView.reloadData()
                    self?.refreshControl.endRefreshing()
                }
            }
        })
    }
    
    func fetchData(withCompleteHandler completeHandler: @escaping ((_ isFinished: Bool) -> ())) {
        // Request news data
        self.dataComm.request(to: dataComm.generate(forSection: "home"), with: nil,
                              endingWith:
            { [weak self] (data: Articles?, isSuccess: Bool) in
                // Have obtained news data
                self?.articles = data!
                
                // Get the location
                self?.lookUpCurrentLocation(with: { [weak self, isSuccess ] (currentPlace: CLPlacemark?) in
                    guard let place = currentPlace else {
                        completeHandler(isSuccess)
                        return
                    }
                    
                    self?.fetchWeather(forCity: place.locality, inState: place.administrativeArea, isSuccess, with: completeHandler)
                })
        })
    }
    
    func fetchWeather(forCity city: String?, inState state: String?, _ isSuccess: Bool,
                      with completeHandler: @escaping ((Bool) -> ())) {
        // Request weather data
        self.dataComm.request(forCity: city, inState: state,
                               endingWith: { [weak self, isSuccess] (weather: Weather?) in
                                // Have obtained weather data
                                self?.weather = weather
                                completeHandler(isSuccess)
        })
    }
    
    // MARK: - Loaction manager
    func setupLocationManager() {
        // Request authorization for in-use only
        self.locationManager.requestWhenInUseAuthorization()
        
        // Set up configuration, including location accuracy
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            self.locationManager.startUpdatingLocation()
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Home2SearchResults" {
            let searchResultsVC = segue.destination as! SearchResultsViewController
            searchResultsVC.query = sender as? String

            // Dismiss the search results controller, yet reserve the query by using placehoder
            self.searchController.searchBar.endEditing(true)
            self.searchController.searchBar.placeholder = self.searchController.searchBar.text!
            self.searchController.searchBar.text = ""
            
            // Set the back item title
            self.backItem.title = "Home"
            navigationItem.backBarButtonItem = backItem
        }
        else if segue.identifier == "Home2DetailedArticle" {
            let detailedArticleVC = segue.destination as! DetailedArticleViewController
            detailedArticleVC.articleId = (sender as? Article)?.articleId
            
            // Remove the back item title
            self.backItem.title = ""
            navigationItem.backBarButtonItem = backItem
        }
    }
    
    // MARK: - Notification manager
    func setupNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.refresh(by:)),
                                               name: self.refreshNotification, object: nil)
    }

    func removeNotification(named name: Notification.Name) {
        NotificationCenter.default.removeObserver(self, name: name, object: nil)
    }

    @objc func refresh(by notification: Notification) {
        // If the view is not being presented
        guard let _ = self.viewIfLoaded?.window else {
            // Reload data
            DispatchQueue.main.async {
                self.newsCellTableView.reloadData()
            }
            
            return
        }
        
        // Check bookmark operation, only when the view is being presented
        if let info = notification.userInfo as? [String : Bool] {
            info["bookmarked"]! ? self.bookmarked() : self.unbookmarked()
        }
    }
}


// MARK: - Handle events from the search bar if needed
extension HomeViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Restore the placehoder
        self.searchController.searchBar.placeholder = self.defaultPlaceholder
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if let placeholder = self.searchController.searchBar.placeholder, placeholder != self.defaultPlaceholder {
            self.searchController.searchBar.text = placeholder
            self.searchController.searchBar.placeholder = self.defaultPlaceholder
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Search button clicked
        if let query = self.searchController.searchBar.text {
            self.performSegue(withIdentifier: "Home2SearchResults", sender: query)
        }
    }
}

// MARK: - Handle events from search controller if needed
extension HomeViewController: UISearchControllerDelegate {
    
}

// MARK: - Handle selecting in search result controller
extension HomeViewController: SelectedAutosuggestCellProtocol {
    func didSelectedCell(named keyword: String?) {
        if let query = keyword {
            self.performSegue(withIdentifier: "Home2SearchResults", sender: query)
        }
    }
}

// MARK: - Handle table view
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Weather section
        if section == 0 {
            return 1
        }
        // News section
        else {
            return self.articles?.all.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Weather section
        if indexPath.section == 0 {
            let weatherCell = tableView.dequeueReusableCell(withIdentifier: self.weatherCellIdentifier,
                                                            for: indexPath) as! WeatherCell
            weatherCell.load(from: self.weather)
            // Remove the selection highlight
            weatherCell.selectionStyle = .none
            return weatherCell
        }
        // News section
        else {
            let article = self.articles?.all[indexPath.row] ?? nil
            
            // Render the data to the news cell
            let newsCell = tableView.dequeueReusableCell(withIdentifier: self.newsCellIdentifier,
                                                         for: indexPath) as! NewsCell
            newsCell.load(from: article, ofType: true)
            // Remove the selection highlight
            newsCell.selectionStyle = .none
            
            return newsCell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Select news cell
        if indexPath.section == 1 {
            let article = self.articles?.all[indexPath.row]
            self.performSegue(withIdentifier: "Home2DetailedArticle", sender: article)
        }
        
        // Remove the animation
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Setup context menu
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath,
                   point: CGPoint) -> UIContextMenuConfiguration? {
        
        // If holding the tap on the news cell
        if indexPath.section == 1 {
            let tappedCell = tableView.cellForRow(at: indexPath) as! NewsCell
            let isFav = (tableView.cellForRow(at: indexPath) as! NewsCell).isFav
            let share = UIAction(title: "Share with Twitter",
                                 image: UIImage(named: "twitter")) { (action) in
                                    
                                    // Share with twitter
                                    self.share(withURL: self.articles?.all[indexPath.row].url)
            }
            let bookmark = UIAction(title: "Bookmark",
                                    image: isFav ? UIImage(systemName: "bookmark.fill") : UIImage(systemName: "bookmark")) {
                                        [tappedCell] (action) in
                                        // Perform operation after clicking on bookmark
                                        tappedCell.clickFavButton(true)                     
            }

            return UIContextMenuConfiguration(identifier: nil,
                                              previewProvider: nil) { _ in
                                                UIMenu(title: "Menu", children: [share, bookmark])
            }
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
}

// MARK: - Location management
extension HomeViewController: CLLocationManagerDelegate {
    
    func lookUpCurrentLocation(with completeHandler: @escaping (CLPlacemark?) -> ()) {
        // Use the last repored location
        if let lastLocation = self.locationManager.location {
            let geoCoder = CLGeocoder()
            
            // Look up the location
            geoCoder.reverseGeocodeLocation(lastLocation,
                                            completionHandler: { (placemarks, error) in
                                                if error == nil {
                                                    // Give back the placemark
                                                    completeHandler(placemarks?[0])
                                                }
                                                else {
                                                    completeHandler(nil)
                                                }
            })
        }
        else {
            // No location was available
            completeHandler(nil)
        }
    }
    
}
