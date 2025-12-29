
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

    // Role is set by child screens or after Firestore fetch
    var currentRole: UserRole = .donor {
        didSet { applyRoleToNav() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !didSetupViews {
            didSetupViews = true
            setupHeader()
            setupNav()
            applyRoleToNav()
        }
    }

    // MARK: - Header
    private func setupHeader() {
        guard let header = Bundle.main
            .loadNibNamed("HeaderView", owner: nil, options: nil)?
            .first as? HeaderView else { return }

        header.frame = headerContainer.bounds
        header.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        header.takaffalLabel.text = "Takaffal"
        header.backBtn.isHidden = true
        header.notiBtn.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)

        headerContainer.addSubview(header)
        headerContainer.backgroundColor = .clear
        headerView = header
    }

    @objc private func openNotifications() {
        print("🔔 Notifications tapped")
    }

    // MARK: - Bottom Nav
    private func setupNav() {
        guard let nav = Bundle.main
            .loadNibNamed("BottomNavView", owner: nil, options: nil)?
            .first as? BottomNavView else { return }

        nav.frame = navContainer.bounds
        nav.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        nav.listBtn.addTarget(self, action: #selector(openHome), for: .touchUpInside)
        nav.hisBtn.addTarget(self, action: #selector(openHistory), for: .touchUpInside)
        nav.impBtn.addTarget(self, action: #selector(openImpact), for: .touchUpInside)
        nav.proBtn.addTarget(self, action: #selector(openProfile), for: .touchUpInside)
        nav.userBtn.addTarget(self, action: #selector(openUsers), for: .touchUpInside)

        nav.backgroundColor = .clear
        navContainer.addSubview(nav)
        bottomNav = nav
    }

    // MARK: - Role Handling
    private func applyRoleToNav() {
        guard let nav = bottomNav else { return }

        nav.formBtn.isHidden = true
        nav.listBtn.isHidden = true
        nav.proBtn.isHidden = true
        nav.impBtn.isHidden = true
        nav.hisBtn.isHidden = true
        nav.userBtn.isHidden = true
        nav.heartBtn.isHidden = true

        switch currentRole {
        case .donor:
            nav.formBtn.isHidden = false

        case .ngo:
            nav.listBtn.isHidden = false
            nav.proBtn.isHidden = false
            nav.impBtn.isHidden = false
            nav.hisBtn.isHidden = false

        case .admin:
            nav.userBtn.isHidden = false
        }
    }

    // MARK: - Nav Actions
    @objc private func openHome()    { print("🏠 Home") }
    @objc private func openHistory() { print("📜 History") }
    @objc private func openImpact()  { print("📈 Impact") }
    @objc private func openProfile() { print("👤 Profile") }
    @objc private func openUsers()   { print("👥 Users") }
}


