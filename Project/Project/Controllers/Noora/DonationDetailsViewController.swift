import UIKit
import FirebaseFirestore

final class DonationDetailsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private let db = Firestore.firestore()

    // Passed from History
    var donation: DonationHistoryItem!

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

    override func viewDidLoad() {
        super.viewDidLoad()
        
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 180
    

        
        //
//        view.backgroundColor = .systemGroupedBackground
//        tableView.backgroundColor = .clear
////

        title = ""
        setupTableView()
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
}

// MARK: - UITableView
extension DonationDetailsViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    ///
    // MARK: - Section spacing
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0 : 14   // spacing between cells
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }

    ///

    func numberOfSections(in tableView: UITableView) -> Int { 4 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch indexPath.section {

        case 0: // Header
            let cell = tableView.dequeueReusableCell(withIdentifier: "DonationHeaderCell", for: indexPath) as! DonationHeaderCell
            cell.configure(title: "Donation Status", donationID: donation.donationID)
            return cell

        case 1: // Tracker
            let cell = tableView.dequeueReusableCell(withIdentifier: "DonationTrackerCell", for: indexPath) as! DonationTrackerCell
            let status = (details["status"] as? String) ?? donation.status
            cell.configure(currentStatus: status)
            return cell

        case 2: // Donation Details (simplified)
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "DonationDetailsCell",
                for: indexPath
            ) as! DonationDetailsCell

            let item = (details["item"] as? String) ?? "—"
            let category = (details["category"] as? String) ?? "—"

            let quantityInt: Int = {
                if let q = details["quantity"] as? Int { return q }
                if let q = details["quantity"] as? Double { return Int(q) }
                return 0
            }()

            let impact = (details["impactType"] as? String) ?? "—"
//            let imageUrl = (details["imageUrl"] as? String) ?? ""

            cell.configure(
                item: item,
                quantity: "\(quantityInt)",
                category: category,
                impact: impact
//                imageUrlString: imageUrl
            )
            return cell


        case 3: // Pickup / Dropoff
            let cell = tableView.dequeueReusableCell(withIdentifier: "DonationPickupCell", for: indexPath) as! DonationPickupCell

            let facility = (pickup["facilityName"] as? String) ?? "Not set"

            let method = (pickup["method"] as? String)
                ?? ((details["donationMethod"] as? String) ?? donation.method)

            let dropoffTimestamp = (pickup["dropoffDate"] as? Timestamp)
                ?? ((details["createdAt"] as? Timestamp) ?? donation.createdAt)

            // Date only
            let dateFormatterOnly = DateFormatter()
            dateFormatterOnly.dateStyle = .medium
            dateFormatterOnly.timeStyle = .none

            let dateText = dateFormatterOnly.string(from: dropoffTimestamp.dateValue())

            let timeText = (pickup["dropoffTime"] as? String) ?? ""

            let finalDateTime: String
            if timeText.isEmpty {
                finalDateTime = dateText
            } else {
                finalDateTime = "\(dateText) at \(timeText)"
            }


            cell.configure(address: facility, dateTime: finalDateTime, method: method)
            return cell

        default:
            return UITableViewCell()
        }
    }
}



