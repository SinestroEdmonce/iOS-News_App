//
//  Extensions.swift
//  csci571-news-app
//
//  Created by sinestro on 2020/4/22.
//  Copyright © 2020 us.usc. All rights reserved.
//

import Foundation
import UIKit
import Toast_Swift

extension UIImageView {
    func load(from url: String) {
        DispatchQueue.global().async { [weak self] in
            guard let imageURL = URL(string: url) else { return }
            
            if let data = try? Data(contentsOf: imageURL) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}

extension String {
    var htmlToMutableAttributedString: NSMutableAttributedString? {
        guard let data = data(using: .utf8) else { return NSMutableAttributedString() }
        
        do {
            return try NSMutableAttributedString(data: data,
                                                 options: [.documentType: NSAttributedString.DocumentType.html,
                                                           .characterEncoding: String.Encoding.utf8.rawValue],
                                                 documentAttributes: nil)
        } catch {
            return NSMutableAttributedString()
        }
    }
    
    var htmlToString: String {
        return htmlToMutableAttributedString?.string ?? ""
    }
}

extension NSMutableAttributedString {
    func setFont(with font: UIFont? = nil) -> NSMutableAttributedString {
        var attributes = self.attributes(at: 0, effectiveRange: nil)
        attributes[NSAttributedString.Key.font] = font
        self.setAttributes(attributes, range: NSRange(location: 0, length: self.length))
        
        return self
    }
}

extension UIViewController {

    func toastify(with text: String) {
        self.view.makeToast(text, duration: 2.0, position: .bottom)
    }
    
    func bookmarked() {
        self.toastify(with: "Article Bookmarked. Check out the Bookmarks tab to view.")
    }
    
    func unbookmarked() {
        self.toastify(with: "Article removed from Bookmarks.")
    }
    
    func share(withURL articleURL: String?) {
        let tweetText: String = "Check out this Article!"
        let hashtag: String = "CSCI_571_NewsApp"
        
        let sharedURL = "https://twitter.com/intent/tweet?text=\(tweetText)&hashtags=\(hashtag)&url=\(articleURL ?? "")"
        
        // Convert the space to %20
        let escapedSharedURL = sharedURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if let url = URL(string: escapedSharedURL) {
            UIApplication.shared.open(url)
        }
    }
    
}
