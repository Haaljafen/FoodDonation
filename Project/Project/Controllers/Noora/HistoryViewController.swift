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

final class HistoryViewController: UIViewController {

    // MARK: - Outlets (from storyboard)
    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var navContainer: UIView!
    @IBOutlet weak var table: UITableView!

    // Keep references if you need them later
    private var headerView: HeaderView?
    private var bottomNav: BottomNavView?


    // MARK: - Firestore
    private let db = Firestore.firestore()
    private var donations: [DonationHistoryItem] = []

    // MARK: - Role
    private enum AppRole: String {
        case admin
        case donor
        case ngo
    }

    private var currentRole: AppRole?
    private var didResolveRole = false

    
    ///
    private let TEST_USER_ID: String? = "7yfpJrFgU3YfH1vm8CiGRpwjpjj2"
   // <-- replace with real uid for testing
        // 🔴 OPTIONAL TESTING ONLY: force a role (set nil to use Firestore role)
    private let FORCE_TEST_ROLE: AppRole? = nil         // e.g. .admin / .donor / .collector
///

    // Date formatter (reuse)
    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    // MARK: - Layout (your hard-coded frames)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        headerContainer.translatesAutoresizingMaskIntoConstraints = true
        navContainer.translatesAutoresizingMaskIntoConstraints = true
        table.translatesAutoresizingMaskIntoConstraints = true

        let safe = view.safeAreaInsets
        let w = view.bounds.width
        let h = view.bounds.height

        let headerH: CGFloat = 90
        let navH: CGFloat = 90

        headerContainer.frame = CGRect(x: 0, y: safe.top, width: w, height: headerH)
        navContainer.frame = CGRect(x: 0, y: h - safe.bottom - navH, width: w, height: navH)

        let tableY = headerContainer.frame.maxY
        let tableBottom = navContainer.frame.minY
        table.frame = CGRect(x: 0, y: tableY, width: w, height: max(0, tableBottom - tableY))
    }

    
//    private var didResolveRole = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Table setup
        table.dataSource = self
        table.delegate = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 100
        table.tableFooterView = UIView()

        showEmptyPlaceholder(message: "Loading…")
        
        
        ///
        ///        // If you forced a role for testing, skip fetching role from Firestore.
        if let forcedRole = FORCE_TEST_ROLE {
                    currentRole = forcedRole
                    didResolveRole = true   // ✅ ADDED
                    updateTitleForRole()
                    loadDonationsForCurrentRole()
                    return
                }
        ///

        // 1) Fetch role then 2) load donations
        fetchCurrentUserRole { [weak self] role in
                    guard let self = self else { return }

                    // ✅ ADDED: require role (no default)
                    guard let role = role else {
                        self.currentRole = nil
                        self.didResolveRole = false
                        self.updateTitleForUnknownRole() // ✅ ADDED
                        self.donations = []
                        self.showEmptyPlaceholder(message: "Role missing/invalid. Fix Users/{uid}.role")
                        self.table.reloadData()
                        return
                    }

                    self.currentRole = role
                    self.didResolveRole = true
                    self.updateTitleForRole()
                    self.loadDonationsForCurrentRole()
            }
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Refresh using already-known role
        guard didResolveRole else { return }
        loadDonationsForCurrentRole()
    }
    
    //delete it later(this is only to test)
    private func resolvedUserIdForTestingOrAuth() -> String? {
           return TEST_USER_ID ?? Auth.auth().currentUser?.uid
       }
