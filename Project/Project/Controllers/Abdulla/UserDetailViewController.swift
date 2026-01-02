import UIKit
import FirebaseFirestore
import FirebaseAuth

// Uses DonationService for Notifications

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
    private var currentUserRole: UserRole?
    private var headerView: HeaderView?
    private var bottomNav: BottomNavView?
    private var didSetupViews = false
    
    // ✅ ADD FIREBASE
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
        
        // Status Badge
        if let status = user.status {
            configureStatusBadge(status: status)
        }
        
        // Show/Hide Stats based on status
        if user.status == .verified || user.status == .suspended {
            statsContainer.isHidden = false
            donationsNumberLabel.text = "0"
            mealsNumberLabel.text = "0"
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
        
        // Configure Action Buttons
        if let status = user.status {
            configureActionButtons(for: status)
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
                    // Show placeholder on error
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
                    // Show placeholder
                    self?.logoImageView.backgroundColor = .systemPurple
                    self?.logoImageView.image = UIImage(systemName: "person.circle.fill")
                    self?.logoImageView.tintColor = .white
                }
            }
        }.resume()
    }
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
    
    private func configureActionButtons(for status: UserStatus) {
        // Hide all buttons first
        suspendButton.isHidden = true
        resumeButton.isHidden = true
        verifyButton.isHidden = true
        rejectButton.isHidden = true
        
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
            // Could add "Review" button here if needed
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
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("✅ VERIFY BUTTON TAPPED!")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        guard let user = user else {
            print("❌ ERROR: user is nil!")
            return
        }
        
        print("🔵 User to verify: \(user.organizationName ?? "Unknown")")
        
        let alert = UIAlertController(
            title: "Verify User",
            message: "Approve \(user.organizationName ?? user.username ?? "this user")?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            print("❌ User cancelled verification")
        })
        
        alert.addAction(UIAlertAction(title: "Verify", style: .default) { [weak self] _ in
            print("✅ User confirmed verification")
            self?.updateUserStatus(userId: user.id, newStatus: .verified)
        })
        
        print("📱 Presenting alert...")
        present(alert, animated: true)
    }
    
    @IBAction func rejectButtonTapped(_ sender: UIButton) {
        guard let user = user else { return }
        
        let alert = UIAlertController(
            title: "Reject User",
            message: "Reject \(user.organizationName ?? user.username ?? "this user")?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reject", style: .destructive) { [weak self] _ in
            self?.updateUserStatus(userId: user.id, newStatus: .rejected)
        })
        
        present(alert, animated: true)
    }
    
    // ✅ NEW: Update user status in Firebase
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

                if newStatus == .verified {
                    DonationService.shared.notify(
                        type: .userApproved,
                        relatedDonationId: nil,
                        toUserId: userId,
                        audience: nil
                    )
                }
                
                // Show success message
                self?.showSuccessAlert(newStatus: newStatus)
            }
        }
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
            // Go back to list
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
        
        header.clear.isHidden = true
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
        print("🔔 Notifications tapped")

        let sb = UIStoryboard(name: "NotificationsStoryboard", bundle: nil)

        guard let vc = sb.instantiateViewController(withIdentifier: "NotificationVC") as? NotificationViewController else {
            print("❌ Could not instantiate NotificationViewController")
            return
        }

        navigationController?.pushViewController(vc, animated: true)
    }

    
    // MARK: - Bottom Nav
    private func setupNav() {
           guard let nav = Bundle.main
               .loadNibNamed("BottomNavView", owner: nil, options: nil)?
               .first as? BottomNavView else {
               print("Failed to load BottomNavView.xib")
               return
           }

        nav.translatesAutoresizingMaskIntoConstraints = false
        navContainer.addSubview(nav)

        NSLayoutConstraint.activate([
            nav.topAnchor.constraint(equalTo: navContainer.topAnchor),
            nav.bottomAnchor.constraint(equalTo: navContainer.bottomAnchor),
            nav.leadingAnchor.constraint(equalTo: navContainer.leadingAnchor),
            nav.trailingAnchor.constraint(equalTo: navContainer.trailingAnchor)
        ])

        nav.listBtn.addTarget(self, action: #selector(openList), for: .touchUpInside)
        nav.hisBtn.addTarget(self, action: #selector(openHistory), for: .touchUpInside)
        nav.impBtn.addTarget(self, action: #selector(openImpact), for: .touchUpInside)
        nav.proBtn.addTarget(self, action: #selector(openProfile), for: .touchUpInside)
        nav.userBtn.addTarget(self, action: #selector(openUsers), for: .touchUpInside)
        nav.heartBtn.addTarget(self, action: #selector(openDonations), for: .touchUpInside)
        nav.formBtn.addTarget(self,action: #selector(openDonationForm),for: .touchUpInside)

           nav.backgroundColor = .clear
           bottomNav = nav
            fetchUserRoleAndConfigureNav(nav)
       }
    
    private func fetchUserRoleAndConfigureNav(_ nav: BottomNavView) {

        guard let uid = Auth.auth().currentUser?.uid else {
            print("No logged in user")
            return
        }

        Firestore.firestore()
            .collection("Users")
            .document(uid)
            .getDocument { snapshot, error in

                if let error = error {
                    print("Failed to fetch role:", error.localizedDescription)
                    return
                }

                guard
                    let data = snapshot?.data(),
                    let roleString = data["role"] as? String,
                    let role = UserRole(rawValue: roleString)
                else {
                    print("Role missing or invalid")
                    return
                }
                
                self.currentUserRole = role
                self.configureNav(nav, for: role)
            }
    }
    
    private func push(_ vc: UIViewController) {
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            present(vc, animated: true)
        }
    }

    
    private func configureNav(_ nav: BottomNavView, for role: UserRole) {
        
        let allButtons = [
            nav.listBtn,
            nav.hisBtn,
            nav.impBtn,
            nav.proBtn,
            nav.userBtn,
            nav.formBtn,
            nav.heartBtn
        ]

        allButtons.forEach { $0?.isHidden = true }

        switch role {

        case .donor:
            nav.formBtn.isHidden = false
            nav.listBtn.isHidden = false
            nav.proBtn.isHidden = false
            nav.impBtn.isHidden = false
            nav.userBtn.isHidden = true
            nav.hisBtn.isHidden = false
            nav.heartBtn.isHidden = true
            
            nav.userLab.isHidden = true
            nav.donLab.isHidden = true
            nav.listLab.isHidden = true

        case .ngo:
            nav.formBtn.isHidden = true
            nav.listBtn.isHidden = false
            nav.proBtn.isHidden = false
            nav.impBtn.isHidden = false
            nav.hisBtn.isHidden = false
            nav.userBtn.isHidden = true
            nav.heartBtn.isHidden = true
            
            nav.userLab.isHidden = true
            nav.donLab.isHidden = true
            nav.ngoLab.isHidden = true

        case .admin:
            nav.formBtn.isHidden = true
            nav.listBtn.isHidden = true
            nav.proBtn.isHidden = false
            nav.impBtn.isHidden = false
            nav.hisBtn.isHidden = true
            nav.userBtn.isHidden = false
            nav.heartBtn.isHidden = false
            
            nav.hisLab.isHidden = true
            nav.listLab.isHidden = true
            nav.ngoLab.isHidden = true
    
        }
    }


       // MARK: - Nav Actions
    
    @objc private func openDonations() {
        let sb = UIStoryboard(name: "History&statusNoora", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "History&statusNoora")
        push(vc)
    }
    
    @objc private func openList() {

        guard let role = currentUserRole else {
            print("Role not loaded yet")
            return
        }

        switch role {

        case .donor:
            let sb = UIStoryboard(name: "AbdullaStoryboard1", bundle: nil)
            let vc = sb.instantiateViewController(
                withIdentifier: "AbdullaViewController1"
            )
            push(vc)

        case .ngo:
            let sb = UIStoryboard(name: "HajarStoryboard", bundle: nil)
            let vc = sb.instantiateViewController(
                withIdentifier: "HajarHomeVC"
            )
            push(vc)
            
        default:
            return
            
        }
    }

    @objc private func openHistory() {
        let sb = UIStoryboard(name: "History&statusNoora", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "History&statusNoora")
        push(vc)
    }
    
    @objc private func openImpact() {
        let sb = UIStoryboard(name: "ImpactNoora", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "ImpactNoora")
        push(vc)
    }
    
    @objc private func openProfile() {
        let sb = UIStoryboard(name: "MariamStoryboard2", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "ProfileViewController")
        push(vc)
    }
    
    @objc private func openUsers() {
        let sb = UIStoryboard(name: "AbdullaStoryboard2", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "AbdullaViewController2")
        push(vc)
    }
    
    private func pushIfNeeded(_ vc: UIViewController) {
        if let top = navigationController?.topViewController,
           type(of: top) == type(of: vc) {
            return
        }
        push(vc)
    }
    
    @objc private func openDonationForm() {

        guard let role = currentUserRole else {
            print("Role not loaded yet")
            return
        }

        guard role == .donor else {
            print("Only donors can open donation form")
            return
        }

        let sb = UIStoryboard(name: "HajarStoryboard2", bundle: nil)
        let vc = sb.instantiateViewController(
            withIdentifier: "CreateDonationViewController"
        )

        push(vc)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // ✅ Hide navigation bar - use custom header instead
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Keep it hidden for consistency
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
}

