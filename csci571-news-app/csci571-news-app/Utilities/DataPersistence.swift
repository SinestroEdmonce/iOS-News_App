//
//  DataPersistence.swift
//  csci571-news-app
//
//  Created by sinestro on 2020/4/23.
//  Copyright © 2020 us.usc. All rights reserved.
//

import Foundation

class DataPersistence {
    private let favArticleIdsKey: String = "articleIds"
    private let userDefaults: UserDefaults = UserDefaults.standard

    func saveArticle(withData data: Article?) {
        if let article = data, let encoded = try? JSONEncoder().encode(article) {
            // Persist the artcile id into the id list
            var ids = self.userDefaults.stringArray(forKey: self.favArticleIdsKey)
            if ids == nil {
                ids = []
            }
            ids?.append(article.articleId)
            self.userDefaults.set(ids, forKey: self.favArticleIdsKey)
            
            // Persist the article into storage
            self.userDefaults.set(encoded, forKey: article.articleId)
        }
    }
    
    func removeArticle(named articleId: String?) {
        if let id = articleId {
            // Remove the artcile id into the id list
            guard var ids = self.userDefaults.stringArray(forKey: self.favArticleIdsKey) else {
                return
            }
            
            // Remove all the same id
            while let index = ids.firstIndex(of: id) {
                ids.remove(at: index)
            }
            self.userDefaults.set(ids, forKey: self.favArticleIdsKey)
            
            // Remove the article with the given id
            self.userDefaults.removeObject(forKey: id)
        }
    }
    
    func getAricle(named articleId: String?) -> Article? {
        guard let id = articleId else { return nil }
        
        guard let data = self.userDefaults.object(forKey: id) as? Data else { return nil }
        
        guard let article = try? JSONDecoder().decode(Article.self, from: data) else { return nil }
        
        return article
    }
    
    func findArticle(named articleId: String?) -> Bool {
        guard let id = articleId else { return false }
        
        guard let ids = self.userDefaults.stringArray(forKey: self.favArticleIdsKey) else {
            return false
        }
        
        guard let _ = ids.firstIndex(of: id) else { return false }
        
        return true
    }
    
    func getArticleIds() -> [String]? {
        return self.userDefaults.stringArray(forKey: self.favArticleIdsKey)
    }
    
    func getArticles() -> [Article]? {
        guard let ids = self.userDefaults.stringArray(forKey: self.favArticleIdsKey) else {
            return nil
        }
        
        // Obtain all saved articles
        var articles: [Article] = []
        ids.forEach({ [weak self] (id) in
            guard let article = self?.getAricle(named: id) else { return }
            
            articles.append(article)
        })
        
        return articles
    }
}
