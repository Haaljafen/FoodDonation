//
//  BaseChromeViewController.swift
//  Takaffal
//
//  Created by Noora Humaid on 20/12/2025.
//
import UIKit

class BaseChromeViewController: UIViewController {

    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var navContainer: UIView!

    private var headerView: HeaderView?
    private var bottomNav: BottomNavView?

    private var didSetupViews = false

    // ✅ Each screen can set this (or you set it after Firestore fetch)
    var currentRole: UserRole = .donor {
        didSet { applyRoleToNav() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !didSetupViews {
            didSetupViews = true
            setupHeader()
            setupNav()
            applyRoleToNav() // ✅ apply after nav is created
        }
        
        print("navContainer frame:", navContainer.frame)
        print("headerContainer frame:", headerContainer.frame)

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
        header.backBtn.isHidden = true

        header.notiBtn.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)

        headerContainer.addSubview(header)
        headerContainer.backgroundColor = .clear
        self.headerView = header
    }

    @objc private func openNotifications() {
        print("🔔 Notifications tapped")
    }

    // MARK: - Bottom Nav
    private func setupNav() {

        navContainer.clipsToBounds = true

        let loaded = Bundle.main.loadNibNamed("BottomNavView", owner: nil, options: nil)
        print("📦 BottomNavView.xib loaded objects:", loaded?.count ?? 0)

        guard let first = loaded?.first else {
            print("❌ BottomNavView.xib returned nil")
            return
        }

        print("👀 First object type:", type(of: first))

        guard let nav = first as? BottomNavView else {
            print("❌ First object is NOT BottomNavView. Check xib root class!")
            return
        }

        // 🔥 Make it impossible to miss
//        nav.translatesAutoresizingMaskIntoConstraints = false
//        nav.backgroundColor = .systemRed.withAlphaComponent(0.25)

        navContainer.addSubview(nav)

        NSLayoutConstraint.activate([
            nav.leadingAnchor.constraint(equalTo: navContainer.leadingAnchor),
            nav.trailingAnchor.constraint(equalTo: navContainer.trailingAnchor),
            nav.topAnchor.constraint(equalTo: navContainer.topAnchor),
            nav.bottomAnchor.constraint(equalTo: navContainer.bottomAnchor)
        ])

        navContainer.layoutIfNeeded()
        print("🔧 nav frame after layout:", nav.frame)

        self.bottomNav = nav
        view.bringSubviewToFront(navContainer)

        print("✅ BottomNav added + constrained. nav frame:", nav.frame)
    }

    // ✅ One place to show/hide based on role
    private func applyRoleToNav() {
        guard let nav = bottomNav else { return }

        func set(_ view: UIView?, hidden: Bool) { view?.isHidden = hidden }

        // Everything you have (buttons + labels)
        let allViews: [UIView?] = [
            nav.listBtn, nav.listLab,
            nav.hisBtn, nav.hisLab,
            nav.impBtn, nav.ompLab,     // ⚠️ make sure this outlet name is correct
            nav.proBtn, nav.proLab,
            nav.userBtn, nav.userLab,
            nav.heartBtn, nav.donLab,
            nav.formBtn,
            nav.ngoLab
        ]

        // Hide all first
        allViews.forEach { set($0, hidden: true) }

        // Role-specific views (NOW actually used ✅)
        let donorViews: [UIView?] = [
            nav.formBtn,
            nav.listBtn, nav.listLab,
            nav.hisBtn, nav.hisLab,
            nav.proBtn, nav.proLab
        ]

        let ngoViews: [UIView?] = [
            nav.hisBtn, nav.hisLab,
            nav.proBtn, nav.proLab,
            nav.ngoLab
        ]

        let adminViews: [UIView?] = [
            nav.userBtn, nav.userLab,
            nav.heartBtn, nav.donLab,
            nav.hisBtn, nav.hisLab,
            nav.proBtn, nav.proLab
        ]

        let viewsToShow: [UIView?]
        switch currentRole {
        case .donor:
            viewsToShow = donorViews
        case .ngo:
            viewsToShow = ngoViews
        case .admin:
            viewsToShow = adminViews
        }

        viewsToShow.forEach { set($0, hidden: false) }
    }


    // MARK: - Actions
    @objc func openHome() { print("🏠 Home") }
    @objc func openHistory() { print("📜 History") }
    @objc func openImpact() { print("📈 Impact") }
    @objc func openProfile() { print("👤 Profile") }
    @objc func openUsers() { print("👥 Users") }
    @objc func openDonations() { print("🎁 Donations") }
    @objc func openForm() { print("📝 Form") }
}
