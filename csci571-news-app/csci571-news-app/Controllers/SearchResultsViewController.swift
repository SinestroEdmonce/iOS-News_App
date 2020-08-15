//
//  SearchResultsViewController.swift
//  csci571-news-app
//
//  Created by sinestro on 2020/4/20.
//  Copyright © 2020 us.usc. All rights reserved.
//

import UIKit
import SwiftSpinner

class SearchResultsViewController: UIViewController {
    // MARK: - Table view for news search results
    @IBOutlet weak var searchResultsTableView: UITableView!
    private let newsCellIdentifier: String = "NewsCell"
    @IBOutlet weak var noResultsLabel: UILabel!
    
    // MARK: - Refresh controller for table view
    private let refreshControl: UIRefreshControl = UIRefreshControl()
    
    // MARK: - Data communication API
    private let dataComm: DataCommunication = DataCommunication()
    
    // MARK: - News data
    private var articles: Articles?
    
    // MARK: - Keyword for query
    var query: String?
    
    // MARK: - Navigation controller
    private var backItem: UIBarButtonItem = UIBarButtonItem()
    
    // MARK: - Notification manager
    private let refreshNotification: Notification.Name = Notification.Name(rawValue: "refresh")
    
    // MARK: - View control functions
    override func viewDidLoad() {
        // Setup refresh control
        self.setupRefreshControl()
        // Setup spinner
        SwiftSpinner.show("Loading Search Results...")
        
        super.viewDidLoad()
        
        // Setup table view configuration
        self.setupTableViewConfig()
        // Setup notification manager
        self.setupNotification()
        // Fetch data from the server
        fetchData(withCompleteHandler: { [weak self] (isFinished: Bool) in
            if isFinished {
                SwiftSpinner.hide()
                self?.noResultsLabel.isHidden = true
                self?.searchResultsTableView.isHidden = false
                DispatchQueue.main.async {
                    self?.searchResultsTableView.reloadData()
                }
            }
            // If no data is fetched from the server
            else {
                SwiftSpinner.hide()
                self?.noResultsLabel.isHidden = false
                self?.searchResultsTableView.isHidden = true
            }
        })
    }
    
    func setupRefreshControl() {
        self.refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
    }
    
    func setupTableViewConfig() {
        self.searchResultsTableView.register(UINib(nibName: "NewsCell", bundle: nil),
                                        forCellReuseIdentifier: self.newsCellIdentifier)
        self.searchResultsTableView.delegate = self
        self.searchResultsTableView.dataSource = self
        // No separator between cells
        self.searchResultsTableView.separatorStyle = .none
        self.searchResultsTableView.estimatedRowHeight = 0
        // Add a refresh control
        self.searchResultsTableView.addSubview(self.refreshControl)
    }
    
    @objc func refresh(_ sender: Any) {
        // Re-fetch data from tthe server
        self.fetchData(withCompleteHandler: { [weak self] (isFinished: Bool) in
            if isFinished {
                self?.noResultsLabel.isHidden = true
                self?.searchResultsTableView.isHidden = false
                DispatchQueue.main.async {
                    self?.searchResultsTableView.reloadData()
                    self?.refreshControl.endRefreshing()
                }
            }
            else {
                self?.noResultsLabel.isHidden = false
                self?.searchResultsTableView.isHidden = true
            }
        })
    }
    
    func fetchData(withCompleteHandler completeHandler: @escaping ((_ isFinished: Bool) -> ())) {
        // Request search results
        self.dataComm.request(to: dataComm.generate(forSearchResults: nil), with: ["q": self.query!],
                              endingWith:
            { [weak self] (data: Articles?, isSuccess: Bool) in
                if isSuccess {
                    self?.articles = data!
                    completeHandler(true)
                }
                else {
                    completeHandler(false)
                }
        })
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SearchResults2DetailedArticle" {
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
                self.searchResultsTableView.reloadData()
            }
            
            return
        }
        
        // Check bookmark operation, only when the view is being presented
        if let info = notification.userInfo as? [String : Bool] {
            info["bookmarked"]! ? self.bookmarked() : self.unbookmarked()
        }
    }
}

extension SearchResultsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.articles?.all.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let article = self.articles?.all[indexPath.row] ?? nil
        
        // Render the data to the news cell
        let newsCell = tableView.dequeueReusableCell(withIdentifier: self.newsCellIdentifier,
                                                     for: indexPath) as! NewsCell
        newsCell.load(from: article, ofType: false)
        // Remove the selection highlight
        newsCell.selectionStyle = .none
        
        return newsCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Select news cell
        let article = self.articles?.all[indexPath.row]
        self.performSegue(withIdentifier: "SearchResults2DetailedArticle", sender: article)
        
        // Remove the animation
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath,
                   point: CGPoint) -> UIContextMenuConfiguration? {
        
        // If holding the tap on the news cell
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
}