//
    
    // MARK: - Role
    private func fetchCurrentUserRole(completion: @escaping (AppRole?) -> Void) {
        
        //coming back to u
//        guard let uid = Auth.auth().currentUser?.uid else {
//        print("❌ No uid (testing/auth).")
//            completion(nil)
//            return
//        }

        
        //
        let uid = "7yfpJrFgU3YfH1vm8CiGRpwjpjj2"
//
        
        db.collection("Users").document(uid).getDocument { snap, error in
            if let error = error {
                print("❌ Failed to fetch user role:", error)
                completion(nil)
                return
            }

//            let roleStr = snap?.data()?["role"] as? String ?? ""
//            completion(AppRole(rawValue: roleStr))
            
            let roleStr = ((snap?.data()?["role"] as? String) ?? "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased()
            
            print("🧩 role from Firestore =", roleStr, " doc exists =", snap?.exists ?? false)

                    completion(AppRole(rawValue: roleStr))
            
            
        }
    }
    
    private func updateTitleForUnknownRole() {
            DispatchQueue.main.async {
                self.title = "Donations"
            }
        }

    private func updateTitleForRole() {
        
        
        guard let role = currentRole else {
                    updateTitleForUnknownRole()
                    return
                }
        
        
        DispatchQueue.main.async {
            switch role {
            case .admin:
                self.title = "All Donations"
            case .ngo:
                self.title = "Accepted Donations"
            default:
                self.title = "My Donations"
            }
        }
    }

    // MARK: - Load Donations (role-based)
    private func loadDonationsForCurrentRole() {
        showEmptyPlaceholder(message: "Loading…")
        
        guard let role = currentRole else {
                    donations = []
                    showEmptyPlaceholder(message: "Role not set. Cannot load donations.")
                    table.reloadData()
                    return
                }

        
//        //comming back to u later
//        guard let uid = Auth.auth().currentUser?.uid else {
//            donations = []
//            showEmptyPlaceholder(message: "Please log in to view donations.")
//            table.reloadData()
//            return
//        }
        
        let uid = "7yfpJrFgU3YfH1vm8CiGRpwjpjj2"
//    🔴 HARD-CODED donorId

            print("🧪 Using hard-coded donorId:", uid)


        var query: Query = db.collection("donations")
//            .order(by: "createdAt", descending: true)

        switch role {
        case .admin:
            // all donations
            break

        case .donor:
            query = query.whereField("donorId", isEqualTo: uid)

        case .ngo:
            // ✅ only donations accepted by this collector
            query = query.whereField("collectorId", isEqualTo: uid)

//        default:
//            donations = []
//            showEmptyPlaceholder(message: "No permission to view donations.")
//            table.reloadData()
//            return
        }

        query.getDocuments { [weak self] snapshot, error in
                   guard let self = self else { return }

                   if let error = error {
                       print("❌ Firestore error:", error)
                       self.donations = []
                       self.showEmptyPlaceholder(message: "Failed to load donations.")
                       self.table.reloadData()
                       return
                   }

                   let docs = snapshot?.documents ?? []
                   print("📦 docs count =", docs.count)

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
            
            
//            print("👤 uid =", uid)
//            print("🎭 currentRole =", currentRole.rawValue)
//            print("📌 filtering donorId/collectorId with =", uid)

        }
    }

    // MARK: - Placeholder UI
    private func showEmptyPlaceholder(message: String) {
        let label = UILabel(frame: table.bounds)
        label.text = message
        label.textColor = .gray
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20)
        label.numberOfLines = 0
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        table.backgroundView = label
        table.separatorStyle = .none
    }

    private func hideEmptyPlaceholder() {
        table.backgroundView = nil
        table.separatorStyle = .singleLine
    }
}

// MARK: - Segue helper
//(might delete it later)

//private var selectedDonation: DonationHistoryItem?
//

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

        return cell
    }

    // ✅ Role-based segue:
    // - donor/admin: showDonationDetails
    // - collector: showCollectorDonation (you create this segue)
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if currentRole == .ngo {
            ///here the prop
                    performSegue(withIdentifier: "showNGODonationDetails", sender: indexPath)
                } else {
                    performSegue(withIdentifier: "showDonationDetails", sender: indexPath)
                }
    }

//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        guard let indexPath = sender as? IndexPath else { return }
//        let selected = donations[indexPath.row]
//
//        if segue.identifier == "showDonationDetails" {
//            guard let detailsVC = segue.destination as? DonationDetailsViewController else { return }
//            detailsVC.donation = selected
//        }
//
//        if segue.identifier == "showCollectorDonation" {
//            guard let collectorVC = segue.destination as? DonationDetailsViewController else { return }
//            collectorVC.donation = selected
//        }
//    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
           guard let indexPath = sender as? IndexPath else { return }
           let selected = donations[indexPath.row]

           if let detailsVC = segue.destination as? DonationDetailsViewController {
               detailsVC.donation = selected

               // ✅ PASS ROLE (as String) into details
               detailsVC.roleFromHistory = currentRole?.rawValue
           }
       }
}





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
//        
//        super.viewDidLoad()
//        
//        
////        DonationInsert.insertDonation()
//
////        table.separatorStyle = .none
////
////        headerContainer.backgroundColor = .systemBlue
////        navContainer.backgroundColor = .systemBlue
////        table.backgroundColor = .systemBackground
////        
//
//            self.title = "My Donations"
//
////            // ✅ Paint the navigation bar blue
////            let appearance = UINavigationBarAppearance()
////            appearance.configureWithOpaqueBackground()
////            appearance.backgroundColor = .systemBlue
////            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
////            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
////
////            navigationController?.navigationBar.standardAppearance = appearance
////            navigationController?.navigationBar.scrollEdgeAppearance = appearance
////            navigationController?.navigationBar.compactAppearance = appearance
////            navigationController?.navigationBar.tintColor = .white   // back button color
////
////          
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
//         let donorIdValue = "7yfpJrFgU3YfH1vm8CiGRpwjpjj2"
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
////        cell.donationIDLabel.textColor = .systemBlue
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
