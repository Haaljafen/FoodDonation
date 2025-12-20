import UIKit
import FirebaseFirestore
import FirebaseAuth

final class DonationDetailsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private let db = Firestore.firestore()

    // Passed from History
    var donation: DonationHistoryItem!

    // ✅ PASSED ROLE from HistoryVC
       var roleFromHistory: String?
    
    
    // donations/{id}
    private var details: [String: Any] = [:]

    // pickupRequests (matched by donationId)
    private var pickup: [String: Any] = [:]

    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    // ✅ Allowed statuses (match your pipeline wording)
    private let statusOptions: [String] = ["pending", "accepted", "collected", "delivered"]

    // ✅ Role
    private enum AppRole: String { case admin, donor, ngo }
    private var currentRole: AppRole = .donor

    override func viewDidLoad() {
        super.viewDidLoad()

//        tableView.rowHeight = UITableView.automaticDimension
//        tableView.estimatedRowHeight = 180
        tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 200

        title = ""
        setupTableView()

        // ✅ Get role (collector vs donor/admin) then refresh section 1 UI
//        fetchCurrentUserRole()
        if let r = roleFromHistory?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
           let parsed = AppRole(rawValue: r) {
            currentRole = parsed
        } else {
            fetchCurrentUserRole()
        }

        
        fetchDonationDetails()
        fetchPickupRequest()
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 180
    }

    // MARK: - Role
    private func fetchCurrentUserRole() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("Users").document(uid).getDocument { [weak self] snap, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ fetch role error:", error)
                self.currentRole = .donor
            } else {
                let roleStr = ((snap?.data()?["role"] as? String) ?? "donor")
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                                .lowercased()

                            print("🧩 details role =", roleStr)

                            self.currentRole = AppRole(rawValue: roleStr) ?? .donor
            }

            // Refresh section 1 (pipeline vs button)
            self.tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
        }
    }

    // MARK: - Fetch
    private func fetchDonationDetails() {
        let id = donation.donationID

        db.collection("donations").document(id).getDocument { [weak self] snap, err in
            guard let self = self else { return }

            if let err = err {
                print("❌ fetch donation details error:", err)
                self.details = [:]
                self.tableView.reloadData()
                return
            }

            self.details = snap?.data() ?? [:]
            self.tableView.reloadData()
        }
    }

    private func fetchPickupRequest() {
        db.collection("pickupRequests")
            .whereField("donationId", isEqualTo: donation.donationID)
            .limit(to: 1)
            .getDocuments { [weak self] snap, err in
                guard let self = self else { return }

                if let err = err {
                    print("❌ fetch pickup request error:", err)
                    self.pickup = [:]
                    self.tableView.reloadData()
                    return
                }

                self.pickup = snap?.documents.first?.data() ?? [:]
                self.tableView.reloadData()
            }
    }

    // MARK: - Status Helpers
    private func currentStatusString() -> String {
        return (details["status"] as? String) ?? donation.status
    }

    // ✅ Collector-only
    private func presentStatusPicker() {
        guard currentRole == .ngo else { return }

        let current = currentStatusString().lowercased()
        let alert = UIAlertController(
            title: "Update Status",
            message: "Current: \(current.capitalized)",
            preferredStyle: .actionSheet
        )

        for s in statusOptions {
            let action = UIAlertAction(title: s.capitalized, style: .default) { [weak self] _ in
                self?.updateDonationStatus(to: s)
            }
            if s == current { action.isEnabled = false }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPad safety
        if let pop = alert.popoverPresentationController {
            pop.sourceView = self.view
            pop.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 1, height: 1)
        }

        present(alert, animated: true)
    }

    // ✅ Collector-only (updates Firestore)
    private func updateDonationStatus(to newStatus: String) {
        guard currentRole == .ngo else { return }

        let id = donation.donationID
        view.isUserInteractionEnabled = false

        db.collection("donations").document(id).updateData([
            "status": newStatus
        ]) { [weak self] error in
            guard let self = self else { return }
            self.view.isUserInteractionEnabled = true

            if let error = error {
                print("❌ Failed to update status:", error)
                self.showSimpleAlert(title: "Error", message: "Could not update status. Please try again.")
                return
            }

            self.details["status"] = newStatus

            // Refresh only section 1 (pipeline/button)
            self.tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
        }
    }

    private func showSimpleAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - UITableView
extension DonationDetailsViewController: UITableViewDelegate, UITableViewDataSource {

    // MARK: - Section spacing
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0 : 14
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }

    func numberOfSections(in tableView: UITableView) -> Int { 4 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch indexPath.section {

        case 0: // Header
            let cell = tableView.dequeueReusableCell(withIdentifier: "DonationHeaderCell", for: indexPath) as! DonationHeaderCell
            cell.configure(title: "Donation Status", donationID: donation.donationID)
            return cell

        case 1: // ✅ donor/admin = pipeline, collector = change-status button
            let status = currentStatusString()

            if currentRole == .ngo {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: "DonationStatusActionCell",
                    for: indexPath
                ) as! DonationStatusActionCell

                cell.configure(currentStatus: status, buttonTitle: "Change Status") { [weak self] in
                    self?.presentStatusPicker()
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: "DonationTrackerCell",
                    for: indexPath
                ) as! DonationTrackerCell

                cell.configure(currentStatus: status)
                return cell
            }

        case 2: // Donation Details
            let cell = tableView.dequeueReusableCell(withIdentifier: "DonationDetailsCell", for: indexPath) as! DonationDetailsCell

            let item = (details["item"] as? String) ?? "—"
            let category = (details["category"] as? String) ?? "—"

            let quantityInt: Int = {
                if let q = details["quantity"] as? Int { return q }
                if let q = details["quantity"] as? Double { return Int(q) }
                return 0
            }()

            let impact = (details["impactType"] as? String) ?? "—"

            cell.configure(
                item: item,
                quantity: "\(quantityInt)",
                category: category,
                impact: impact
            )
            return cell

        case 3: // Pickup / Dropoff
            let cell = tableView.dequeueReusableCell(withIdentifier: "DonationPickupCell", for: indexPath) as! DonationPickupCell

            let facility = (pickup["facilityName"] as? String) ?? "Not set"

            let method = (pickup["method"] as? String)
                ?? ((details["donationMethod"] as? String) ?? donation.method)

            let dropoffTimestamp = (pickup["dropoffDate"] as? Timestamp)
                ?? ((details["createdAt"] as? Timestamp) ?? donation.createdAt)

            let dateFormatterOnly = DateFormatter()
            dateFormatterOnly.dateStyle = .medium
            dateFormatterOnly.timeStyle = .none

            let dateText = dateFormatterOnly.string(from: dropoffTimestamp.dateValue())
            let timeText = (pickup["dropoffTime"] as? String) ?? ""
            let finalDateTime = timeText.isEmpty ? dateText : "\(dateText) at \(timeText)"

            cell.configure(address: facility, dateTime: finalDateTime, method: method)
            return cell

        default:
            return UITableViewCell()
        }
    }
}
