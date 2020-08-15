//
//  AutosuggestResultsViewController.swift
//  csci571-news-app
//
//  Created by sinestro on 2020/4/20.
//  Copyright © 2020 us.usc. All rights reserved.
//

import UIKit

class AutosuggestResultsViewController: UIViewController {
    // MARK: - Table view for autosuggest results
    @IBOutlet weak var autosuggestTableView: UITableView!
    private let cellIdentifier = "AutosuggestCell"
    
    // MARK: - Use the delegate to perform segue
    var segueDelegate: SelectedAutosuggestCellProtocol?
    // MARK: - Store autosuggest items
    private var suggestedItems: [String] = []
    
    // MARK: - Data communication
    private var dataComm: DataCommunication = DataCommunication()
    
    // MARK: - View control functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup delegate and data source
        self.autosuggestTableView.delegate = self
        self.autosuggestTableView.dataSource = self
        
    }
    
    func fetchData(forKeyword keyword: String, with completeHandler: @escaping (Bool) -> ()) {
        // Request autosuggeted results
        self.dataComm.request(forKeyword: keyword,
                              endingWith:
            { [weak self] (_ suggestions: [String]) in
                if suggestions.count > 0 {
                    self?.suggestedItems = suggestions
                    completeHandler(true)
                }
                else {
                    completeHandler(false)
                }
        })
    }
}

extension AutosuggestResultsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.suggestedItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let autosuggestCell = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier, for: indexPath)
        autosuggestCell.textLabel?.text = self.suggestedItems[indexPath.row]
        
        return autosuggestCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath)
        // Use segue delegate to perform segue
        self.segueDelegate?.didSelectedCell(named: selectedCell?.textLabel?.text)
    }
}

// MARK: - Update search results in result controller
extension AutosuggestResultsViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        // Update search results
        if let keyword = searchController.searchBar.text, keyword.count > 2 {
            // Fetch autosuggested results
            fetchData(forKeyword: keyword, with: { [weak self] (_ isSuccess: Bool) in
                if isSuccess {
                    DispatchQueue.main.async {
                        self?.autosuggestTableView.reloadData()
                    }
                }
            })
        }
        else {
            // Clear table view
            DispatchQueue.main.async {
               self.suggestedItems.removeAll()
               self.autosuggestTableView.reloadData()
            }
        }
    }
    
}
