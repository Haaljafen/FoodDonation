//
//  ChangePasswordViewController.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 23/12/2025.
//

import UIKit

class ChangePasswordViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = UIColor.white

    }
    
   
    @IBOutlet weak var navContainer: UIView!
    @IBOutlet weak var headerContainer: UIView!
    
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
            print("Nav container frame:", navContainer.frame)
            print("Safe area insets:", view.safeAreaInsets)
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
        header.search.isHidden = true
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

        nav.translatesAutoresizingMaskIntoConstraints = false
        navContainer.addSubview(nav)

        NSLayoutConstraint.activate([
            nav.topAnchor.constraint(equalTo: navContainer.topAnchor),
            nav.bottomAnchor.constraint(equalTo: navContainer.bottomAnchor),
            nav.leadingAnchor.constraint(equalTo: navContainer.leadingAnchor),
            nav.trailingAnchor.constraint(equalTo: navContainer.trailingAnchor)
        ])


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
