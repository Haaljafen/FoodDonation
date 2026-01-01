import UIKit

// The delegate allows whatever screen is using this filter to receive the updates
protocol FilterDelegate: AnyObject {
    func didChangeCategory(to category: String)
}

class EmamaViewController1: UIViewController, FilterViewDelegate {

    @IBOutlet weak var filterView: FilterView!
    weak var delegate: FilterDelegate?
    
    // Default to admin, but can be changed to .donorHistory or .ngoBrowsing before loading
    var activeFilterType: FilterType = .adminUserManagement

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the Filter UI based on the role
        filterView.delegate = self
        filterView.setupFilter(for: activeFilterType)
    }

    // Catches the tap from your FilterView.swift logic
    func didSelectCategory(_ category: String) {
        // Send the result to the main screen
        delegate?.didChangeCategory(to: category)
    }
}
