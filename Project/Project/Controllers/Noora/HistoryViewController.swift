


import UIKit
import FirebaseFirestore
import FirebaseAuth

// MARK: - Model (History list only)
struct DonationHistoryItem {
    let donationID: String
    let method: String
    let createdAt: Timestamp
    let status: String
}

struct DonationDetails {
    let donationID: String
    let category: String
    let createdAt: Timestamp
    let donationMethod: String
    let donorId: String
    let imageUrl: String
    let impactType: String
    let item: String
    let quantity: Int
    let status: String
}

final class HistoryViewController: UIViewController {

    // MARK: - Outlets (from storyboard)
    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var navContainer: UIView!
    @IBOutlet weak var table: UITableView!
    
    

    // Keep references if you need them later
    private var headerView: HeaderView?
    private var bottomNav: BottomNavView?

    // Make sure we only add them once
    private var didSetupViews = false

    
    // MARK: - Firestore
    private let db = Firestore.firestore()
    private var donations: [DonationHistoryItem] = []

    // Date formatter (reuse)
    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    
    
    ///
    override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()

            // ✅ Hard-coded layout (ignores Auto Layout)
            // IMPORTANT: remove/disable storyboard constraints for these views,
            // or they may override your frames.
            headerContainer.translatesAutoresizingMaskIntoConstraints = true
            navContainer.translatesAutoresizingMaskIntoConstraints = true
            table.translatesAutoresizingMaskIntoConstraints = true

            let safe = view.safeAreaInsets
            let w = view.bounds.width
            let h = view.bounds.height

            let headerH: CGFloat = 90
            let navH: CGFloat = 90

            // Header at top
            headerContainer.frame = CGRect(
                x: 0,
                y: safe.top,
                width: w,
                height: headerH
            )

            // Nav at bottom
            navContainer.frame = CGRect(
                x: 0,
                y: h - safe.bottom - navH,
                width: w,
                height: navH
            )

            // Table fills the middle
            let tableY = headerContainer.frame.maxY
            let tableBottom = navContainer.frame.minY
            table.frame = CGRect(
                x: 0,
                y: tableY,
                width: w,
                height: max(0, tableBottom - tableY)
            )

            print("header:", headerContainer.frame)
            print("table:", table.frame)
            print("nav:", navContainer.frame)
        }

    ///
    // MARK: - Lifecycle


    override func viewDidLoad() {
        super.viewDidLoad()
        
//        table.separatorStyle = .none
//
//        headerContainer.backgroundColor = .systemBlue
//        navContainer.backgroundColor = .systemBlue
//        table.backgroundColor = .systemBackground
//        

            self.title = "My Donations"

//            // ✅ Paint the navigation bar blue
//            let appearance = UINavigationBarAppearance()
//            appearance.configureWithOpaqueBackground()
//            appearance.backgroundColor = .systemBlue
//            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
//            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
//
//            navigationController?.navigationBar.standardAppearance = appearance
//            navigationController?.navigationBar.scrollEdgeAppearance = appearance
//            navigationController?.navigationBar.compactAppearance = appearance
//            navigationController?.navigationBar.tintColor = .white   // back button color
//
//          

        // Table setup (same style as your Orders)
        table.dataSource = self
        table.delegate = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 100
        table.tableFooterView = UIView()

        showEmptyPlaceholder(message: "Loading…")
        loadDonations()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadDonations()
    }

    
    
    
    // MARK: - Load Donations (same idea as loadOrders)
    private func loadDonations() {
        // Choose ONE donor id approach:

        // Option A (recommended): use logged-in Firebase user
//        guard let donorIdValue = Auth.auth().currentUser?.uid else {
//            donations = []
//            showEmptyPlaceholder(message: "Please log in to view donations.")
//            table.reloadData()
//            return
//        }

        // Option B: hard-coded for testing
         let donorIdValue = "testUser123"

        db.collection("donations")
            .whereField("donorId", isEqualTo: donorIdValue)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Firestore error:", error)
                    self.donations = []
                    self.showEmptyPlaceholder(message: "Failed to load donations.")
                    self.table.reloadData()
                    return
                }

                let docs = snapshot?.documents ?? []

                self.donations = docs.compactMap { doc in
                    let data = doc.data()

                    guard
                        let method = data["donationMethod"] as? String,
                        let status = data["status"] as? String,
                        let createdAt = data["createdAt"] as? Timestamp
                    else {
                        print("⚠️ Skipping donation \(doc.documentID) (missing donationMethod/status/createdAt)")
                        return nil
                    }

                    let donationID = (data["id"] as? String) ?? doc.documentID

                    return DonationHistoryItem(
                        donationID: donationID,
                        method: method,
                        createdAt: createdAt,
                        status: status
                    )
                }

                if self.donations.isEmpty {
                    self.showEmptyPlaceholder(message: "No donations yet.")
                } else {
                    self.hideEmptyPlaceholder()
                }

                self.table.reloadData()
            }
    }

    private func showEmptyPlaceholder(message: String) {
        let label = UILabel(frame: table.bounds)        // ✅ give it a frame
        label.text = message
        label.textColor = .gray
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20)
        label.numberOfLines = 0
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight] // ✅ keep it sized

        table.backgroundView = label
        table.separatorStyle = .none
    }

    private func hideEmptyPlaceholder() {
        table.backgroundView = nil
        table.separatorStyle = .none
    }


}







