//
//  HistoryViewController.swift
//  Takaffal
//
//  Created by Noora Humaid on 16/12/2025.
//

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

    //defualt role
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

        // 1) Fetch role then 2) load Donations
        fetchCurrentUserRole { [weak self] (role: UserRole?) in
                    guard let self = self else { return }

                    // require role (no default)
                    guard let role = role else {
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

        
        //  Refresh using already-known role
        guard let role = currentRole else { return }
        updateTitleForRole(role)
//        loadDonationsForCurrentRole()

    }

    private func redonateDonation(donationID: String) {
            Firestore.firestore()
                .collection("Donations")
                .whereField("id", isEqualTo: donationID)
                .getDocuments { snapshot, error in
                    guard let donationData = snapshot?.documents.first?.data() else {
                        print("❌ Original donation not found")
                        return
                    }

                    DonationRedonate.redonate(from: donationData) { success in
                        DispatchQueue.main.async {
                            if success {
                                let alert = UIAlertController(
                                    title: "Success",
                                    message: "Donation re-created with status pending",
                                    preferredStyle: .alert
                                )
                                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                                    // ✅ refresh history list
                                    self.loadDonationsForCurrentRole()
                                })
                                self.present(alert, animated: true)
                            }
                        }
                    }
                }
        }
    
    private func resolvedUserIdForTestingOrAuth() -> String? {
           return TEST_USER_ID ?? Auth.auth().currentUser?.uid
    }
    
    // MARK: - Role
    private func fetchCurrentUserRole(completion: @escaping (UserRole?) -> Void) {

        
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
        //
        guard didResolveRole else {
               print("⏳ Role not resolved yet — skipping load")
               return
           }
        //
        
        
        guard let role = currentRole else {
            donations = []
            showEmptyPlaceholder(message: "Role not resolved.")
            table.reloadData()
            return
        }

        guard let uid = resolvedUserIdForTestingOrAuth() else {
                   donations = []
                   showEmptyPlaceholder(message: "Please log in to view Donations.")
                   table.reloadData()
                   return
               }

        
        var query: Query = db.collection("Donations")
            .order(by: "createdAt", descending: true)


        switch role {
        case .admin:
            // all Donations
            break

        case .donor:
            query = query.whereField("donorId", isEqualTo: uid)

        case .ngo:
            // ✅ only Donations accepted by this collector
            query = query.whereField("collectorId", isEqualTo: uid)

        }

        query.getDocuments { [weak self] snapshot, error in
                   guard let self = self else { return }

                   if let error = error {
                       print("❌ Firestore error:", error)
                       self.donations = []
                       self.showEmptyPlaceholder(message: "Failed to load Donations.")
//                       self.showEmptyPlaceholder(message: "No donations yet.")
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
                self.showEmptyPlaceholder(message: "No Donations yet.")
            } else {
                self.hideEmptyPlaceholder()
            }

            self.table.reloadData()

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
        cell.methodLabel.textColor = .label

        cell.donationIDLabel.text = "ID: \(donation.donationID)"
        cell.methodLabel.text = "Method: \(donation.method.displayText)"
        cell.dateLabel.text = dateString
        cell.statusLabel.text = donation.status.displayText

        // ✅ Show redonate button ONLY if completed
            cell.redonateButton.isHidden = donation.status != "delivered"

            // ✅ Handle redonate button tap
            cell.onRedonateTapped = { [weak self] in
                guard let self = self else { return }

                let alert = UIAlertController(
                    title: "Confirmation",
                    message: "Are you sure you want to re-donate?",
                    preferredStyle: .alert
                )

                alert.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
                    Firestore.firestore()
                        .collection("Donations")
                        .whereField("id", isEqualTo: donation.donationID)
                        .getDocuments { snapshot, _ in
                            guard let donationData = snapshot?.documents.first?.data() else { return }

                            DonationRedonate.redonate(from: donationData) { success in
                                if success {
                                    DispatchQueue.main.async {
                                        let successAlert = UIAlertController(
                                            title: "Success",
                                            message: "Re-donated successfully",
                                            preferredStyle: .alert
                                        )
                                        successAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                                            self.loadDonationsForCurrentRole()
                                        })
                                        self.present(successAlert, animated: true)
                                    }
                                }
                            }
                        }
                })

                alert.addAction(UIAlertAction(title: "No", style: .cancel))
                self.present(alert, animated: true)
            }
        
        return cell
    }

    //  Role-based segue:

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if currentRole == .ngo {
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
               detailsVC.roleFromHistory = currentRole?.rawValue  // PASS ROLE (as String) into details

           }
       }


    // MARK: - Redonate Button
    
    
}




extension String {
    var displayText: String {
        let spaced = self.replacingOccurrences(
            of: "([a-z])([A-Z])",
            with: "$1 $2",
            options: .regularExpression
        )

        return spaced.capitalized
    }
}
