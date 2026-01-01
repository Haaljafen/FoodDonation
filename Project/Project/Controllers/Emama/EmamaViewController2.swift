import UIKit

// This protocol must be at the very top to fix the red error
protocol EmamaSearchDelegate: AnyObject {
    func didUpdateSearch(text: String)
    func didTapBack()
}

class EmamaViewController2: UIViewController, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var clearAllButton: UIButton!
    
    weak var delegate: EmamaSearchDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        
        // Initial state: Hidden as you requested
        backButton.isHidden = true
        clearAllButton.isHidden = true
        
        setupUI()
    }
    
    private func setupUI() {
        searchBar.placeholder = "Search here..."
        searchBar.backgroundImage = UIImage()
    }

    // MARK: - UISearchBarDelegate
    
    // This makes buttons appear when you click the search bar
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        UIView.animate(withDuration: 0.3) {
            self.backButton.isHidden = false
            self.clearAllButton.isHidden = false
        }
        return true
    }

    // This makes buttons hide if you leave the search bar empty
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if searchBar.text?.isEmpty ?? true {
            UIView.animate(withDuration: 0.3) {
                self.backButton.isHidden = true
                self.clearAllButton.isHidden = true
            }
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        delegate?.didUpdateSearch(text: searchText)
    }

    // MARK: - Actions
    
    @IBAction func backTapped(_ sender: UIButton) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        delegate?.didUpdateSearch(text: "")
        delegate?.didTapBack()
    }

    @IBAction func clearAllTapped(_ sender: UIButton) {
        searchBar.text = ""
        delegate?.didUpdateSearch(text: "")
    }
}
