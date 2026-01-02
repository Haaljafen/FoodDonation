import UIKit
import FirebaseFirestore

class NGODetailViewController: UIViewController {

    @IBOutlet weak var headerContainer: UIView!
        @IBOutlet weak var navContainer: UIView!
        @IBOutlet weak var scrollView: UIScrollView!
        
        // ✅ ADD THESE OUTLETS FOR DISPLAYING DATA
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

        
        private var headerView: HeaderView?
        private var bottomNav: BottomNavView?
        private var didSetupViews = false
        
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
            
            // ✅ DISPLAY CREATED DATE (createdAt is NOT optional)
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
        print("🔔 Notifications")
    }

    private func setupNav() {
        guard let nav = Bundle.main
            .loadNibNamed("BottomNavView", owner: nil, options: nil)?
            .first as? BottomNavView else {
            return
        }

        nav.frame = navContainer.bounds
        nav.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navContainer.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)

        nav.listBtn.isHidden = false
        nav.listLab.isHidden = false
        nav.hisBtn.isHidden = false
        nav.hisLab.isHidden = false
        nav.impBtn.isHidden = false
        nav.ompLab.isHidden = false
        nav.proBtn.isHidden = false
        nav.proLab.isHidden = false
        
        nav.userBtn.isHidden = true
        nav.userLab.isHidden = true
        nav.heartBtn.isHidden = true
        nav.donLab.isHidden = true
        nav.formBtn.isHidden = true
        nav.ngoLab.isHidden = true

        navContainer.addSubview(nav)
        self.bottomNav = nav
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
