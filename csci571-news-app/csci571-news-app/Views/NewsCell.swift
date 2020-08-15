//
//  NewsCell.swift
//  csci571-news-app
//
//  Created by sinestro on 2020/4/20.
//  Copyright © 2020 us.usc. All rights reserved.
//

import UIKit
import SDWebImage

class NewsCell: UITableViewCell {

    // MARK: - Views layout
    @IBOutlet weak var newsImageView: UIImageView!
    @IBOutlet weak var newsTitleLabel: UILabel!
    @IBOutlet weak var newsTimeLabel: UILabel!
    @IBOutlet weak var newsSectionLabel: UILabel!
    @IBOutlet weak var favButton: UIButton!
    var isFav: Bool = false
    
    // MARK: - Data persistence tool
    private let dataPeTool: DataPersistence = DataPersistence()
    
    // MARK: - New data
    private var article: Article?
    
    // MARK: - Notification
    private let refreshNotification: Notification.Name = Notification.Name(rawValue: "refresh")
    
    @IBAction func clickFavButton(_ sender: Any) {
        if self.isFav {
            self.dataPeTool.removeArticle(named: self.article?.articleId)
            self.favButton.setBackgroundImage(UIImage(systemName: "bookmark"), for: .normal)
            // Post notification
            NotificationCenter.default.post(name: self.refreshNotification, object: nil,
                                            userInfo: ["bookmarked": false])
        }
        else {
            self.dataPeTool.saveArticle(withData: self.article)
            self.favButton.setBackgroundImage(UIImage(systemName: "bookmark.fill"), for: .normal)
            // Post notification
            NotificationCenter.default.post(name: self.refreshNotification, object: nil,
                                            userInfo: ["bookmarked": true])
        }
        
        self.isFav = !self.isFav
    }
    
    // MARK: - Setup color constant
    private let background = UIColor(red: 235/255.0, green: 235/255.0, blue: 235/255.0, alpha: 1.0).cgColor
    private let border = UIColor(red: 195/255.0, green: 195/255.0, blue: 195/255.0, alpha: 1.0).cgColor
    
    // MARK: - View control function
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
        self.contentView.frame = self.contentView.frame.inset(by: UIEdgeInsets(top: 2, left: 5, bottom: 3, right: 5))
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
    func load(from data: Article?, ofType type: Bool) {
        if let article = data {
            let imageURL = type ? article.thumbnail : article.imageURL
            if imageURL == "guardian-default-image" {
                self.newsImageView.image = UIImage(named: "default-guardian")
            }
            else {
                self.newsImageView.sd_setImage(with: URL(string: imageURL),
                                               placeholderImage: UIImage(named: "default-guardian"))
            }
            self.newsTitleLabel.text = article.title
            self.newsTimeLabel.text = article.timeDiff
            self.newsSectionLabel.text = article.sectionId
            
            // Store the article
            self.article = article
            
            // Check if it is favourite
            self.isFav = self.dataPeTool.findArticle(named: self.article?.articleId)
            if self.isFav {
                self.favButton.setBackgroundImage(UIImage(systemName: "bookmark.fill"), for: .normal)
            }
            else {
                self.favButton.setBackgroundImage(UIImage(systemName: "bookmark"), for: .normal)
            }
        }
    }
}
