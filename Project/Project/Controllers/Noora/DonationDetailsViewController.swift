//
//  DonationDetailsViewController.swift
//  Takaffal
//
//  Created by Noora Humaid on 17/12/2025.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

final class DonationDetailsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)

        let navy = UIColor(red: 2/255, green: 24/255, blue: 43/255, alpha: 1)



        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = navy
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }



    

    private let db = Firestore.firestore()

    // Passed from History
    var donation: DonationHistoryItem!

    // PASSED ROLE from HistoryVC
       var roleFromHistory: String?
    
    
    // donations/{id}
    private var details: [String: Any] = [:]

    // pickupRequests (matched by donationId)
    private var pickup: [String: Any] = [:]
    // Resolved pickup UI values
    private var pickupAddress: String = "Unavaliable yet"
    private var pickupDateTime: String = "Unavalible yet"


    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    
    // MARK: - Status Helpers
    // NGO-only: one tap moves to the next status in order
    private func toggleToNextStatus() {
        guard currentRole == .ngo else { return }

        let current = currentStatusString()

        // if already delivered -> no next -> do nothing
        guard let next = nextStatus(after: current) else { return }

        updateDonationStatus(to: next)
    }

    
    private func normalized(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func nextStatus(after current: String) -> String? {
        let cur = normalized(current)

        // If current status isn't in the array, start from the first status
        guard let i = statusOptions.firstIndex(of: cur) else {
            return statusOptions.first
        }

        let nextIndex = i + 1
        guard nextIndex < statusOptions.count else { return nil } // already last (delivered)
        return statusOptions[nextIndex]
    }

    private func buttonTitle(for currentStatus: String) -> (title: String, enabled: Bool) {
        if let next = nextStatus(after: currentStatus) {
            return (next.capitalized, true)
        } else {
            return ("Delivered", false)
        }
    }


    
    // Allowed statuses (match your pipeline wording)
    private let statusOptions: [String] = ["pending", "accepted", "collected", "delivered"]

    // MARK: - Role
    private var currentRole: UserRole = .donor

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 200

        title = ""
        
        setupTableView()

        // Get role (collector vs donor/admin) then refresh section 1 UI
        if let r = roleFromHistory?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
           let parsed = UserRole(rawValue: r) {
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


                            self.currentRole = UserRole(rawValue: roleStr) ?? .donor
            }

            // Refresh section 1 (pipeline vs button)
            self.tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
        }
    }

    // MARK: - Fetch
    private func fetchDonationDetails() {
        let id = donation.donationID

        db.collection("Donations").document(id).getDocument { [weak self] snap, err in
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
    
    
    
    private func normalizedMethod(_ raw: String) -> String {
        let m = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if m == "pickup" || m == "locationpickup" {
            return "pickup"
        }

        if m == "dropoff" || m == "drop-off" {
            return "dropoff"
        }

        return m
    }

    
    
    private func fetchPickupRequest() {
        db.collection("PickupRequests")
            .whereField("donationId", isEqualTo: donation.donationID)
            .limit(to: 1)
            .getDocuments { [weak self] snap, err in
                guard let self = self else { return }

                // Defaults
                self.pickup = [:]
                self.pickupAddress = "Not Set yet"
                self.pickupDateTime = "Not Scheduled yet"

                if let err = err {
                    print("❌ fetch pickup request error:", err)
                    self.tableView.reloadData()
                    return
                }

                guard let doc = snap?.documents.first else {
                    // No pickup request yet
                    self.tableView.reloadData()
                    return
                }

                self.pickup = doc.data()

             
                if let ts = self.pickup["pickupDateTime"] as? Timestamp {
                    self.pickupDateTime = self.dateFormatter.string(from: ts.dateValue())
                }

                // Resolve method
                let rawMethod =
                    (self.details["donationMethod"] as? String) ??
                    (self.pickup["method"] as? String) ??
                    self.donation.method

                let method = normalizedMethod(rawMethod)

                // DROP-OFF → use facilityName
                if method == "dropoff" {
                    if let facilityAddress = self.pickup["pickupAddress"] as? String,
                       !facilityAddress.isEmpty {
                        self.pickupAddress = facilityAddress
                    }

                    self.tableView.reloadData()
                    return
                }

                // PICKUP → fetch donor address
                guard let donorId = self.details["donorId"] as? String else {
                    self.tableView.reloadData()
                    return
                }

                self.db.collection("Users").document(donorId).getDocument { userSnap, _ in
                    if let address = userSnap?.data()?["address"] as? String,
                       !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        self.pickupAddress = address
                    }

                    self.tableView.reloadData()
                }
            }
    }
    


    // MARK: - Status Helpers
    private func currentStatusString() -> String {
        return (details["status"] as? String) ?? donation.status
    }

    
    
    // Collector-only (updates Firestore)
    private func updateDonationStatus(to newStatus: String) {
        guard currentRole == .ngo else { return }

        let id = donation.donationID
        view.isUserInteractionEnabled = false

        db.collection("Donations").document(id).updateData([
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
    
    // MARK: - Image URL Helper
    private func imageUrlStringFromDetails() -> String? {
        let possibleKeys = ["imageUrl", "imageURL", "image_url", "imgUrl", "imgURL"]

        for key in possibleKeys {
            if let s = details[key] as? String, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return s
            }

            // In case you stored it as a URL type (rare)
            if let url = details[key] as? URL {
                return url.absoluteString
            }
        }

        return nil
    }


    func numberOfSections(in tableView: UITableView) -> Int { 4 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch indexPath.section {

        case 0: // Header
            let cell = tableView.dequeueReusableCell(withIdentifier: "DonationHeaderCell", for: indexPath) as! DonationHeaderCell
            cell.configure(title: "Donation Status", donationID: donation.donationID)
            return cell

        case 1: // donor/admin = pipeline, NGO = change-status button (next status)
            let status = currentStatusString()

            if currentRole == .ngo {

                // compute next-title + enabled based on current status
                let config = buttonTitle(for: status) // (title: String, enabled: Bool)

                let cell = tableView.dequeueReusableCell(
                    withIdentifier: "DonationStatusActionCell",
                    for: indexPath
                ) as! DonationStatusActionCell

                // show current status
                // button title shows NEXT status name (e.g., "Mark as Accepted")
                cell.configure(currentStatus: status, buttonTitle: config.title) { [weak self] in
                    self?.toggleToNextStatus()
                }

                // enforce enabled/disabled + alpha every reload
                cell.setButton(title: config.title, enabled: config.enabled)

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
            
            let expiryText: String = {
                if let ts = details["expiryDate"] as? Timestamp {
                    let df = DateFormatter()
                    df.dateStyle = .medium
                    df.timeStyle = .none
                    return df.string(from: ts.dateValue())
                }

                if let s = details["expiryDate"] as? String, !s.isEmpty {
                    return s
                }

                return "—"
            }()


            let quantityInt: Int = {
                if let q = details["quantity"] as? Int { return q }
                if let q = details["quantity"] as? Double { return Int(q) }
                return 0
            }()

            let impact = (details["impactType"] as? String) ?? "—"
            
            let imageUrlString = imageUrlStringFromDetails()

            cell.configure(
                item: item,
                quantity: "\(quantityInt)",
                expiryDate: expiryText,
                impact: impact,
                imageUrlString: imageUrlString
            )
            return cell
            
        case 3: // Pickup / Dropoff
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "DonationPickupCell",
                for: indexPath
            ) as! DonationPickupCell

            let method = (pickup["method"] as? String)
                ?? ((details["donationMethod"] as? String) ?? donation.method)

            cell.configure(
                address: pickupAddress,
                dateTime: pickupDateTime,
                method: method
            )
            return cell
            
                    default:
                        return UITableViewCell()

        }
    }
}
