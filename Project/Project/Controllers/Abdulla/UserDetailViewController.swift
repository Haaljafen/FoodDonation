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
            configureDefaultStatusBadge(for: user.role)
        }
        
        // ✅ Show/Hide Stats
        if user.status == .verified || user.status == .suspended || user.status == .active || user.role == .donor {
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
        
        // ✅ Configure Action Buttons
        if let status = user.status {
            configureActionButtons(for: status, role: user.role)
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
        
        let queryField: String
        if user?.role == .ngo {
            queryField = "collectorId"
        } else {
            queryField = "donorId"
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
                
                let donations = documents.compactMap { doc -> Donation? in
                    try? doc.data(as: Donation.self)
                }
                
                let donationCount = donations.count
                let totalMeals = donations.reduce(0) { $0 + $1.quantity }
                
                print("✅ Stats calculated:")
                print("   Donations: \(donationCount)")
                print("   Total Meals: \(totalMeals)")
                
                DispatchQueue.main.async {
                    self?.donationsNumberLabel.text = "\(donationCount)"
                    self?.mealsNumberLabel.text = "\(totalMeals)"
                }
            }
    }
    
    // MARK: - Status Badge Configuration
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
    
    // MARK: - Button Configuration
    private func hideAllButtons() {
        suspendButton.isHidden = true
        resumeButton.isHidden = true
        verifyButton.isHidden = true
        rejectButton.isHidden = true
    }
    
    private func configureActionButtons(for status: UserStatus, role: UserRole) {
        hideAllButtons()
        
        // ✅ For DONORS - only suspend/resume
        if role == .donor {
            switch status {
            case .active, .verified:
                suspendButton.isHidden = false
                print("👤 Donor is active - showing suspend button")
                
            case .suspended:
                resumeButton.isHidden = false
                print("👤 Donor is suspended - showing resume button")
                
            default:
                print("👤 Donor status: \(status.rawValue) - no buttons")
            }
            return
        }
        
        // ✅ For NGOs - full workflow
        switch status {
        case .verified:
            suspendButton.isHidden = false
            
        case .suspended:
            resumeButton.isHidden = false
            
        case .pending:
            verifyButton.isHidden = false
            rejectButton.isHidden = false
            
        case .rejected:
            break
            
        case .active:
            suspendButton.isHidden = false
        }
    }
    
    private func styleButtons() {
        suspendButton.backgroundColor = UIColor.systemRed
        suspendButton.setTitleColor(.white, for: .normal)
        suspendButton.layer.cornerRadius = 12
        
        resumeButton.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)
        resumeButton.setTitleColor(.white, for: .normal)
        resumeButton.layer.cornerRadius = 12
        
        verifyButton.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)
        verifyButton.setTitleColor(.white, for: .normal)
        verifyButton.layer.cornerRadius = 12
        
        rejectButton.backgroundColor = UIColor.systemRed
        rejectButton.setTitleColor(.white, for: .normal)
        rejectButton.layer.cornerRadius = 12
    }
    
    // MARK: - Button Actions
    @IBAction func suspendButtonTapped(_ sender: UIButton) {
        guard let user = user else { return }
        
        let userType = user.role == .donor ? "donor" : "NGO"
        let userName = user.role == .donor
            ? (user.username ?? "this user")
            : (user.organizationName ?? "this user")
        
        let alert = UIAlertController(
            title: "Suspend \(userType.capitalized)",
            message: "Are you sure you want to suspend \(userName)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Suspend", style: .destructive) { [weak self] _ in
            self?.updateUserStatus(userId: user.id, newStatus: .suspended, role: user.role)
        })
        
        present(alert, animated: true)
    }
    
    @IBAction func resumeButtonTapped(_ sender: UIButton) {
        guard let user = user else { return }
        
        let userType = user.role == .donor ? "donor" : "NGO"
        let userName = user.role == .donor
            ? (user.username ?? "this user")
            : (user.organizationName ?? "this user")
        
        let newStatus: UserStatus = user.role == .donor ? .active : .verified
        
        let alert = UIAlertController(
            title: "Resume \(userType.capitalized)",
            message: "Resume \(userName)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Resume", style: .default) { [weak self] _ in
            self?.updateUserStatus(userId: user.id, newStatus: newStatus, role: user.role)
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
            self?.updateUserStatus(userId: user.id, newStatus: .verified, role: user.role)
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
            self?.updateUserStatus(userId: user.id, newStatus: .rejected, role: user.role)
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Update User Status
    private func updateUserStatus(userId: String, newStatus: UserStatus, role: UserRole) {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔄 Updating user status...")
        print("   User ID: \(userId)")
        print("   Role: \(role.rawValue)")
        print("   New Status: \(newStatus.rawValue)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
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
        
        db.collection("Users").document(userId).updateData([
            "status": newStatus.rawValue
        ]) { [weak self] error in
            
            loadingAlert.dismiss(animated: true) {
                
                if let error = error {
                    print("❌ ERROR updating status:", error.localizedDescription)
                    self?.showErrorAlert(message: "Failed to update status. Please try again.")
                    return
                }
                
                print("✅ SUCCESS: Status updated to \(newStatus.rawValue)")
                
                // ✅ REFRESH UI IMMEDIATELY
                self?.refreshUIAfterStatusChange(newStatus: newStatus, role: role)
                
                // Show success
                self?.showSuccessAlert(newStatus: newStatus, role: role)
            }
        }
    }
    
    // ✅ REAL-TIME UI UPDATE
    private func refreshUIAfterStatusChange(newStatus: UserStatus, role: UserRole) {
        print("🔄 Refreshing UI with new status: \(newStatus.rawValue)")
        
        // 1. Update badge immediately
        configureStatusBadge(status: newStatus)
        
        // 2. Update buttons immediately
        configureActionButtons(for: newStatus, role: role)
        
        // 3. Update stats visibility
        if newStatus == .verified || newStatus == .suspended || newStatus == .active {
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
        print("   Badge: \(statusBadge.text ?? "nil") - \(statusBadge.backgroundColor?.description ?? "nil")")
        print("   Suspend hidden: \(suspendButton.isHidden)")
        print("   Resume hidden: \(resumeButton.isHidden)")
    }
    
    private func showSuccessAlert(newStatus: UserStatus, role: UserRole) {
        let message: String
        let userType = role == .donor ? "Donor" : "NGO"
        
        switch newStatus {
        case .verified:
            message = "\(userType) has been verified!"
        case .suspended:
            message = "\(userType) has been suspended."
        case .rejected:
            message = "\(userType) has been rejected."
        case .active:
            message = "\(userType) has been resumed to active."
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

