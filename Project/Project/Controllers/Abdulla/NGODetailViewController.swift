import UIKit
import FirebaseFirestore
import FirebaseAuth
class NGODetailViewController: UIViewController {

    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var navContainer: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    // Basic Info
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var organizationNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var aboutTextView: UILabel!
    @IBOutlet weak var missionTextView: UILabel!
    @IBOutlet weak var createdAtLabel: UILabel!
    @IBOutlet weak var ngoIDLabel: UILabel!
    
    // ✅ ADD THESE OUTLETS FOR STATS
    @IBOutlet weak var donationsCountLabel: UILabel!
    @IBOutlet weak var totalMealsLabel: UILabel!
    
    private var currentUserRole: UserRole?
    private var headerView: HeaderView?
    private var bottomNav: BottomNavView?
    private var didSetupViews = false
    
    private let db = Firestore.firestore()
    
    var selectedUser: User?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let user = selectedUser {
            displayUserData(user)
        }
    }
    
    private func displayUserData(_ user: User) {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📱 DETAIL SCREEN LOADED")
        print("✅ Received user:")
        print("   Organization:", user.organizationName ?? "nil")
        print("   Email:", user.email)
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // ✅ UPDATE UI LABELS
        organizationNameLabel?.text = user.organizationName ?? "Unknown"
        emailLabel?.text = user.email
        phoneLabel?.text = user.phone
        cityLabel?.text = user.city
        addressLabel?.text = user.address
        statusLabel?.text = user.status?.rawValue.capitalized ?? "Unknown"
        aboutTextView?.text = user.about ?? "No description"
        missionTextView?.text = user.mission ?? "No mission"

        let shortID = String(user.id.prefix(8))
        ngoIDLabel?.text = "NGO ID: \(shortID)"
        
        // ✅ DISPLAY CREATED DATE
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        let dateString = dateFormatter.string(from: user.createdAt)
        createdAtLabel?.text = "Member since \(dateString)"
        
        // ✅ LOAD PROFILE IMAGE
        if let urlString = user.profileImageUrl,
           !urlString.isEmpty,
           let url = URL(string: urlString) {
            loadProfileImage(from: url)
        } else {
            profileImageView?.image = UIImage(systemName: "building.2.fill")
            profileImageView?.tintColor = .systemBlue
        }
        
        // ✅ FETCH DONATION STATS
        donationsCountLabel?.text = "..."
        totalMealsLabel?.text = "..."
        fetchDonationStats(for: user.id, role: user.role)
    }
    
    // ✅ NEW: Fetch donation stats from Firebase
    private func fetchDonationStats(for userId: String, role: UserRole) {
        print("📊 Fetching donation stats for NGO: \(userId)")
        
        // NGOs use collectorId field
        let queryField = "collectorId"
        
        db.collection("Donations")
            .whereField(queryField, isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                
                if let error = error {
                    print("❌ Error fetching donations:", error.localizedDescription)
                    DispatchQueue.main.async {
                        self?.donationsCountLabel?.text = "0"
                        self?.totalMealsLabel?.text = "0"
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No donations found")
                    DispatchQueue.main.async {
                        self?.donationsCountLabel?.text = "0"
                        self?.totalMealsLabel?.text = "0"
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
                    self?.donationsCountLabel?.text = "\(donationCount)"
                    self?.totalMealsLabel?.text = "\(totalMeals)"
                }
            }
    }
    
    private func loadProfileImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.profileImageView?.image = image
                }
            }
        }.resume()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !didSetupViews {
            didSetupViews = true
            setupHeader()
            setupNav()
        }
    }

    private func setupHeader() {
        guard let header = Bundle.main
            .loadNibNamed("HeaderView", owner: nil, options: nil)?
            .first as? HeaderView else {
            return
        }
        
        header.search.isHidden = true
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
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }
}


