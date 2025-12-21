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
           guard let nav = Bundle.main
               .loadNibNamed("BottomNavView", owner: nil, options: nil)?
               .first as? BottomNavView else {
               print("❌ Failed to load BottomNavView.xib")
               return
           }

           nav.frame = navContainer.bounds
           nav.autoresizingMask = [.flexibleWidth, .flexibleHeight]

           // Example role handling
           let currentRole: UserRole = .ngo

           switch currentRole {
           case .donor:
               nav.formBtn.isHidden = false
               nav.listBtn.isHidden = true
               nav.proBtn.isHidden = true
               nav.impBtn.isHidden = true
               nav.userBtn.isHidden = true
               nav.hisBtn.isHidden = true
               nav.heartBtn.isHidden = true

           case .ngo:
               nav.formBtn.isHidden = true
               nav.listBtn.isHidden = false
               nav.proBtn.isHidden = false
               nav.impBtn.isHidden = false
               nav.hisBtn.isHidden = false
               nav.userBtn.isHidden = true
               nav.heartBtn.isHidden = true

           case .admin:
               nav.formBtn.isHidden = true
               nav.listBtn.isHidden = true
               nav.proBtn.isHidden = true
               nav.impBtn.isHidden = true
               nav.hisBtn.isHidden = true
               nav.userBtn.isHidden = true
               nav.heartBtn.isHidden = true
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
