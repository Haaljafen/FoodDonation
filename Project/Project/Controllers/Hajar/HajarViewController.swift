//import UIKit
//
//class HajarViewController: UIViewController {
//
//    // MARK: - Outlets (connect these in storyboard)
//    @IBOutlet weak var headerContainer: UIView!
//    @IBOutlet weak var navContainer: UIView!
//
//    // MARK: - State
//    private var didAddHeader = false
//    private var didAddNav = false
//
//    // MARK: - Lifecycle
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//
//        if !didAddHeader {
//            setupHeader()
//            didAddHeader = true
//        }
//
//        if !didAddNav {
//            setupNav()
//            didAddNav = true
//        }
//    }
//
//    // MARK: - Header
//    private func setupHeader() {
//        print("⚪️ setupHeader, headerContainer frame:", headerContainer.frame)
//
//        guard let header = Bundle.main
//            .loadNibNamed("HeaderView", owner: nil, options: nil)?
//            .first as? HeaderView else {
//                print("❌ Failed to load HeaderView.xib")
//                return
//        }
//
//        print("✅ HeaderView loaded")
//
//        header.frame = headerContainer.bounds
//        header.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//
//        // Customise header
//        header.takaffalLabel.text = "Takaffal"
//        header.backBtn.isHidden = true
//        header.notiBtn.addTarget(self,
//                                 action: #selector(openNotifications),
//                                 for: .touchUpInside)
//
//        headerContainer.addSubview(header)
//        headerContainer.backgroundColor = .clear
//
//        print("✅ Header added to container, header frame:", header.frame)
//    }
//
//    @objc private func openNotifications() {
//        print("🔔 Notifications tapped")
//    }
//
//    // MARK: - Bottom Nav
//    private func setupNav() {
//        print("⚪️ setupNav, navContainer frame:", navContainer.frame)
//
//        guard let nav = Bundle.main
//            .loadNibNamed("BottomNavView", owner: nil, options: nil)?
//            .first as? BottomNavView else {
//                print("❌ Failed to load BottomNavView.xib or cast to BottomNavView")
//                return
//        }
//
//        print("✅ BottomNavView loaded")
//
//        nav.frame = navContainer.bounds
//        nav.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//
//        // Button actions
//        nav.listBtn.addTarget(self,
//                              action: #selector(openHome),
//                              for: .touchUpInside)
//        nav.profileBtn.addTarget(self,
//                                 action: #selector(openProfile),
//                                 for: .touchUpInside)
//
//        navContainer.addSubview(nav)
//        
//        // comment this out while debugging if you want to see the container color
////        navContainer.backgroundColor = .red
////        header.backBtn.isHidden = true
////        nav.donationsBtn.isHidden = true
////        nav.donationsLab.isHidden = true
////        nav.ngoLab.isHidden = true
////        nav.usersBtn.isHidden = true
////        nav.usersLab.isHidden = true
//
//        print("✅ Nav added to container, nav frame:", nav.frame)
//    }
//
//    @objc private func openHome() {
//        print("🏠 Home tapped")
//    }
//
//    @objc private func openProfile() {
//        print("👤 Profile tapped")
//    }
//}

import UIKit

class HajarViewController: UIViewController {

    // MARK: - Outlets (from storyboard)
    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var navContainer: UIView!

    // Keep references if you need them later
    private var headerView: HeaderView?
    private var bottomNav: BottomNavView?

    // Make sure we only add them once
    private var didSetupViews = false

    // MARK: - Lifecycle
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // This is called multiple times so protect it
        if !didSetupViews {
            didSetupViews = true
            setupHeader()
            setupNav()
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

        // Customize header
        header.takaffalLabel.text = "Takaffal"
        header.backBtn.isHidden = true

        header.notiBtn.addTarget(self,
                                 action: #selector(openNotifications),
                                 for: .touchUpInside)

        headerContainer.addSubview(header)
        headerContainer.backgroundColor = .clear

        self.headerView = header

        print("✅ Header added to container, header frame:", header.frame)
    }

    @objc private func openNotifications() {
        print("🔔 Notifications tapped")
        // later: push notifications screen
    }

    // MARK: - Bottom Nav

    private func setupNav() {
        print("⚪️ setupNav, navContainer frame:", navContainer.frame)

        guard let nav = Bundle.main
            .loadNibNamed("BottomNavView", owner: nil, options: nil)?
            .first as? BottomNavView else {
            print("❌ Failed to load BottomNavView.xib or cast to BottomNavView")
            return
        }

        print("✅ BottomNavView loaded")

        nav.frame = navContainer.bounds
        nav.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // ====== CONTROL WHAT IS HIDDEN HERE ======

        // Example: assume current user is a donor for now
        let currentRole: UserRole = .ngo   // later: replace with real value

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


        case .ngo:
        
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

        }

        // ====== BUTTON ACTIONS ======
        nav.listBtn.addTarget(self,
                              action: #selector(openHome),
                              for: .touchUpInside)

        nav.hisBtn.addTarget(self,
                                 action: #selector(openHistory),
                                 for: .touchUpInside)

        nav.impBtn.addTarget(self,
                                action: #selector(openImpact),
                                for: .touchUpInside)

        nav.proBtn.addTarget(self,
                                 action: #selector(openProfile),
                                 for: .touchUpInside)

        nav.userBtn.addTarget(self,
                               action: #selector(openUsers),
                               for: .touchUpInside)

        nav.listBtn.addTarget(self,
                                   action: #selector(openDonations),
                                   for: .touchUpInside)

        // Optional styling example
        nav.backgroundColor = .clear

        navContainer.addSubview(nav)
        self.bottomNav = nav

        print("✅ Nav added to container, nav frame:", nav.frame)
    }

    // MARK: - Navigation Actions (for now just print; later you push/segue)

    @objc private func openHome() {
        print("🏠 Home tapped")
        // TODO: show Hajar's main listing screen
    }

    @objc private func openHistory() {
        print("📜 History tapped")
        // TODO: show donation history VC
    }

    @objc private func openImpact() {
        print("📈 Impact tapped")
        // TODO: show impact/analytics VC
    }

    @objc private func openProfile() {
        print("👤 Profile tapped")
        // TODO: show profile VC
    }

    @objc private func openUsers() {
        print("👥 Users tapped (admin)")
        // TODO: admin users VC
    }

    @objc private func openDonations() {
        print("🎁 Donations tapped (admin)")
        // TODO: admin donations management VC
    }
}
