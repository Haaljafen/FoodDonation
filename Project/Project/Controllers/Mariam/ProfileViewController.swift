//
//  ProfileViewController.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 20/12/2025.
//

import UIKit

class ProfileViewController: UIViewController {
    
//    @IBOutlet weak var headerContainer: UIView!
//    @IBOutlet weak var navContainer: UIView!
    @IBOutlet weak var navContainer: UIView!
    @IBOutlet weak var headerContainer: UIView!
    
    private var headerView: HeaderView?
    private var bottomNav: BottomNavView?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true

        setupHeader()
        setupNav()
        
//        configureForRole()
    }
    
//
//    private func configureForRole() {
//        let role: UserRole = .donor
//
//        AchievementsButton.isHidden = role != .donor
//        OrganizationButton.isHidden = role != .ngo
//    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("Nav frame:", navContainer.frame)
    }
    
    

    // MARK: - Header
    private func setupHeader() {
        // prevent duplicates (important if view reloads)
        headerContainer.subviews.forEach { $0.removeFromSuperview() }

        guard let header = Bundle.main
            .loadNibNamed("HeaderView", owner: nil, options: nil)?
            .first as? HeaderView else {
            print("❌ Failed to load HeaderView.xib")
            return
        }

        header.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(header)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            header.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            header.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor)
        ])

        header.takaffalLabel.text = "Profile"
        header.backBtn.isHidden = true
        header.search.isHidden = true

        header.notiBtn.addTarget(self,
                                 action: #selector(openNotifications),
                                 for: .touchUpInside)

        headerContainer.backgroundColor = .clear
        self.headerView = header
    }

    @objc private func openNotifications() {
        print("🔔 Notifications tapped")
    }

    // MARK: - Bottom Nav
    private func setupNav() {
        navContainer.subviews.forEach { $0.removeFromSuperview() }

        guard let nav = Bundle.main
            .loadNibNamed("BottomNavView", owner: nil, options: nil)?
            .first as? BottomNavView else {
            print("❌ Failed to load BottomNavView.xib")
            return
        }

        nav.translatesAutoresizingMaskIntoConstraints = false
        navContainer.addSubview(nav)

        NSLayoutConstraint.activate([
            nav.topAnchor.constraint(equalTo: navContainer.topAnchor),
            nav.leadingAnchor.constraint(equalTo: navContainer.leadingAnchor),
            nav.trailingAnchor.constraint(equalTo: navContainer.trailingAnchor),
            nav.bottomAnchor.constraint(equalTo: navContainer.bottomAnchor)
        ])

        let currentRole: UserRole = .donor

        switch currentRole {
        case .donor:
            nav.formBtn.isHidden = true
            nav.listBtn.isHidden = true
            nav.proBtn.isHidden = false
            nav.impBtn.isHidden = false
            nav.userBtn.isHidden = true
            nav.hisBtn.isHidden = false
            nav.heartBtn.isHidden = false

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
        bottomNav = nav
        

    }

    // MARK: - Nav Actions
    @objc private func openHome() { print("🏠 Home tapped") }
    @objc private func openHistory() { print("📜 History tapped") }
    @objc private func openImpact() { print("📈 Impact tapped") }
    @objc private func openProfile() { print("👤 Profile tapped") }
    @objc private func openUsers() { print("👥 Users tapped") }
}
