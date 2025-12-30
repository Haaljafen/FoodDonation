import UIKit

class EmamaViewController: UIViewController {

    @IBOutlet weak var filterView: FilterView! // Ensure this is connected in Storyboard

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the delegate so this class hears button clicks
        filterView.delegate = self
        
        // Initialize the filter bar with food categories
        filterView.setupFilter(for: .foodCategories)
    }
}

// MARK: - FilterViewDelegate
extension EmamaViewController: FilterViewDelegate {
    func didSelectCategory(_ category: String) {
        print("Category selected: \(category)")
        // This is where you will eventually trigger your table view to filter
    }
}