// MARK: - Table DataSource + Delegate
extension HistoryViewController: UITableViewDataSource, UITableViewDelegate {

    

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        donations.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "DonationCell",
            for: indexPath
        ) as? DonationCell else {
            return UITableViewCell()
        }

        let donation = donations[indexPath.row]
        let dateString = dateFormatter.string(from: donation.createdAt.dateValue())

        cell.donationIDLabel.text = "ID: \(donation.donationID)"
        cell.methodLabel.text = "Method: \(donation.method)"
        cell.dateLabel.text = dateString
        cell.statusLabel.text = donation.status

        // 🔴 PUT IT HERE (TEMPORARY TEST)
        cell.donationIDLabel.textColor = .systemBlue

        return cell
        
    }
    
    
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showDonationDetails" else { return }

        guard let detailsVC = segue.destination as? DonationDetailsViewController else { return }

        // sender IS the tapped cell
        guard let cell = sender as? UITableViewCell else { return }

        // get indexPath from the cell
        guard let indexPath = table.indexPath(for: cell) else { return }

        // pass selected donation
        detailsVC.donation = donations[indexPath.row]
    }




}














//history based on roles
//
//import UIKit
//import FirebaseFirestore
//import FirebaseAuth
//
//// MARK: - Model (History list only)
//struct DonationHistoryItem {
//    let donationID: String
//    let method: String
//    let createdAt: Timestamp
//    let status: String
//}
//
//struct DonationDetails {
//    let donationID: String
//    let category: String
//    let createdAt: Timestamp
//    let donationMethod: String
//    let donorId: String
//    let imageUrl: String
//    let impactType: String
//    let item: String
//    let quantity: Int
//    let status: String
//}
//
//final class HistoryViewController: UIViewController {
//
//    // MARK: - Outlets (from storyboard)
//    @IBOutlet weak var headerContainer: UIView!
//    @IBOutlet weak var navContainer: UIView!
//    @IBOutlet weak var table: UITableView!
//    
//    
//
//    // Keep references if you need them later
//    private var headerView: HeaderView?
//    private var bottomNav: BottomNavView?
//
//    // Make sure we only add them once
//    private var didSetupViews = false
//
//    
//    // MARK: - Firestore
//    private let db = Firestore.firestore()
//    private var donations: [DonationHistoryItem] = []
//
//    // Date formatter (reuse)
//    private lazy var dateFormatter: DateFormatter = {
//        let f = DateFormatter()
//        f.dateStyle = .medium
//        f.timeStyle = .short
//        return f
//    }()
//
//    
//    
//    ///
//    override func viewDidLayoutSubviews() {
//            super.viewDidLayoutSubviews()
//
//            // ✅ Hard-coded layout (ignores Auto Layout)
//            // IMPORTANT: remove/disable storyboard constraints for these views,
//            // or they may override your frames.
//            headerContainer.translatesAutoresizingMaskIntoConstraints = true
//            navContainer.translatesAutoresizingMaskIntoConstraints = true
//            table.translatesAutoresizingMaskIntoConstraints = true
//
//            let safe = view.safeAreaInsets
//            let w = view.bounds.width
//            let h = view.bounds.height
//
//            let headerH: CGFloat = 90
//            let navH: CGFloat = 90
//
//            // Header at top
//            headerContainer.frame = CGRect(
//                x: 0,
//                y: safe.top,
//                width: w,
//                height: headerH
//            )
//
//            // Nav at bottom
//            navContainer.frame = CGRect(
//                x: 0,
//                y: h - safe.bottom - navH,
//                width: w,
//                height: navH
//            )
//
//            // Table fills the middle
//            let tableY = headerContainer.frame.maxY
//            let tableBottom = navContainer.frame.minY
//            table.frame = CGRect(
//                x: 0,
//                y: tableY,
//                width: w,
//                height: max(0, tableBottom - tableY)
//            )
//
//            print("header:", headerContainer.frame)
//            print("table:", table.frame)
//            print("nav:", navContainer.frame)
//        }
//
//    ///
//    // MARK: - Lifecycle
//
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
////        table.separatorStyle = .none
//
////        headerContainer.backgroundColor = .systemBlue
////        navContainer.backgroundColor = .systemBlue
////        table.backgroundColor = .systemBackground
//        
//        
//        self.title = "My Donations"
//
//        // Table setup (same style as your Orders)
//        table.dataSource = self
//        table.delegate = self
//        table.rowHeight = UITableView.automaticDimension
//        table.estimatedRowHeight = 100
//        table.tableFooterView = UIView()
//
//        showEmptyPlaceholder(message: "Loading…")
//        loadDonations()
//
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        loadDonations()
//    }
//
//    
//    
//    
//    // MARK: - Load Donations (same idea as loadOrders)
//    private func loadDonations() {
//        // Choose ONE donor id approach:
//
//        // Option A (recommended): use logged-in Firebase user
////        guard let donorIdValue = Auth.auth().currentUser?.uid else {
////            donations = []
////            showEmptyPlaceholder(message: "Please log in to view donations.")
////            table.reloadData()
////            return
////        }
//
//        // Option B: hard-coded for testing
//         let donorIdValue = "testUser123"
//
//        db.collection("donations")
//            .whereField("donorId", isEqualTo: donorIdValue)
//            .getDocuments { [weak self] snapshot, error in
//                guard let self = self else { return }
//
//                if let error = error {
//                    print("Firestore error:", error)
//                    self.donations = []
//                    self.showEmptyPlaceholder(message: "Failed to load donations.")
//                    self.table.reloadData()
//                    return
//                }
//
//                let docs = snapshot?.documents ?? []
//
//                self.donations = docs.compactMap { doc in
//                    let data = doc.data()
//
//                    guard
//                        let method = data["donationMethod"] as? String,
//                        let status = data["status"] as? String,
//                        let createdAt = data["createdAt"] as? Timestamp
//                    else {
//                        print("⚠️ Skipping donation \(doc.documentID) (missing donationMethod/status/createdAt)")
//                        return nil
//                    }
//
//                    let donationID = (data["id"] as? String) ?? doc.documentID
//
//                    return DonationHistoryItem(
//                        donationID: donationID,
//                        method: method,
//                        createdAt: createdAt,
//                        status: status
//                    )
//                }
//
//                if self.donations.isEmpty {
//                    self.showEmptyPlaceholder(message: "No donations yet.")
//                } else {
//                    self.hideEmptyPlaceholder()
//                }
//
//                self.table.reloadData()
//            }
//    }
//
//    private func showEmptyPlaceholder(message: String) {
//        let label = UILabel(frame: table.bounds)        // ✅ give it a frame
//        label.text = message
//        label.textColor = .gray
//        label.textAlignment = .center
//        label.font = UIFont.systemFont(ofSize: 20)
//        label.numberOfLines = 0
//        label.autoresizingMask = [.flexibleWidth, .flexibleHeight] // ✅ keep it sized
//
//        table.backgroundView = label
//        table.separatorStyle = .none
//    }
//
//    private func hideEmptyPlaceholder() {
//        table.backgroundView = nil
//        table.separatorStyle = .none
//    }
//
//
//}
//
//
//
//
//
//
//
//// MARK: - Table DataSource + Delegate
//extension HistoryViewController: UITableViewDataSource, UITableViewDelegate {
//
//    
//
//    func numberOfSections(in tableView: UITableView) -> Int { 1 }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        donations.count
//    }
//
//    func tableView(_ tableView: UITableView,
//                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//
//        guard let cell = tableView.dequeueReusableCell(
//            withIdentifier: "DonationCell",
//            for: indexPath
//        ) as? DonationCell else {
//            return UITableViewCell()
//        }
//
//        let donation = donations[indexPath.row]
//        let dateString = dateFormatter.string(from: donation.createdAt.dateValue())
//
//        cell.donationIDLabel.text = "ID: \(donation.donationID)"
//        cell.methodLabel.text = "Method: \(donation.method)"
//        cell.dateLabel.text = dateString
//        cell.statusLabel.text = donation.status
//
//        // 🔴 PUT IT HERE (TEMPORARY TEST)
//        cell.donationIDLabel.textColor = .systemBlue
//
//        return cell
//        
//    }
//    
//    
//    
//    
//    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        guard segue.identifier == "showDonationDetails" else { return }
//
//        guard let detailsVC = segue.destination as? DonationDetailsViewController else { return }
//
//        // sender IS the tapped cell
//        guard let cell = sender as? UITableViewCell else { return }
//
//        // get indexPath from the cell
//        guard let indexPath = table.indexPath(for: cell) else { return }
//
//        // pass selected donation
//        detailsVC.donation = donations[indexPath.row]
//    }
//
//
//
//
//}
//
//
