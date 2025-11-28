import UIKit

class HajarViewController: UIViewController {

    // MARK: - Outlets (connect these in storyboard)
    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var navContainer: UIView!

    // MARK: - State
    private var didAddHeader = false
    private var didAddNav = false

    // MARK: - Lifecycle
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !didAddHeader {
            setupHeader()
            didAddHeader = true
        }

        if !didAddNav {
            setupNav()
            didAddNav = true
        }
    }

    // MARK: - Header
    private func setupHeader() {
        print("⚪️ setupHeader, headerContainer frame:", headerContainer.frame)

        guard let header = Bundle.main
            .loadNibNamed("HeaderView", owner: nil, options: nil)?
            .first as? HeaderView else {
                print("❌ Failed to load HeaderView.xib")
                return
        }

        print("✅ HeaderView loaded")

        header.frame = headerContainer.bounds
        header.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Customise header
        header.takaffalLabel.text = "Takaffal"
        header.backBtn.isHidden = true
        header.notiBtn.addTarget(self,
                                 action: #selector(openNotifications),
                                 for: .touchUpInside)

        headerContainer.addSubview(header)
        headerContainer.backgroundColor = .clear

        print("✅ Header added to container, header frame:", header.frame)
    }

    @objc private func openNotifications() {
        print("🔔 Notifications tapped")
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

        // Button actions
        nav.listBtn.addTarget(self,
                              action: #selector(openHome),
                              for: .touchUpInside)
        nav.profileBtn.addTarget(self,
                                 action: #selector(openProfile),
                                 for: .touchUpInside)

        navContainer.addSubview(nav)
        // comment this out while debugging if you want to see the container color
        navContainer.backgroundColor = .red

        print("✅ Nav added to container, nav frame:", nav.frame)
    }

    @objc private func openHome() {
        print("🏠 Home tapped")
    }

    @objc private func openProfile() {
        print("👤 Profile tapped")
    }
}
