//
//  DetailedArticleViewController.swift
//  csci571-news-app
//
//  Created by sinestro on 2020/4/20.
//  Copyright © 2020 us.usc. All rights reserved.
//

import UIKit
import SwiftSpinner

class DetailedArticleViewController: UIViewController {

    // MARK: - Information for detailed article
    @IBOutlet weak var articleImageView: UIImageView!
    @IBOutlet weak var articleTitleLabel: UILabel!
    @IBOutlet weak var articleSectionLabel: UILabel!
    @IBOutlet weak var articleDateLabel: UILabel!
    @IBOutlet weak var articleDescriptionLabel: UILabel!
    
    @IBOutlet weak var twitterBarButton: UIBarButtonItem!
    @IBOutlet weak var favBarButton: UIBarButtonItem!
    private var isFav: Bool = false
    
    // MARK: - Notification manager
    private let refreshNotification: Notification.Name = Notification.Name(rawValue: "refresh")
    
    // MARK: - Actions on the detail article page
    @IBAction func clickFavButton(_ sender: Any) {
        if self.isFav {
            // Set the article unfavourite
            self.dataPeTool.removeArticle(named: self.articleId)
            self.favBarButton.image = UIImage(systemName: "bookmark")
            // Post notification
            NotificationCenter.default.post(name: self.refreshNotification, object: nil,
                                            userInfo: ["bookmarked": false])
        }
        else {
            // Set the article favourite
            self.dataPeTool.saveArticle(withData: self.article)
            self.favBarButton.image = UIImage(systemName: "bookmark.fill")
            // Post notification
            NotificationCenter.default.post(name: self.refreshNotification, object: nil,
                                            userInfo: ["bookmarked": true])
        }
        
        // Change bookmark status
        self.isFav = !self.isFav
    }
    
    @IBAction func clickShareButton(_ sender: Any) {
        // Share with twitter
        self.share(withURL: self.article?.url)
    }
    
    @IBAction func viewInBrowser(_ sender: Any) {
        if let url = URL(string: self.article!.url) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - News article id
    var articleId: String?
    
    // MARK: - Data communication API
    private let dataComm: DataCommunication = DataCommunication()
    
    // MARK: - News data
    private var article: Article?
    
    // MARK: - Data persistence tool
    private let dataPeTool: DataPersistence = DataPersistence()
    
    // MARK: - View control functions
    override func viewDidLoad() {
        // Setup the notification
        self.setupNotification()
        // Setup spinner
        SwiftSpinner.show("Loading Detailed Article...")
        
        super.viewDidLoad()
        
        // Fetch data from the server
        fetchData(withCompleteHandler: { [weak self] (isFinished: Bool) in
            if isFinished {
                self?.load(from: self?.article)
                SwiftSpinner.hide()
            }
            // If no data is fetched from the server, keep spinning
        })
    }
    
    func fetchData(withCompleteHandler completeHandler: @escaping ((_ isFinished: Bool) -> ())) {
        self.dataComm.request(to: dataComm.generate(forArticle: nil), with: ["id" : self.articleId!],
                              endingWith:
            { [weak self] (data: Article?, isSuccess: Bool) in
                if isSuccess {
                    self?.article = data!
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
                self.load(from: self.article)
            }
            
            return
        }
        
        // Check bookmark operation, only when the view is being presented
        if let info = notification.userInfo as? [String : Bool] {
            info["bookmarked"]! ? self.bookmarked() : self.unbookmarked()
        }
    }
    
    func load(from article: Article?) {
        guard let article = article else { return }
        
        // Load web image
        if article.imageURL == "guardian-default-image" {
            self.articleImageView.image = UIImage(named: "default-guardian")
        }
        else {
            self.articleImageView.sd_setImage(with: URL(string: article.imageURL),
                                              placeholderImage: UIImage(named: "default-guardian"))
        }
        
        self.articleTitleLabel.text = article.title
        // Set navigation item title
        self.navigationItem.title = article.title
        self.articleSectionLabel.text = article.sectionId
        self.articleDateLabel.text = article.publicationDate
        // Stripe out the <img ... > or <figure>...</figure> and obtain the attributed string
        var htmlText = article.description.replacingOccurrences(of: "<figure[^>]+>.*</figure>", with: "",
                                                                options: .regularExpression, range: nil)
        htmlText = htmlText.replacingOccurrences(of: "<img[^>]+>", with: "",
                                                 options: .regularExpression, range: nil)
        // Load the attributed html string
        self.articleDescriptionLabel.attributedText = htmlText.htmlToMutableAttributedString
        
        // Check if the article is in favourite lists
        self.isFav = self.dataPeTool.findArticle(named: self.articleId)
        self.favBarButton.image = self.isFav ? UIImage(systemName: "bookmark.fill") : UIImage(systemName: "bookmark")
    }
}