// coming back to u
//  NooraViewController2.swift
//  Takaffal
//
//  Created by Hajar on 01/12/2025.
//
//
//import UIKit
//import FirebaseFirestore
//
//final class DonationDetailsViewController: UIViewController {
//
//    @IBOutlet weak var tableView: UITableView!
//
//    private let db = Firestore.firestore()
//
//    // Passed from History
//    var donation: DonationHistoryItem!
//
//    // Loaded from Firestore (full doc)
//    private var details: DonationDetails?
//
//    // Reuse the same formatter style
//    private lazy var dateFormatter: DateFormatter = {
//        let f = DateFormatter()
//        f.dateStyle = .medium
//        f.timeStyle = .short
//        return f
//    }()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        title = "Donation Details"
//        setupTableView()
//        fetchDonationDetails()
//    }
//
//    private func setupTableView() {
//        tableView.delegate = self
//        tableView.dataSource = self
//        tableView.tableFooterView = UIView()
//    }
//
//    private func fetchDonationDetails() {
//        // Your donationID is either "id" or docID in your list code.
//        let id = donation.donationID
//        
//        db.collection("donations").document(id).getDocument { [weak self] snapshot, error in
//            guard let self = self else { return }
//            
//            if let error = error {
//                print("❌ Details fetch error:", error)
//                self.details = nil
//                self.tableView.reloadData()
//                return
//            }
//            
//            guard let data = snapshot?.data() else {
//                print("⚠️ No details data for donation:", id)
//                self.details = nil
//                self.tableView.reloadData()
//                return
//            }
//            
//            // Parse safely
//            guard
//                let category = data["category"] as? String,
//                let createdAt = data["createdAt"] as? Timestamp,
//                let donationMethod = data["donationMethod"] as? String,
//                let donorId = data["donorId"] as? String,
//                let imageUrl = data["imageUrl"] as? String,
//                let impactType = data["impactType"] as? String,
//                let item = data["item"] as? String,
//                let quantity = data["quantity"] as? Int,
//                let status = data["status"] as? String
//            else {
//                print("⚠️ Missing fields in donation doc:", id)
//                self.details = nil
//                self.tableView.reloadData()
//                return
//            }
//            
//            let donationID = (data["id"] as? String) ?? snapshot!.documentID
//            
//            self.details = DonationDetails(
//                donationID: donationID,
//                category: category,
//                createdAt: createdAt,
//                donationMethod: donationMethod,
//                donorId: donorId,
//                imageUrl: imageUrl,
//                impactType: impactType,
//                item: item,
//                quantity: quantity,
//                status: status
//            )
//            
//            self.tableView.reloadData()
//        }
//    }
//    
//    
//}
//
//
//extension DonationDetailsViewController: UITableViewDelegate, UITableViewDataSource {
//
//    func numberOfSections(in tableView: UITableView) -> Int {
//        // Similar idea to your order status screen
//        return 6
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }
//
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        switch section {
//        case 0: return "Donation"
//        case 1: return "Status"
//        case 2: return "Item"
//        case 3: return "Category"
//        case 4: return "Method"
//        case 5: return "Extra"
//        default: return nil
//        }
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//
//        // Basic “Value1” style cell
//        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
//        cell.selectionStyle = .none
//
//        // While loading, show passed summary
//        guard let d = details else {
//            switch indexPath.section {
//            case 0:
//                cell.textLabel?.text = "ID"
//                cell.detailTextLabel?.text = donation.donationID
//            case 1:
//                cell.textLabel?.text = "Status"
//                cell.detailTextLabel?.text = donation.status
//            case 4:
//                cell.textLabel?.text = "Method"
//                cell.detailTextLabel?.text = donation.method
//            default:
//                cell.textLabel?.text = "Loading…"
//                cell.detailTextLabel?.text = ""
//            }
//            return cell
//        }
//
//        let dateString = dateFormatter.string(from: d.createdAt.dateValue())
//
//        switch indexPath.section {
//        case 0:
//            cell.textLabel?.text = "ID"
//            cell.detailTextLabel?.text = d.donationID
//
//        case 1:
//            cell.textLabel?.text = "Status"
//            cell.detailTextLabel?.text = d.status
//
//        case 2:
//            cell.textLabel?.text = "\(d.item)"
//            cell.detailTextLabel?.text = "Qty: \(d.quantity)"
//
//        case 3:
//            cell.textLabel?.text = "Category"
//            cell.detailTextLabel?.text = d.category
//
//        case 4:
//            cell.textLabel?.text = "Method"
//            cell.detailTextLabel?.text = d.donationMethod
//
//        case 5:
//            // Put multiple key details in “Extra” section
//            cell.textLabel?.numberOfLines = 0
//            cell.detailTextLabel?.numberOfLines = 0
//            cell.textLabel?.text = "Impact / Date"
//            cell.detailTextLabel?.text = "\(d.impactType)\n\(dateString)"
//
//        default:
//            break
//        }
//
//        return cell
//    }
//}
//
