import UIKit
import FirebaseFirestore

class UserDetailViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var navContainer: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    // Top Info Card
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var statusBadge: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    
    // Stats Container
    @IBOutlet weak var statsContainer: UIView!
    @IBOutlet weak var donationsNumberLabel: UILabel!
    @IBOutlet weak var mealsNumberLabel: UILabel!
    
    // Contact Info
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var joinedLabel: UILabel!
    
    // Action Buttons
    @IBOutlet weak var suspendButton: UIButton!
    @IBOutlet weak var resumeButton: UIButton!
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!
    
    // MARK: - Properties
    private var headerView: HeaderView?
    private var bottomNav: BottomNavView?
    private var didSetupViews = false
    
    private let db = Firestore.firestore()
    
    var user: User?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !didSetupViews {
            didSetupViews = true
            setupHeader()
            setupNav()
        }
    }
    
    // MARK: - Configure UI
    private func configureUI() {
        guard let user = user else { return }
        
        // Logo styling
        logoImageView.layer.cornerRadius = 40
        logoImageView.layer.masksToBounds = true
        
        // ✅ Load profile image or show placeholder
        if let urlString = user.profileImageUrl,
           !urlString.isEmpty,
           let url = URL(string: urlString) {
            loadProfileImage(from: url)
        } else {
            logoImageView.backgroundColor = .systemPurple
            logoImageView.image = UIImage(systemName: "person.circle.fill")
            logoImageView.tintColor = .white
        }
        
        // Basic Info
        nameLabel.text = user.organizationName ?? user.username ?? "Unknown"
        idLabel.text = "ID: \(String(user.id.prefix(8)))"
        
        // ✅ Status Badge - handle nil status for donors
        if let status = user.status {
            configureStatusBadge(status: status)
        } else {
            // Default status for users without status field (donors)
            configureDefaultStatusBadge(for: user.role)
        }
        
        // ✅ Show/Hide Stats - also show for active donors
        if user.status == .verified || user.status == .suspended || user.role == .donor {
            statsContainer.isHidden = false
            donationsNumberLabel.text = "..."
            mealsNumberLabel.text = "..."
            fetchDonationStats(for: user.id)
        } else {
            statsContainer.isHidden = true
        }
        
        // Contact Info
        emailLabel.text = user.email
        phoneLabel.text = user.phone ?? "Not provided"
        locationLabel.text = "\(user.city), \(user.country)"
        
        // Format joined date
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        joinedLabel.text = "Joined \(formatter.string(from: user.createdAt))"
        
        // ✅ Configure Action Buttons - hide for donors
        if user.role == .donor {
            hideAllButtons()
            print("👤 Donor profile - no action buttons needed")
        } else if let status = user.status {
            configureActionButtons(for: status)
        } else {
            hideAllButtons()
        }
        
        // Style buttons
        styleButtons()
    }
    
    // MARK: - Load Profile Image
    private func loadProfileImage(from url: URL) {
        print("🖼️ Loading profile image from: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            
            if let error = error {
                print("❌ Error loading image:", error.localizedDescription)
                DispatchQueue.main.async {
                    self?.logoImageView.backgroundColor = .systemPurple
                    self?.logoImageView.image = UIImage(systemName: "person.circle.fill")
                    self?.logoImageView.tintColor = .white
                }
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    print("✅ Profile image loaded successfully")
                    self?.logoImageView.image = image
                    self?.logoImageView.backgroundColor = .clear
                }
            } else {
                print("⚠️ Failed to convert data to image")
                DispatchQueue.main.async {
                    self?.logoImageView.backgroundColor = .systemPurple
                    self?.logoImageView.image = UIImage(systemName: "person.circle.fill")
                    self?.logoImageView.tintColor = .white
                }
            }
        }.resume()
    }
    
    // MARK: - Fetch Donation Stats
    private func fetchDonationStats(for userId: String) {
        print("📊 Fetching donation stats for user: \(userId)")
        
        // Determine query field based on user role
        let queryField: String
        if user?.role == .ngo {
            queryField = "collectorId"  // NGOs collect donations
        } else {
            queryField = "donorId"      // Donors give donations
        }
        
        db.collection("Donations")
            .whereField(queryField, isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                
                if let error = error {
                    print("❌ Error fetching donations:", error.localizedDescription)
                    DispatchQueue.main.async {
                        self?.donationsNumberLabel.text = "0"
                        self?.mealsNumberLabel.text = "0"
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No donations found")
                    DispatchQueue.main.async {
                        self?.donationsNumberLabel.text = "0"
                        self?.mealsNumberLabel.text = "0"
                    }
                    return
                }
                
                print("📦 Found \(documents.count) donations")
                
                // Decode donations
                let donations = documents.compactMap { doc -> Donation? in
                    try? doc.data(as: Donation.self)
                }
                
                // Calculate stats
                let donationCount = donations.count
                let totalMeals = donations.reduce(0) { $0 + $1.quantity }
                
                print("✅ Stats calculated:")
                print("   Donations: \(donationCount)")
                print("   Total Meals: \(totalMeals)")
                
                // Update UI
                DispatchQueue.main.async {
                    self?.donationsNumberLabel.text = "\(donationCount)"
                    self?.mealsNumberLabel.text = "\(totalMeals)"
                }
            }
    }
    
    // ✅ Configure status badge for explicit status
    private func configureStatusBadge(status: UserStatus) {
        statusBadge.text = status.rawValue.capitalized
        statusBadge.textColor = .white
        statusBadge.layer.cornerRadius = 14
        statusBadge.layer.masksToBounds = true
        statusBadge.textAlignment = .center
        
        switch status {
        case .verified:
            statusBadge.backgroundColor = UIColor.systemGreen
        case .suspended, .rejected:
            statusBadge.backgroundColor = UIColor.systemRed
        case .pending:
            statusBadge.backgroundColor = UIColor.systemOrange
        case .active:
            statusBadge.backgroundColor = UIColor.systemBlue
        }
    }
    
    // ✅ Configure default status badge when status field is missing
    private func configureDefaultStatusBadge(for role: UserRole) {
        statusBadge.textColor = .white
        statusBadge.layer.cornerRadius = 14
        statusBadge.layer.masksToBounds = true
        statusBadge.textAlignment = .center
        
        switch role {
        case .donor:
            statusBadge.text = "Active"
            statusBadge.backgroundColor = .systemBlue
        case .ngo:
            statusBadge.text = "Pending"
            statusBadge.backgroundColor = .systemOrange
        case .admin:
            statusBadge.text = "Active"
            statusBadge.backgroundColor = .systemGreen
        }
    }
    
    // ✅ Hide all action buttons
    private func hideAllButtons() {
        suspendButton.isHidden = true
        resumeButton.isHidden = true
        verifyButton.isHidden = true
        rejectButton.isHidden = true
    }
    
    // ✅ Configure action buttons based on status (for NGOs only)
    private func configureActionButtons(for status: UserStatus) {
        // Hide all buttons first
        hideAllButtons()
        
        // Show relevant buttons based on status
        switch status {
        case .verified:
            suspendButton.isHidden = false
            
        case .suspended:
            resumeButton.isHidden = false
            
        case .pending:
            verifyButton.isHidden = false
            rejectButton.isHidden = false
            
        case .rejected:
            // No buttons for rejected
            break
            
        case .active:
            suspendButton.isHidden = false
        }
    }
    
    private func styleButtons() {
        // Suspend button (red)
        suspendButton.backgroundColor = UIColor.systemRed
        suspendButton.setTitleColor(.white, for: .normal)
        suspendButton.layer.cornerRadius = 12
        
        // Resume button (blue/dark)
        resumeButton.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)
        resumeButton.setTitleColor(.white, for: .normal)
        resumeButton.layer.cornerRadius = 12
        
        // Verify button (blue/dark)
        verifyButton.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)
        verifyButton.setTitleColor(.white, for: .normal)
        verifyButton.layer.cornerRadius = 12
        
        // Reject button (red)
        rejectButton.backgroundColor = UIColor.systemRed
        rejectButton.setTitleColor(.white, for: .normal)
        rejectButton.layer.cornerRadius = 12
    }
    
    // MARK: - Actions
    @IBAction func suspendButtonTapped(_ sender: UIButton) {
        guard let user = user else { return }
        
        let alert = UIAlertController(
            title: "Suspend User",
            message: "Are you sure you want to suspend \(user.organizationName ?? user.username ?? "this user")?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Suspend", style: .destructive) { [weak self] _ in
            self?.updateUserStatus(userId: user.id, newStatus: .suspended)
        })
        
        present(alert, animated: true)
    }
    
    @IBAction func resumeButtonTapped(_ sender: UIButton) {
        guard let user = user else { return }
        
        let alert = UIAlertController(
            title: "Resume User",
            message: "Resume \(user.organizationName ?? user.username ?? "this user") to verified status?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Resume", style: .default) { [weak self] _ in
            self?.updateUserStatus(userId: user.id, newStatus: .verified)
        })
        
        present(alert, animated: true)
    }
    
    @IBAction func verifyButtonTapped(_ sender: UIButton) {
        guard let user = user else { return }
        
        let alert = UIAlertController(
            title: "Verify NGO",
            message: "Approve \(user.organizationName ?? "this NGO")?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Verify", style: .default) { [weak self] _ in
            self?.updateUserStatus(userId: user.id, newStatus: .verified)
        })
        
        present(alert, animated: true)
    }
    
    @IBAction func rejectButtonTapped(_ sender: UIButton) {
        guard let user = user else { return }
        
        let alert = UIAlertController(
            title: "Reject NGO",
            message: "Reject \(user.organizationName ?? "this NGO")?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reject", style: .destructive) { [weak self] _ in
            self?.updateUserStatus(userId: user.id, newStatus: .rejected)
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Update User Status in Firebase
    // MARK: - Update User Status in Firebase
    private func updateUserStatus(userId: String, newStatus: UserStatus) {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔄 Updating user status...")
        print("   User ID: \(userId)")
        print("   New Status: \(newStatus.rawValue)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Show loading indicator
        let loadingAlert = UIAlertController(title: nil, message: "Updating...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: loadingAlert.view.centerXAnchor),
            loadingIndicator.bottomAnchor.constraint(equalTo: loadingAlert.view.bottomAnchor, constant: -20)
        ])
        present(loadingAlert, animated: true)
        
        // Update in Firebase
        db.collection("Users").document(userId).updateData([
            "status": newStatus.rawValue
        ]) { [weak self] error in
            
            // Dismiss loading
            loadingAlert.dismiss(animated: true) {
                
                if let error = error {
                    print("❌ ERROR updating status:", error.localizedDescription)
                    self?.showErrorAlert(message: "Failed to update status. Please try again.")
                    return
                }
                
                print("✅ SUCCESS: Status updated to \(newStatus.rawValue)")
                
                // ✅ UPDATE LOCAL USER OBJECT IMMEDIATELY
                
                // ✅ REFRESH THE UI IMMEDIATELY
                self?.refreshUIAfterStatusChange(newStatus: newStatus)
                
                // Show success message
                self?.showSuccessAlert(newStatus: newStatus)
            }
        }
    }
    
    // ✅ NEW: Refresh UI immediately after status change
    private func refreshUIAfterStatusChange(newStatus: UserStatus) {
        print("🔄 Refreshing UI with new status: \(newStatus.rawValue)")
        
        // Update status badge
        configureStatusBadge(status: newStatus)
        
        // Update action buttons
        configureActionButtons(for: newStatus)
        
        // Update stats visibility
        if newStatus == .verified || newStatus == .suspended {
            if statsContainer.isHidden {
                statsContainer.isHidden = false
                donationsNumberLabel.text = "..."
                mealsNumberLabel.text = "..."
                if let userId = user?.id {
                    fetchDonationStats(for: userId)
                }
            }
        } else {
            statsContainer.isHidden = true
        }
        
        print("✅ UI refreshed successfully")
    }
    
    private func showSuccessAlert(newStatus: UserStatus) {
        let message: String
        switch newStatus {
        case .verified:
            message = "User has been verified!"
        case .suspended:
            message = "User has been suspended."
        case .rejected:
            message = "User has been rejected."
        default:
            message = "Status updated successfully."
        }
        
        let alert = UIAlertController(
            title: "Success",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Header
    private func setupHeader() {
        guard let header = Bundle.main
            .loadNibNamed("HeaderView", owner: nil, options: nil)?
            .first as? HeaderView else {
            return
        }
        
        header.frame = headerContainer.bounds
        header.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        header.takaffalLabel.text = "Takaffal"
        header.backBtn.isHidden = false
        header.backBtn.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        header.notiBtn.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)
        
        headerContainer.addSubview(header)
        self.headerView = header
    }
    
    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func openNotifications() {
        print("🔔 Notifications")
    }
    
    // MARK: - Bottom Nav
    private func setupNav() {
        guard let nav = Bundle.main
            .loadNibNamed("BottomNavView", owner: nil, options: nil)?
            .first as? BottomNavView else {
            return
        }
        
        nav.frame = navContainer.bounds
        nav.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Admin view
        nav.listBtn.isHidden = true
        nav.listLab.isHidden = true
        nav.ngoLab.isHidden = true
        nav.proBtn.isHidden = false
        nav.proLab.isHidden = false
        nav.impBtn.isHidden = false
        nav.ompLab.isHidden = false
        nav.userBtn.isHidden = false
        nav.userLab.isHidden = false
        nav.hisBtn.isHidden = true
        nav.hisLab.isHidden = true
        nav.heartBtn.isHidden = false
        nav.donLab.isHidden = false
        nav.formBtn.isHidden = true
        
        nav.backgroundColor = .clear
        navContainer.backgroundColor = .clear
        
        navContainer.addSubview(nav)
        self.bottomNav = nav
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
}
