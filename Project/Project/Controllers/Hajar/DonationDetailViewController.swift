import UIKit
import FirebaseFirestore

final class DonationDetailViewController: UIViewController {

    @IBOutlet weak var headerContainer: UIView!
    private var headerView: HeaderView?

    // Donor
    @IBOutlet weak var donorNameLabel: UILabel!
    @IBOutlet weak var donorAddressLabel: UILabel!
    @IBOutlet weak var donorContactLabel: UILabel!
    @IBOutlet weak var donorImageView: UIImageView!

    @IBOutlet weak var categoryPillView: UIView!
    // Donation
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var quantityLabel: UILabel!

    // Pickup
    @IBOutlet weak var pickupDateLabel: UILabel!
    @IBOutlet weak var pickupMethodLabel: UILabel!

    // Buttons
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!

    // Passed in
    var donationId: String?
    var donorId: String?
    var passedItem: DonationItem?

    private let db = Firestore.firestore()

    private func quantityNumber(from text: String) -> String {
        let digits = text.filter { $0.isNumber }
        return digits.isEmpty ? text : digits
    }

    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private func presentAcceptanceReceiptPopup() {
        let donationIdSafe = donationId ?? ""

        let itemName = itemNameLabel.text ?? "—"
        let category = categoryLabel.text ?? "—"
        let quantity = quantityLabel.text ?? "—"
        let donorName = donorNameLabel.text ?? "—"
        let pickupMethod = pickupMethodLabel.text ?? "—"
        let scheduledDate = pickupDateLabel.text ?? "—"
        let location = donorAddressLabel.text ?? "—"

        let body = """
🧾 Receipt 2: Donation Accepted (NGO)
Title: Donation Acceptance Receipt
This receipt confirms that your organization has successfully accepted a donation.
Donation Details:
• Item Name: \(itemName)
• Category: \(category)
• Quantity: \(quantity)
• Donor Name: \(donorName)
• Pickup Method: \(pickupMethod)
• Scheduled Date: \(scheduledDate)
• Location: \(location)
Please ensure the donation is collected according to the agreed schedule.
Thank you for your continued efforts in supporting the community.
"""

        let qrPayload = ReceiptPopupViewController.makeGithubPagesReceiptUrl(from: body)
        let popup = ReceiptPopupViewController(
            receiptTitle: "Donation Acceptance Receipt",
            receiptBody: body,
            qrPayload: qrPayload
        )
        popup.onDismiss = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        present(popup, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupHeader()
        applyStaticUIStyle()

        print("✅ detail opened donationId:", donationId ?? "nil", "donorId:", donorId ?? "nil")

        guard donationId != nil || passedItem != nil else {
            showError(message: "Unable to load donation details")
            return
        }
        
        categoryLabel.setContentHuggingPriority(.required, for: .horizontal)
         categoryLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Fast fill from list card (instant UI)
        if let item = passedItem {
            fillFrom(item)
            if donationId == nil { donationId = item.id }
            if donorId == nil { donorId = item.donorId }
        }

        // Fetch real data
        fetchDonation()
        fetchDonor()
        fetchPickupRequest()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

            donorImageView.layoutIfNeeded()
            headerContainer.isUserInteractionEnabled = true
            headerView?.isUserInteractionEnabled = true
            view.bringSubviewToFront(headerContainer)
            donorImageView.layer.cornerRadius = donorImageView.bounds.width / 2
            categoryPillView.layer.cornerRadius = categoryPillView.bounds.height / 2
            categoryPillView.clipsToBounds = true
            donorImageView.clipsToBounds = true
            donorImageView.contentMode = .scaleAspectFill

            acceptButton.layer.cornerRadius = 12
            rejectButton.layer.cornerRadius = 12
            itemImageView.layer.cornerRadius = 14

            layoutCategoryPill()

    }

    private func applyStaticUIStyle() {
        donorImageView.clipsToBounds = true
        donorImageView.contentMode = .scaleAspectFill

        itemImageView.clipsToBounds = true
        itemImageView.contentMode = .scaleAspectFill

        // ✅ pill styling
        categoryLabel.backgroundColor = UIColor.systemBlue
        categoryLabel.textColor = .white
        categoryLabel.textAlignment = .center
        categoryLabel.numberOfLines = 1
        categoryLabel.lineBreakMode = .byTruncatingTail
        categoryLabel.clipsToBounds = true
        categoryLabel.adjustsFontSizeToFitWidth = true
        categoryLabel.minimumScaleFactor = 0.75

        // ✅ IMPORTANT: stop it stretching
        categoryLabel.setContentHuggingPriority(.required, for: .horizontal)
        categoryLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func layoutCategoryPill() {
        guard let text = categoryLabel.text, !text.isEmpty else { return }
        guard let container = categoryPillView.superview else { return }

        let availableWidth = container.bounds.width
        guard availableWidth > 0 else { return }

        let maxWidth = max(80, availableWidth - 40)
        let padding: CGFloat = 24
        let labelWidth = categoryLabel.sizeThatFits(CGSize(width: maxWidth, height: categoryPillView.bounds.height)).width
        let pillWidth = min(maxWidth, max(80, labelWidth + padding))

        var frame = categoryPillView.frame
        frame.size.width = pillWidth
        frame.origin.x = availableWidth - pillWidth - 15
        categoryPillView.frame = frame

        categoryLabel.frame = categoryPillView.bounds.insetBy(dx: 12, dy: 4)
        categoryLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }


    private func fillFrom(_ item: DonationItem) {
        itemNameLabel.text = item.name
        let q = quantityNumber(from: item.quantity)
        quantityLabel.text = "Quantity: \(q)"
        categoryLabel.text = item.category

        donorNameLabel.text = item.donorName
        donorAddressLabel.text = item.location
        donorContactLabel.text = "Loading..."

        let urlStr = item.imageURL
        if !urlStr.isEmpty, URL(string: urlStr) != nil {
            loadImage(urlString: urlStr, into: itemImageView)
        } else {
            itemImageView.image = UIImage(named: "placeholder_food")
        }

        pickupDateLabel.text = "Loading..."
        pickupMethodLabel.text = "Loading..."
        donorImageView.image = UIImage(named: "no-pfp")

        layoutCategoryPill()
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    // MARK: - Fetch Donation
    private func fetchDonation() {
        guard let donationId = donationId, !donationId.isEmpty else { return }

        db.collection("Donations").document(donationId).getDocument { [weak self] snap, err in
            guard let self = self else { return }
            if let err = err {
                print("❌ fetchDonation error:", err.localizedDescription)
                return
            }
            guard let d = snap?.data() else {
                print("❌ fetchDonation: document not found:", donationId)
                return
            }

            let itemName = d["item"] as? String ?? "—"
            let category = d["category"] as? String ?? "—"
            let qty = d["quantity"] as? Int ?? 0
            let unit = d["unit"] as? String ?? ""
            let imageUrl = d["imageUrl"] as? String ?? ""

            DispatchQueue.main.async {
                self.itemNameLabel.text = itemName
                self.categoryLabel.text = category
                self.quantityLabel.text = "Quantity: \(qty)"

                self.layoutCategoryPill()

                if !imageUrl.isEmpty, URL(string: imageUrl) != nil {
                    self.loadImage(urlString: imageUrl, into: self.itemImageView)
                } else {
                    self.itemImageView.image = UIImage(named: "placeholder_food")
                }
            }
        }
    }

    // MARK: - Fetch Donor
    private func fetchDonor() {
        guard let donorId = donorId, !donorId.isEmpty else { return }

        db.collection("Users").document(donorId).getDocument { [weak self] snap, err in
            guard let self = self else { return }
            if let err = err {
                print("❌ fetchDonor error:", err.localizedDescription)
                return
            }
            guard let u = snap?.data() else {
                print("❌ fetchDonor: user not found:", donorId)
                return
            }

            let name = (u["username"] as? String)
                ?? (u["organizationName"] as? String)
                ?? "Donor"

            let city = u["city"] as? String ?? ""
            let address = u["address"] as? String ?? ""
            let email = u["email"] as? String ?? ""
            let pfp = u["profileImageUrl"] as? String ?? ""

            DispatchQueue.main.async {
                self.donorNameLabel.text = name
                self.donorAddressLabel.text = "\(city)\(city.isEmpty ? "" : " - ")\(address)"
                self.donorContactLabel.text = email

                if !pfp.isEmpty, URL(string: pfp) != nil {
                    self.loadImage(urlString: pfp, into: self.donorImageView)
                } else {
                    self.donorImageView.image = UIImage(named: "no-pfp")
                }
            }
        }
    }

    // MARK: - Fetch Pickup Request
    private func fetchPickupRequest() {
        guard let donationId = donationId, !donationId.isEmpty else { return }

        db.collection("PickupRequests")
            .whereField("donationId", isEqualTo: donationId)
            .limit(to: 1)
            .getDocuments { [weak self] snap, err in
                guard let self = self else { return }
                if let err = err {
                    print("❌ fetchPickupRequest error:", err.localizedDescription)
                    return
                }

                let p = snap?.documents.first?.data() ?? [:]
                let method = (p["method"] as? String ?? "—")
                DispatchQueue.main.async {
                    self.pickupMethodLabel.text = (method == "locationPickup") ? "Location pickup" : method

                    if let ts = p["pickupDateTime"] as? Timestamp {
                        self.pickupDateLabel.text = self.dateFormatter.string(from: ts.dateValue())
                    } else if let ts = p["dropoffDate"] as? Timestamp {
                        self.pickupDateLabel.text = self.dateFormatter.string(from: ts.dateValue())
                    } else {
                        self.pickupDateLabel.text = "—"
                    }
                }
            }
    }

    // MARK: - Image loader
    private func loadImage(urlString: String, into imageView: UIImageView) {
        let transformed = urlString.replacingOccurrences(
            of: "/upload/",
            with: "/upload/w_900,h_600,c_fill,q_auto,f_auto/"
        )
        guard let url = URL(string: transformed) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let img = UIImage(data: data) else { return }
            DispatchQueue.main.async { imageView.image = img }
        }.resume()
    }

    private func setupHeader() {
        guard let header = Bundle.main.loadNibNamed("HeaderView", owner: nil)?.first as? HeaderView else { return }
        header.frame = headerContainer.bounds
        header.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        header.takaffalLabel.text = "Takaffal"
        header.backBtn.isHidden = false
        header.search.isHidden = true
        header.notiBtn.isHidden = false
        headerContainer.isUserInteractionEnabled = true
        header.isUserInteractionEnabled = true
        header.backBtn.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        header.onNotificationTap = { [weak self] in
            self?.openNotifications()
        }
        header.notiBtn.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)
        headerContainer.addSubview(header)
        self.headerView = header

        acceptButton.addTarget(self, action: #selector(acceptDonationTapped), for: .touchUpInside)
        rejectButton.addTarget(self, action: #selector(rejectDonationTapped), for: .touchUpInside)
    }

    @objc private func backButtonTapped() {
        if let nav = navigationController, nav.viewControllers.first != self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func openNotifications() {
        let sb = UIStoryboard(name: "NotificationsStoryboard", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "NotificationVC") as? NotificationViewController else {
            return
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func acceptDonationTapped() {
        guard let donationId = donationId else { return }
        db.collection("Donations").document(donationId).updateData([
            "status": "accepted",
            "acceptedAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("❌ Error accepting donation:", error.localizedDescription)
                self.showError(message: "Failed to accept donation")
            } else {
                if let donorId = self.donorId {
                    DonationService.shared.notify(
                        type: .donationCollected,
                        relatedDonationId: donationId,
                        toUserId: donorId,
                        audience: nil
                    )
                }
                DispatchQueue.main.async {
                    self.presentAcceptanceReceiptPopup()
                }
            }
        }
    }

    @objc private func rejectDonationTapped() {
        guard let donationId = donationId else { return }
        db.collection("Donations").document(donationId).updateData([
            "status": "rejected",
            "rejectedAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("❌ Error rejecting donation:", error.localizedDescription)
                self.showError(message: "Failed to reject donation")
            } else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Success", message: "Donation rejected", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.navigationController?.popViewController(animated: true)
                    })
                    self.present(alert, animated: true)
                }
            }
        }
    }
}
