//
//  SectionNewsViewController.swift
//  csci571-news-app
//
//  Created by sinestro on 2020/4/21.
//  Copyright © 2020 us.usc. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import SwiftSpinner

class SectionNewsViewController: UITableViewController, IndicatorInfoProvider {
    
    // MARK: - Segue delegate
    var segueDelegate: SelectedNewsCellProtocol?
    
    // MARK: - Main table view for news
    private let newsCellIdentifier: String = "NewsCell"
    
    // MARK: - Refresh controller for table view
    private let myRefreshControl: UIRefreshControl = UIRefreshControl()
    
    // MARK: - Data communication API
    private let dataComm: DataCommunication = DataCommunication()
    
    // MARK: - Notification manager
    private let refreshNotification: Notification.Name = Notification.Name(rawValue: "refresh")
    
    // MARK: - News data
    private var articles: Articles?
    
    // MARK: - Information for IndicatorInfoProvider
    var sectionInfo = IndicatorInfo(title: "View")
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return self.sectionInfo
    }
    
    init(style: UITableView.Style, itemInfo: IndicatorInfo) {
        self.sectionInfo = itemInfo
        super.init(style: style)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Control functions
    override func viewDidLoad() {
        // Setup refresh control
        self.setupRefreshControl()
        // Setup spinner
        SwiftSpinner.show("Loading \(self.sectionInfo.title!) Headlines...")
        
        super.viewDidLoad()
        
        // Setup table view configuration
        self.setupTableViewConfig()
        // Setup notification manager
        self.setupNotification()
        // Fetch data from the server
        fetchData(withCompleteHandler: { [weak self] (isFinished: Bool) in
            if isFinished {
                SwiftSpinner.hide()
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
        })
    }
    
    func setupRefreshControl() {
        self.myRefreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
    }
    
    func setupTableViewConfig() {
        self.tableView.register(UINib(nibName: "NewsCell", bundle: nil),
                                        forCellReuseIdentifier: self.newsCellIdentifier)
        // No separator between cells
        self.tableView.separatorStyle = .none
        // No cell shifting when refreshing
        self.tableView.estimatedRowHeight = 0
        // Add a refresh control
        self.tableView.addSubview(self.myRefreshControl)
    }
    
    @objc func refresh(_ sender: Any) {
        // Re-fetch data from tthe server
        self.fetchData(withCompleteHandler: { [weak self] (isFinished: Bool) in
            if isFinished {
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    self?.myRefreshControl.endRefreshing()
                }
            }
        })
    }
    
    func fetchData(withCompleteHandler completeHandler: @escaping ((_ isFinished: Bool) -> ())) {
        self.dataComm.request(to: dataComm.generate(forSection: self.sectionInfo.title!.lowercased()), with: nil,
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
                self.tableView.reloadData()
            }
            
            return
        }
        
        // Check bookmark operation, only when the view is being presented
        if let info = notification.userInfo as? [String : Bool] {
            info["bookmarked"]! ? self.parent?.bookmarked() : self.parent?.unbookmarked()
        }
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.articles?.all.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let article = self.articles?.all[indexPath.row] ?? nil
        
        // Render the data to the news cell
        let newsCell = tableView.dequeueReusableCell(withIdentifier: self.newsCellIdentifier,
                                                     for: indexPath) as! NewsCell
        newsCell.load(from: article, ofType: false)
        // Remove the selection highlight
        newsCell.selectionStyle = .none
        
        return newsCell
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Select news cell
        let article = self.articles?.all[indexPath.row]
        self.segueDelegate?.didSelectedCell(of: article)
        
        // Remove the animation
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath,
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
}


