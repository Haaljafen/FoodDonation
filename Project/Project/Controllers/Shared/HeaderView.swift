import UIKit

class HeaderView: UIView {
    // your outlets + code here
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var takaffalLabel: UILabel!
    @IBOutlet weak var notiBtn: UIButton!
    @IBOutlet weak var search: UISearchBar!
    
    @IBOutlet weak var clear: UILabel!
    
    var onNotificationTap: (() -> Void)?

        @IBAction func notificationTapped(_ sender: UIButton) {
            onNotificationTap?()
        }
    }

