import UIKit

class HajarViewController1: UIViewController {

    // MARK: - Outlets
//    @IBOutlet weak var headerContainer: UIView!
//    @IBOutlet weak var navContainer: UIView!

    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var navContainer: UIView!
    
    // MARK: - State
    private var headerView: HeaderView?
    private var bottomNav: BottomNavView?
    private var didSetupBars = false

    // MARK: - Lifecycle
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !didSetupBars {
            didSetupBars = true
            setupHeader()
//            setupNav()
        }
    }

    
    // MARK: - Header
    private func setupHeader() {
        guard let header = Bundle.main
            .loadNibNamed("HeaderView", owner: nil, options: nil)?
            .first as? HeaderView else {
            print("❌ Failed to load HeaderView.xib")
            return
        }

        header.frame = headerContainer.bounds
        header.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        header.takaffalLabel.text = "Takaffal"
        header.search.isHidden = true
        header.backBtn.isHidden = false
        header.notiBtn.addTarget(self,
                                 action: #selector(openNotifications),
                                 for: .touchUpInside)

        headerContainer.addSubview(header)
        headerContainer.backgroundColor = .clear
        headerView = header
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
            print("❌ Failed to load BottomNavView.xib")
            return
        }

        nav.frame = navContainer.bounds
        nav.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Example role handling
        let currentRole: UserRole = .donor

        switch currentRole {
        case .donor:
            // Hide EVERYTHING in BottomNavView
            nav.listBtn.isHidden = true
            nav.listLab.isHidden = true

            nav.ngoLab.isHidden = true

            nav.proBtn.isHidden = true
            nav.proLab.isHidden = true

            nav.impBtn.isHidden = true
            nav.ompLab.isHidden = true   // (impact label)

            nav.userBtn.isHidden = true
            nav.userLab.isHidden = true

            nav.hisBtn.isHidden = true
            nav.hisLab.isHidden = true

            nav.heartBtn.isHidden = true
            nav.donLab.isHidden = true

            nav.formBtn.isHidden = true


        case .ngo:
        
            // Hide EVERYTHING in BottomNavView
            nav.listBtn.isHidden = false
            nav.listLab.isHidden = false

            nav.ngoLab.isHidden = true

            nav.proBtn.isHidden = false
            nav.proLab.isHidden = false

            nav.impBtn.isHidden = false
            nav.ompLab.isHidden = false  // (impact label)

            nav.userBtn.isHidden = true
            nav.userLab.isHidden = true

            nav.hisBtn.isHidden = false
            nav.hisLab.isHidden = false

            nav.heartBtn.isHidden = true
            nav.donLab.isHidden = true

            nav.formBtn.isHidden = true
            
        case .admin:
            // Hide EVERYTHING in BottomNavView
            nav.listBtn.isHidden = true
            nav.listLab.isHidden = true

            nav.ngoLab.isHidden = true

            nav.proBtn.isHidden = true
            nav.proLab.isHidden = true

            nav.impBtn.isHidden = true
            nav.ompLab.isHidden = true   // (impact label)

            nav.userBtn.isHidden = true
            nav.userLab.isHidden = true

            nav.hisBtn.isHidden = true
            nav.hisLab.isHidden = true

            nav.heartBtn.isHidden = true
            nav.donLab.isHidden = true

            nav.formBtn.isHidden = true

        }
        
        nav.listBtn.addTarget(self, action: #selector(openHome), for: .touchUpInside)
        nav.hisBtn.addTarget(self, action: #selector(openHistory), for: .touchUpInside)
        nav.impBtn.addTarget(self, action: #selector(openImpact), for: .touchUpInside)
        nav.proBtn.addTarget(self, action: #selector(openProfile), for: .touchUpInside)
        nav.userBtn.addTarget(self, action: #selector(openUsers), for: .touchUpInside)

        nav.backgroundColor = .clear
        navContainer.addSubview(nav)
        bottomNav = nav
    }

    // MARK: - Nav Actions
    @objc private func openHome() { print("🏠 Home tapped") }
    @objc private func openHistory() { print("📜 History tapped") }
    @objc private func openImpact() { print("📈 Impact tapped") }
    @objc private func openProfile() { print("👤 Profile tapped") }
    @objc private func openUsers() { print("👥 Users tapped") }
}
