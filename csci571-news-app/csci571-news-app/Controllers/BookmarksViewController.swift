//
//  BookmarksViewController.swift
//  csci571-news-app
//
//  Created by sinestro on 2020/4/20.
//  Copyright © 2020 us.usc. All rights reserved.
//

import UIKit

class BookmarksViewController: UIViewController {
    
    // MARK: - Collection view section layout
    private let sectionInsets = UIEdgeInsets(top: 0.0, left: 10.0, bottom: 10.0, right: 10.0)
    private let itemPerRow: CGFloat = 2
    private let itemAspectRatio: CGFloat = 4.0/3.0
    
    // MARK: - Collection view for news cards
    @IBOutlet weak var newsCardCollectionView: UICollectionView!
    private let cellIdentifer = "NewsCard"
    
    // MARK: - Navigation controller
    private var backItem: UIBarButtonItem = UIBarButtonItem()
    
    // MARK: - No bookmarks label
    @IBOutlet weak var noBookmarksLabel: UILabel!
    
    // MARK: - News data
    private var articles: [Article]?
    
    // MARK: - Data persistence tool
    private let dataPeTool: DataPersistence = DataPersistence()
    
    // MARK: - Notification manager
    private let refreshNotification: Notification.Name = Notification.Name(rawValue: "refresh")
    
    // MARK: - View control functions
    override func viewDidLoad() {
        // Setup the collection view configuration
        self.setupCollectionViewConfig()
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Setup notification
        self.setupNotification()
        // Obtain saved articles
        self.fetchData()
        // Reload data
        DispatchQueue.main.async {
            self.newsCardCollectionView.reloadData()
        }

        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Remove notification
        self.removeNotification(named: self.refreshNotification)
        
        super.viewWillDisappear(animated)
    }
    
    func setupCollectionViewConfig() {
        self.newsCardCollectionView.register(UINib(nibName: "NewsCard", bundle: nil),
                                             forCellWithReuseIdentifier: self.cellIdentifer)
        self.newsCardCollectionView.delegate = self
        self.newsCardCollectionView.dataSource = self
    }
   
    func fetchData() {
        // If no bookmarks
        guard let data = self.dataPeTool.getArticles() else {
            self.noBookmarksLabel.isHidden = false
            return
        }
        
        self.articles = data
        if self.articles?.count == 0 {
            self.noBookmarksLabel.isHidden = false
            return
        }
        
        // If bookmarks exist
        self.noBookmarksLabel.isHidden = true
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Bookmarks2DetailedArticle" {
            let detailedArticleVC = segue.destination as! DetailedArticleViewController
            detailedArticleVC.articleId = (sender as? Article)?.articleId
            
            // Remove the back item title
            self.backItem.title = ""
            navigationItem.backBarButtonItem = backItem
        }
    }
    
    // MARK: - Notification observation
    func setupNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.refresh(by:)),
                                               name: self.refreshNotification, object: nil)
    }

    func removeNotification(named name: Notification.Name) {
        NotificationCenter.default.removeObserver(self, name: name, object: nil)
    }

    @objc func refresh(by notification: Notification) {
        // Obtain saved articles
        self.fetchData()
        
        // Check bookmark operation, only when the view is being presented
        if self.viewIfLoaded?.window != nil, let info = notification.userInfo as? [String : Bool] {
            info["bookmarked"]! ? self.bookmarked() : self.unbookmarked()
        }
        
        // Reload data
        DispatchQueue.main.async {
            self.newsCardCollectionView.reloadData()
        }
    }

}

extension BookmarksViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.articles?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let newsCard = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellIdentifer, for: indexPath) as! NewsCard
        // Load data into the news card
        newsCard.load(from: self.articles?[indexPath.row])
        
        return newsCard
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let article = self.articles?[indexPath.row] {
            self.performSegue(withIdentifier: "Bookmarks2DetailedArticle", sender: article)
        }
    }
    
}

extension BookmarksViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // Calculate the spacing
        let paddingSpace = self.sectionInsets.left*(self.itemPerRow+1)
        let availableWidth = self.newsCardCollectionView.frame.width-paddingSpace
        let widthPerItem = availableWidth/self.itemPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem*self.itemAspectRatio)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}
