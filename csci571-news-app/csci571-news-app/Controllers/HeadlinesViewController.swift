//
//  HeadlinesViewController.swift
//  csci571-news-app
//
//  Created by sinestro on 2020/4/20.
//  Copyright © 2020 us.usc. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class HeadlinesViewController: ButtonBarPagerTabStripViewController {
    // MARK: - Section names
    let sections = ["world", "business", "politics", "sports", "technology", "science"]
    // MARK: - Highlight color for selected section
    let highlightColor = UIColor(red: 60/255.0, green: 135/255.0, blue: 220/255.0, alpha: 1.0)
    let inactiveColor = UIColor(red: 148/255.0, green: 148/255.0, blue: 148/255.0, alpha: 1.0)
    
    // MARK: - Search controller for headlines page
    var searchController: UISearchController!
    // Default attributes for search controller
    let defaultPlaceholder: String = "Enter keyword..."
    let resultControllerName: String = "AutosuggestResultsVC"
    // Search results controller for search controller
    var autosuggestResultsVC: AutosuggestResultsViewController?
    
    // MARK: - Navigation controller
    private var backItem: UIBarButtonItem = UIBarButtonItem()
    
    // MARK: - View control functions
    override func viewDidLoad() {
        // Setup child controllers
        setupPagerTabStrip()
        setupSearchController(withResultsControllerNamed: self.resultControllerName)
        
        super.viewDidLoad()
    }
    
    func setupPagerTabStrip() {
        // Setup the selected button and bar style
        self.settings.style.buttonBarBackgroundColor = .white
        self.settings.style.buttonBarItemBackgroundColor = .white
        self.settings.style.selectedBarBackgroundColor = self.highlightColor
        self.settings.style.buttonBarItemFont = .boldSystemFont(ofSize: 14)
        self.settings.style.selectedBarHeight = 2.0
        self.settings.style.buttonBarMinimumLineSpacing = 0
        self.settings.style.buttonBarItemTitleColor = self.inactiveColor
        self.settings.style.buttonBarItemsShouldFillAvailableWidth = true
        self.settings.style.buttonBarLeftContentInset = 0
        self.settings.style.buttonBarRightContentInset = 0

        self.changeCurrentIndexProgressive = { [weak self] (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            
            // If changing index is not needed, exit safely
            guard changeCurrentIndex == true else { return }
            
            oldCell?.label.textColor = self?.inactiveColor
            newCell?.label.textColor = self?.highlightColor
        }
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
        navigationItem.hidesSearchBarWhenScrolling = false
        
        definesPresentationContext = true
    }
    
    // MARK: - PagerTabStrip data source
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        var children: [UIViewController] = []
        self.sections.forEach({ [weak self] (item) in
            let childVC = SectionNewsViewController(style: .plain, itemInfo: IndicatorInfo(title: item.uppercased()))
            childVC.segueDelegate = self
            children.append(childVC)
        })
        
        return children
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Headlines2SearchResults" {
            let searchResultsVC = segue.destination as! SearchResultsViewController
            searchResultsVC.query = sender as? String

            // Dismiss the search results controller, yet reserve the query by using placehoder
            self.searchController.searchBar.endEditing(true)
            self.searchController.searchBar.placeholder = self.searchController.searchBar.text!
            self.searchController.searchBar.text = ""
            
            // Set the back item title
            self.backItem.title = "Headlines"
            navigationItem.backBarButtonItem = backItem
        }
        else if segue.identifier == "Headlines2DetailedArticle" {
            let detailedArticleVC = segue.destination as! DetailedArticleViewController
            detailedArticleVC.articleId = (sender as? Article)?.articleId
            
            // Remove the back item title
            self.backItem.title = ""
            navigationItem.backBarButtonItem = backItem
        }
    }
}

// MARK: - Handle events from the search bar if needed
extension HeadlinesViewController: UISearchBarDelegate {
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
            self.performSegue(withIdentifier: "Headlines2SearchResults", sender: query)
        }
    }
}

// MARK: - Handle events from search controller if needed
extension HeadlinesViewController: UISearchControllerDelegate {
    
}

// MARK: - Handle selecting in search result controller
extension HeadlinesViewController: SelectedAutosuggestCellProtocol {
    func didSelectedCell(named keyword: String?) {
        if let query = keyword {
            self.performSegue(withIdentifier: "Headlines2SearchResults", sender: query)
        }
    }
}

// MARK: - Handle selecting in table view
extension HeadlinesViewController: SelectedNewsCellProtocol {
    func didSelectedCell(of article: Article?) {
        if let data = article {
            self.performSegue(withIdentifier: "Headlines2DetailedArticle", sender: data)
        }
    }
}
