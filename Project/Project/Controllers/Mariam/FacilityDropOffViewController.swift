//
//  FacilityDropOffViewController.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 25/12/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class FacilityDropOffViewController: UIViewController {
    
    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var navContainer: UIView!
    
    private var headerView: HeaderView?
    private var bottomNav: BottomNavView?
    private var didSetupViews = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
            print("Failed to load HeaderView.xib")
            return
        }

        header.frame = headerContainer.bounds
        header.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Customize header
        header.takaffalLabel.text = "Takaffal"
        header.search.isHidden = true
        header.backBtn.isHidden = false
        
        header.backBtn.addTarget(self,
                                 action: #selector(didTapBack),
                                 for: .touchUpInside)


        header.notiBtn.addTarget(self,
                                 action: #selector(openNotifications),
                                 for: .touchUpInside)

        headerContainer.addSubview(header)
        headerContainer.backgroundColor = .clear

        self.headerView = header

    }
    
    @objc private func didTapBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func openNotifications() {
        print("Notifications tapped")
        // later: push notifications screen
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

           nav.listBtn.addTarget(self, action: #selector(openHome), for: .touchUpInside)
           nav.hisBtn.addTarget(self, action: #selector(openHistory), for: .touchUpInside)
           nav.impBtn.addTarget(self, action: #selector(openImpact), for: .touchUpInside)
           nav.proBtn.addTarget(self, action: #selector(openProfile), for: .touchUpInside)
           nav.userBtn.addTarget(self, action: #selector(openUsers), for: .touchUpInside)

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

                self.configureNav(nav, for: role)
            }
    }
    
    private func configureNav(_ nav: BottomNavView, for role: UserRole) {

        switch role {

        case .donor:
            nav.formBtn.isHidden = true
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
       @objc private func openHome() { print("🏠 Home tapped") }
       @objc private func openHistory() { print("📜 History tapped") }
       @objc private func openImpact() { print("📈 Impact tapped") }
       @objc private func openProfile() { print("👤 Profile tapped") }
       @objc private func openUsers() { print("👥 Users tapped") }
   }


