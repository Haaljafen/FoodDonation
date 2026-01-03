import UIKit

class HeaderView: UIView, UISearchBarDelegate {
    // your outlets + code here
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var takaffalLabel: UILabel!
    @IBOutlet weak var notiBtn: UIButton!
    @IBOutlet weak var search: UISearchBar!
    
    @IBOutlet weak var clear: UILabel!
    
    @IBOutlet weak var calendar: UIButton!
    var onNotificationTap: (() -> Void)?
    var onSearchTextChanged: ((String) -> Void)?
    var onSearchButtonTapped: ((String) -> Void)?
    var onSearchCancelled: (() -> Void)?
    var onCalendarTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        search.delegate = self
        search.autocapitalizationType = .none
        search.autocorrectionType = .no
        search.returnKeyType = .search
        search.enablesReturnKeyAutomatically = false

        calendar.addTarget(self, action: #selector(calendarTapped(_:)), for: .touchUpInside)
    }

    @IBAction func notificationTapped(_ sender: UIButton) {
        onNotificationTap?()
    }

    @objc private func calendarTapped(_ sender: UIButton) {
        if let onCalendarTapped {
            onCalendarTapped()
            return
        }

        guard let vc = parentViewController() else { return }
        let calendarVC = CalendarViewController()
        let nav = UINavigationController(rootViewController: calendarVC)
        nav.modalPresentationStyle = .fullScreen
        vc.present(nav, animated: true)
    }

    private func parentViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let r = responder {
            if let vc = r as? UIViewController { return vc }
            responder = r.next
        }
        return nil
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
