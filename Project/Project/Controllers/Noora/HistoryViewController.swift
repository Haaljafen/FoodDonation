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


final class HistoryViewController: BaseChromeViewController {
    


    // MARK: - Outlets (from storyboard)
    @IBOutlet weak var table: UITableView!


    // MARK: - Firestore
    private let db = Firestore.firestore()
    private var donations: [DonationHistoryItem] = []

    
    private var didResolveRole = false

    
//    ///hard coded id for testing case
//    private let TEST_USER_ID: String? = "nvjfqWavDePSwn28xbHT4aUoEUC2"
//    private let FORCE_TEST_ROLE: UserRole? = nil     // e.g. .admin / .donor / .collector
//    ///
    
    
    //defualt role (for the actual app role)
    private let TEST_USER_ID: String? = nil
    private let FORCE_TEST_ROLE: UserRole? = nil


    // Date formatter (reuse)
    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()


    // MARK: - Lifecycle
    override func viewDidLoad() {
                
        super.viewDidLoad()

//        DonationInsert.insertTestDonation()

        guard Auth.auth().currentUser != nil || TEST_USER_ID != nil else {
            donations.removeAll()
            showEmptyPlaceholder(message: "Please log in.")
            table.reloadData()
            return
        }

        // Table setup
        table.dataSource = self
        table.delegate = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 100
        table.tableFooterView = UIView()

        showEmptyPlaceholder(message: "Loading…")
        
        
        
        ///        // If you forced a role for testing, skip fetching role from Firestore.
        if let forcedRole = FORCE_TEST_ROLE {
            self.currentRole = forcedRole
            self.didResolveRole = true
                        self.updateTitleForRole(forcedRole)
                        self.loadDonationsForCurrentRole()
                        return
                }
        ///

        // 1) Fetch role then 2) load donations
        fetchCurrentUserRole { [weak self] (role: UserRole?) in
                    guard let self = self else { return }

                    // require role (no default)
                    guard let role = role else {
//                        self.currentRole = nil
                        self.didResolveRole = false
                        self.updateTitleForUnknownRole()
                        self.donations = []
                        self.showEmptyPlaceholder(message: "Role missing/invalid. Fix Users/{uid}.role")
                        self.table.reloadData()
                        return
                    }

                    self.currentRole = role
                    self.didResolveRole = true
                    self.updateTitleForRole(role)
                    self.loadDonationsForCurrentRole()
            }
        
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Hide system nav bar on History (because History uses a custom header)
        navigationController?.setNavigationBarHidden(true, animated: false)

        
        // ALWAYS clear UI if no user(in case)
            guard Auth.auth().currentUser != nil || TEST_USER_ID != nil else {
                donations.removeAll()
                showEmptyPlaceholder(message: "Please log in.")
                table.reloadData()
                didResolveRole = false
                return
            }
//        print("Auth uid =", Auth.auth().currentUser?.uid as Any,
//              "anonymous =", Auth.auth().currentUser?.isAnonymous as Any)
        
        //  Refresh using already-known role
        guard didResolveRole else { return }
        updateTitleForRole(currentRole)
        loadDonationsForCurrentRole()
    }

    
    //
    private func resolvedUserIdForTestingOrAuth() -> String? {
           return TEST_USER_ID ?? Auth.auth().currentUser?.uid
    }
    //
    
    // MARK: - Role
    private func fetchCurrentUserRole(completion: @escaping (UserRole?) -> Void) {
        
        //might need it later
//        guard let uid = Auth.auth().currentUser?.uid else {
//        print("❌ No uid (testing/auth).")
//            completion(nil)
//            return
//        }

        
        guard let uid = resolvedUserIdForTestingOrAuth() else {
                    print("❌ No uid (user not logged in).")
                    completion(nil)
                    return
        }
        
        
        db.collection("Users").document(uid).getDocument { snap, error in
            if let error = error {
                print("❌ Failed to fetch user role:", error)
                completion(nil)
                return
            }

            
            let roleStr = ((snap?.data()?["role"] as? String) ?? "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased()
            
//            print("🧩 role from Firestore =", roleStr, " doc exists =", snap?.exists ?? false)

                    completion(UserRole(rawValue: roleStr))
            
        }
    }
    
    
    private func updateTitleForUnknownRole() {
            DispatchQueue.main.async {
                self.title = "Donations"
            }
    }

    
    private func updateTitleForRole(_ role: UserRole) {
        
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
        
//        guard let role = currentRole else {
//                    donations = []
//                    showEmptyPlaceholder(message: "Role not set. Cannot load donations.")
//                    table.reloadData()
//                    return
//                }
        
        let role = currentRole

        guard let uid = resolvedUserIdForTestingOrAuth() else {
                   donations = []
                   showEmptyPlaceholder(message: "Please log in to view donations.")
                   table.reloadData()
                   return
               }

        
//        //might need it later
//        guard let uid = Auth.auth().currentUser?.uid else {
//            donations = []
//            showEmptyPlaceholder(message: "Please log in to view donations.")
//            table.reloadData()
//            return
//        }
        
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

    //  Role-based segue:

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if currentRole == .ngo {
            ///here the prop
                    performSegue(withIdentifier: "showNGODonationDetails", sender: indexPath)
                } else {
                    performSegue(withIdentifier: "showDonationDetails", sender: indexPath)
                }
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
           guard let indexPath = sender as? IndexPath else { return }
           let selected = donations[indexPath.row]

           if let detailsVC = segue.destination as? DonationDetailsViewController {
               detailsVC.donation = selected
               detailsVC.roleFromHistory = currentRole.rawValue  // PASS ROLE (as String) into details

           }
       }
}
