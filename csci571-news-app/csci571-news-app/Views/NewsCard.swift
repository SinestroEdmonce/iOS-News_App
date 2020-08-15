//
//  NewsCard.swift
//  csci571-news-app
//
//  Created by sinestro on 2020/4/20.
//  Copyright © 2020 us.usc. All rights reserved.
//

import UIKit

class NewsCard: UICollectionViewCell {
    
    // MARK: - Views layout
    @IBOutlet weak var newsImageView: UIImageView!
    @IBOutlet weak var newsTitleLabel: UILabel!
    @IBOutlet weak var newsDateLabel: UILabel!
    @IBOutlet weak var newsSectionLabel: UILabel!
       
    // MARK: - Data persistence tool
    private let dataPeTool: DataPersistence = DataPersistence()

    // MARK: - New data
    private var articleId: String?
    
    // MARK: - Notification
    private let refreshNotification: Notification.Name = Notification.Name(rawValue: "refresh")
    
    @IBAction func clickFavButton(_ sender: Any) {
        // Set article unfavourite
        self.dataPeTool.removeArticle(named: self.articleId)
        
        // Post notification
        NotificationCenter.default.post(name: self.refreshNotification, object: nil,
                                        userInfo: ["bookmarked": false])
    }
    
    
    // MARK: - Setup color constant
    private let background = UIColor(red: 235/255.0, green: 235/255.0, blue: 235/255.0, alpha: 1.0).cgColor
    private let border = UIColor(red: 195/255.0, green: 195/255.0, blue: 195/255.0, alpha: 1.0).cgColor
    
    // MARK: - View control function
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Set border style
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.backgroundColor = self.background
        self.contentView.layer.borderColor = self.border
        self.contentView.layer.cornerRadius = 10
        // Set image border
        self.newsImageView.layer.cornerRadius = 10
        self.newsImageView.layer.masksToBounds = true
        self.newsImageView.clipsToBounds = true
    }
    
    // MARK: - Load data
    func load(from data: Article?) {
        if let article = data {
            let imageURL = article.thumbnail
            if imageURL == "guardian-default-image" {
                self.newsImageView.image = UIImage(named: "default-guardian")
            }
            else {
                self.newsImageView.sd_setImage(with: URL(string: imageURL),
                                               placeholderImage: UIImage(named: "default-guardian"))
            }
            self.newsTitleLabel.text = article.title
            self.newsDateLabel.text = Array(article.publicationDate.components(separatedBy: " ")[0..<2]).joined(separator: " ")
            self.newsSectionLabel.text = article.sectionId
            
            // Store the article id
            self.articleId = article.articleId
        }
    }
}
