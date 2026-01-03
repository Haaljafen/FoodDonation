import UIKit

class HeaderView: UIView, UISearchBarDelegate {
    // your outlets + code here
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var takaffalLabel: UILabel!
    @IBOutlet weak var notiBtn: UIButton!
    @IBOutlet weak var search: UISearchBar!
    
    @IBOutlet weak var clear: UILabel!
    
    var onNotificationTap: (() -> Void)?
    var onSearchTextChanged: ((String) -> Void)?
    var onSearchButtonTapped: ((String) -> Void)?
    var onSearchCancelled: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        search.delegate = self
        search.autocapitalizationType = .none
        search.autocorrectionType = .no
        search.returnKeyType = .search
        search.enablesReturnKeyAutomatically = false
    }

    @IBAction func notificationTapped(_ sender: UIButton) {
        onNotificationTap?()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        onSearchTextChanged?(searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        onSearchButtonTapped?(searchBar.text ?? "")
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        onSearchTextChanged?("")
        onSearchCancelled?()
    }
}
