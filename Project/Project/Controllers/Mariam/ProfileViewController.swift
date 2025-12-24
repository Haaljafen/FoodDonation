//
//  ProfileViewController.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 20/12/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseDatabase

class ProfileViewController: UIViewController {
    

    @IBOutlet weak var navContainer: UIView!
    @IBOutlet weak var headerContainer: UIView!
    
    @IBOutlet weak var chatbotButton: UIButton!
    @IBOutlet weak var achievementsButton: UIButton!
    @IBOutlet weak var editProfileButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var organizationButton: UIButton!
    @IBOutlet weak var notificationSwitch: UISwitch!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    
    private var headerView: HeaderView?
    private var bottomNav: BottomNavView?
    
    private let rtdb = Database.database().reference()
    private var organizationName: String?
    private var profileListenerHandle: DatabaseHandle?
    private var didLoadInitialProfile = false


    override func viewDidLoad() {
        super.viewDidLoad()
//        navigationItem.hidesBackButton = true

        setupUI()
        setupActions()
        setupHeader()
        setupNav()
        listenToRealtimeProfileUpdates()
        loadNotificationSetting()
        loadProfileFromFirestoreIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.bounds.height / 2
        profileImageView.clipsToBounds = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let handle = profileListenerHandle,
           let uid = Auth.auth().currentUser?.uid {
            rtdb.child("users_live")
                .child(uid)
                .removeObserver(withHandle: handle)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    

    private func listenToRealtimeProfileUpdates() {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        profileListenerHandle = rtdb
            .child("users_live")
            .child(uid)
            .observe(.value, with: { [weak self] snapshot in

                guard
                    let self = self,
                    let data = snapshot.value as? [String: Any],
                    let roleString = data["role"] as? String,
                    let role = UserRole(rawValue: roleString)
                else { return }

                let displayName = data["displayName"] as? String ?? ""
                let imageUrl = data["profileImageUrl"] as? String

                DispatchQueue.main.async {
                    let displayName = data["displayName"] as? String ?? ""
                    
                    self.didLoadInitialProfile = true
                    self.usernameLabel.text = displayName
                    
                    if role == .ngo {
                        self.organizationName = displayName
                    }

                    self.roleLabel.text = role.rawValue.capitalized

                    self.configureSettings(for: role)

                    if let imageUrl = imageUrl {
                        self.loadImage(from: imageUrl)
                    }
                }
            }
    )}
    
    
    private func loadProfileFromFirestoreIfNeeded() {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("Users")
            .document(uid)
            .getDocument { [weak self] snapshot, error in

                guard
                    let self = self,
                    let data = snapshot?.data(),
                    let roleString = data["role"] as? String,
                    let role = UserRole(rawValue: roleString)
                else { return }

                if self.didLoadInitialProfile {
                    return
                }

                let displayName: String
                switch role {
                case .donor, .admin:
                    displayName = data["username"] as? String ?? ""
                case .ngo:
                    displayName = data["organizationName"] as? String ?? ""
                    self.organizationName = displayName
                }

                let imageUrl = data["profileImageUrl"] as? String

                DispatchQueue.main.async {
                    self.usernameLabel.text = displayName
                    self.roleLabel.text = role.rawValue.capitalized
                    self.configureSettings(for: role)

                    if let imageUrl = imageUrl {
                        self.loadImage(from: imageUrl)
                    }

                    self.didLoadInitialProfile = true
                }
            }
    }

    
    // MARK: - UI Setup

    private func setupUI() {
        usernameLabel.text = "—"
        roleLabel.text = "—"
    }
    
    private func setupActions() {
        logoutButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)
        notificationSwitch.addTarget(self, action: #selector(notificationSwitchChanged(_:)), for: .valueChanged)
    }
    
    
    // MARK: - Role-based Settings UI

    private func configureSettings(for role: UserRole) {

        switch role {

        case .donor:
            achievementsButton.isHidden = false
            organizationButton.isHidden = true

        case .ngo:
            achievementsButton.isHidden = true
            organizationButton.isHidden = false

            let name = organizationName ?? "—"
            organizationButton.setTitle(
                "Organization \(name)",
                for: .normal
            )

        case .admin:
            achievementsButton.isHidden = true
            organizationButton.isHidden = true
        }
    }

    
    
    // MARK: - Notification Switch
    
    @IBAction func notificationSwitchChanged(_ sender: UISwitch) {

        let enabled = sender.isOn
        UserDefaults.standard.set(enabled, forKey: "notificationsEnabled")

        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("Users")
            .document(uid)
            .updateData([
                "notificationsEnabled": enabled
            ])
    }
    
    private func loadNotificationSetting() {

        let enabled = UserDefaults.standard.bool(
            forKey: "notificationsEnabled"
        )
        notificationSwitch.isOn = enabled
    }


    
    // MARK: - Logout

    @IBAction func didTapLogout(_ sender: UIButton) {
        do {
               try Auth.auth().signOut()
               redirectToLogin()
           } catch {
               showAlert(title: "Error", message: "Failed to log out.")
           }
    }
    
    private func redirectToLogin() {

        let storyboard = UIStoryboard(name: "MariamStoryboard1", bundle: nil)
        let loginVC = storyboard.instantiateViewController(
            withIdentifier: "LoginViewController"
        )
        let nav = UINavigationController(rootViewController: loginVC)
        
         if let window = UIApplication.shared.connectedScenes
             .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
             .first {

             window.rootViewController = nav
             window.makeKeyAndVisible()
         }
    }

   
    // MARK: - Helpers

    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self, let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.profileImageView.image = image
            }
        }.resume()
    }

    private func showAlert(title: String, message: String, onOK: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in onOK?() })
        present(alert, animated: true)
    }
    

    // MARK: - Header
    private func setupHeader() {
        headerContainer.subviews.forEach { $0.removeFromSuperview() }

        guard let header = Bundle.main
            .loadNibNamed("HeaderView", owner: nil, options: nil)?
            .first as? HeaderView else {
            print("Failed to load HeaderView.xib")
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
        bottomNav = nil

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
