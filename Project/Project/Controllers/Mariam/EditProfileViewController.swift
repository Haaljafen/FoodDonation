//
//  EditProfileViewController.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 22/12/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseDatabase
import Cloudinary

class EditProfileViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var navContainer: UIView!
    @IBOutlet weak var headerContainer: UIView!
    
    @IBOutlet weak var organizationNameContainer: UIView!
    @IBOutlet weak var usernameContainer: UIView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var ProfileImageEdit: UIButton!
    @IBOutlet weak var organizationNameTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    
    private var currentUserRole: UserRole?
    private var headerView: HeaderView?
    private var bottomNav: BottomNavView?
    private var didSetupViews = false
    
    private var currentUser: User?
    private var selectedImage: UIImage?
    private let db = Firestore.firestore()
    private let rtdb = Database.database().reference()


    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
        
        navigationController?.navigationBar.tintColor = UIColor.white
        
        loadUser()

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !didSetupViews {
            didSetupViews = true
            setupHeader()
            setupNav()
        }
    }
    
    // MARK: - Load User

    private func loadUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("Users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let _ = snapshot?.data(),
                  let user = try? snapshot?.data(as: User.self) else { return }

            DispatchQueue.main.async {
                self.currentUser = user
                self.configureUI(with: user)
            }
        }
    }
    
    
    // MARK: - Configure UI
    
    private func configureUI(with user: User) {

        phoneNumberTextField.text = user.phone
        addressTextField.text = user.address
        countryTextField.text = user.country
        cityTextField.text = user.city

        switch user.role {

        case .donor, .admin:
            usernameContainer.isHidden = false
            organizationNameContainer.isHidden = true
            usernameTextField.text = user.username

        case .ngo:
            usernameContainer.isHidden = true
            organizationNameContainer.isHidden = false
            organizationNameTextField.text = user.organizationName
        }

        loadProfileImage(urlString: user.profileImageUrl)
    }

    
    // MARK: - Image Editing

    @IBAction func editPhotoTapped(_ sender: UIButton) {
        presentImagePicker()
    }

    private func presentImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    private func loadProfileImage(urlString: String?) {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data else { return }
            DispatchQueue.main.async {
                self?.profileImageView.image = UIImage(data: data)
            }
        }.resume()
    }
    
    
    // MARK: - Save Profile
    
    @IBAction func saveTapped(_ sender: UIButton) {
        
        guard let user = currentUser else { return }
        print("Nav controller:", self.navigationController as Any)

        validateFields(for: user) { [weak self] isValid in
            guard let self = self, isValid else { return }

            self.saveButton.isEnabled = false

            self.uploadImageIfNeeded { imageUrl in
                guard let uid = Auth.auth().currentUser?.uid else { return }

                var updates: [String: Any] = [
                    "phone": self.phoneNumberTextField.text!,
                    "address": self.addressTextField.text!,
                    "country": self.countryTextField.text!,
                    "city": self.cityTextField.text!
                ]

                if let imageUrl = imageUrl {
                    updates["profileImageUrl"] = imageUrl
                }

                switch user.role {
                case .donor, .admin:
                    updates["username"] = self.usernameTextField.text!

                case .ngo:
                    updates["organizationName"] = self.organizationNameTextField.text!.lowercased()
                }

                self.db.collection("Users").document(uid).updateData(updates) { error in
                    DispatchQueue.main.async {
                        self.saveButton.isEnabled = true

                        if let error = error {
                            self.showAlert(
                                title: "Update Failed",
                                message: error.localizedDescription
                            )
                        } else {
                            DonationService.shared.notify(
                                type: .profileUpdated,
                                relatedDonationId: nil,
                                toUserId: uid,
                                audience: nil
                            )

                            self.updateRealtimeUserMirror(
                                user: user,
                                profileImageUrl: imageUrl
                            )

                            self.showAlert(
                                title: "Success",
                                message: "Profile updated successfully.",
                                shouldGoBack: true
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Save in Real Time
    
    private func updateRealtimeUserMirror(
        user: User,
        profileImageUrl: String?
    ) {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        let finalImageUrl = profileImageUrl
            ?? currentUser?.profileImageUrl
            ?? ""

        var liveData: [String: Any] = [
            "role": user.role.rawValue,
            "profileImageUrl": finalImageUrl,
            "updatedAt": ServerValue.timestamp()
        ]

        switch user.role {
        case .donor, .admin:
            liveData["displayName"] = usernameTextField.text ?? ""

        case .ngo:
            liveData["displayName"] =
                organizationNameTextField.text?.lowercased() ?? ""
        }

        rtdb
            .child("users_live")
            .child(uid)
            .setValue(liveData)
    }

    
    
    // MARK: - Image Upload (CloudinaryService)

    private func uploadImageIfNeeded(completion: @escaping (String?) -> Void) {

        guard let image = selectedImage else {
            completion(currentUser?.profileImageUrl)
            return
        }

        CloudinaryService.shared.upload(image: image) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    completion(url)

                case .failure(let error):
                    self?.showAlert(
                        title: "Image Upload Failed",
                        message: error.localizedDescription
                    )
                    completion(nil)
                }
            }
        }
    }
    
    // MARK: - Validation (Async)

    private func validateFields(
        for user: User,
        completion: @escaping (Bool) -> Void
    ) {

        // Common fields
        if phoneNumberTextField.text?.isEmpty == true ||
            addressTextField.text?.isEmpty == true ||
            countryTextField.text?.isEmpty == true ||
            cityTextField.text?.isEmpty == true {

            showAlert(
                title: "Missing Information",
                message: "Please fill all required fields."
            )
            completion(false)
            return
        }

        switch user.role {
        case .donor, .admin:
            guard let username = usernameTextField.text?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                  !username.isEmpty else {

                showAlert(
                    title: "Missing Username",
                    message: "Username cannot be empty."
                )
                completion(false)
                return
            }

            if username.contains(" ") {
                showAlert(
                    title: "Invalid Username",
                    message: "Username cannot contain spaces."
                )
                completion(false)
                return
            }

            checkUsernameAvailability(username: username.lowercased()) { isAvailable in
                if !isAvailable {
                    self.showAlert(
                        title: "Username Taken",
                        message: "This username is already in use."
                    )
                    completion(false)
                } else {
                    completion(true)
                }
            }

        case .ngo:
            guard let orgName = organizationNameTextField.text?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                  !orgName.isEmpty else {

                showAlert(
                    title: "Missing Organization Name",
                    message: "Organization name is required."
                )
                completion(false)
                return
            }

            if orgName.contains(" ") {
                showAlert(
                    title: "Invalid Organization Name",
                    message: "Organization name cannot contain spaces."
                )
                completion(false)
                return
            }

            checkOrganizationNameAvailability(orgName: orgName.lowercased()) { isAvailable in
                if !isAvailable {
                    self.showAlert(
                        title: "Organization Exists",
                        message: "This organization name already exists."
                    )
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    private func checkUsernameAvailability(
        username: String,
        completion: @escaping (Bool) -> Void
    ) {

        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        db.collection("Users")
            .whereField("username", isEqualTo: username)
            .getDocuments { snapshot, error in

                if let error = error {
                    print("Username check failed:", error.localizedDescription)
                    completion(false)
                    return
                }

                let documents = snapshot?.documents ?? []

                let isAvailable = documents.allSatisfy {
                    $0.documentID == uid
                }

                completion(isAvailable)
            }
    }

    
    private func checkOrganizationNameAvailability(
        orgName: String,
        completion: @escaping (Bool) -> Void
    ) {

        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        db.collection("Users")
            .whereField("organizationName", isEqualTo: orgName)
            .getDocuments { snapshot, error in

                if let error = error {
                    print("Org name check failed:", error.localizedDescription)
                    completion(false)
                    return
                }

                let documents = snapshot?.documents ?? []

                let isAvailable = documents.allSatisfy {
                    $0.documentID == uid
                }

                completion(isAvailable)
            }
    }

    
    // MARK: - Alerts

    private func showAlert(title: String,message: String,shouldGoBack: Bool = false) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            if shouldGoBack {
                self.navigationController?.popViewController(animated: true)
            }
        })

        present(alert, animated: true)
    }


    

    // MARK: - Header

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
        let sb = UIStoryboard(name: "NotificationsStoryboard", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "NotificationVC") as? NotificationViewController else {
            print("❌ Could not instantiate NotificationViewController")
            return
        }
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            present(vc, animated: true)
        }
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

        nav.listBtn.addTarget(self, action: #selector(openList), for: .touchUpInside)
        nav.hisBtn.addTarget(self, action: #selector(openHistory), for: .touchUpInside)
        nav.impBtn.addTarget(self, action: #selector(openImpact), for: .touchUpInside)
        nav.proBtn.addTarget(self, action: #selector(openProfile), for: .touchUpInside)
        nav.userBtn.addTarget(self, action: #selector(openUsers), for: .touchUpInside)
        nav.heartBtn.addTarget(self, action: #selector(openDonations), for: .touchUpInside)
        nav.formBtn.addTarget(self,action: #selector(openDonationForm),for: .touchUpInside)

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
                
                self.currentUserRole = role
                self.configureNav(nav, for: role)
            }
    }
    
    private func push(_ vc: UIViewController) {
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            present(vc, animated: true)
        }
    }

    
    private func configureNav(_ nav: BottomNavView, for role: UserRole) {
        
        let allButtons = [
            nav.listBtn,
            nav.hisBtn,
            nav.impBtn,
            nav.proBtn,
            nav.userBtn,
            nav.formBtn,
            nav.heartBtn
        ]

        allButtons.forEach { $0?.isHidden = true }

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
    
    @objc private func openDonations() {
        let sb = UIStoryboard(name: "History&statusNoora", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "History&statusNoora")
        push(vc)
    }
    
    @objc private func openList() {

        guard let role = currentUserRole else {
            print("Role not loaded yet")
            return
        }

        switch role {

        case .donor:
            let sb = UIStoryboard(name: "AbdullaStoryboard1", bundle: nil)
            let vc = sb.instantiateViewController(
                withIdentifier: "AbdullaViewController1"
            )
            push(vc)

        case .ngo:
            let sb = UIStoryboard(name: "HajarStoryboard", bundle: nil)
            let vc = sb.instantiateViewController(
                withIdentifier: "HajarHomeVC"
            )
            push(vc)
            
        default:
            return
            
        }
    }

    @objc private func openHistory() {
        let sb = UIStoryboard(name: "History&statusNoora", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "History&statusNoora")
        push(vc)
    }
    
    @objc private func openImpact() {
        let sb = UIStoryboard(name: "ImpactNoora", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "impactNoora")
        push(vc)
    }
    
    @objc private func openProfile() {
        let sb = UIStoryboard(name: "MariamStoryboard2", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "ProfileViewController")
        push(vc)
    }
    
    @objc private func openUsers() {
        let sb = UIStoryboard(name: "AdminStoryboard", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "UsersVC")
        push(vc)
    }
    
    private func pushIfNeeded(_ vc: UIViewController) {
        if let top = navigationController?.topViewController,
           type(of: top) == type(of: vc) {
            return
        }
        push(vc)
    }
    
    @objc private func openDonationForm() {

        guard let role = currentUserRole else {
            print("Role not loaded yet")
            return
        }

        guard role == .donor else {
            print("Only donors can open donation form")
            return
        }

        let sb = UIStoryboard(name: "HajarStoryboard2", bundle: nil)
        let vc = sb.instantiateViewController(
            withIdentifier: "CreateDonationViewController"
        )

        push(vc)
    }
}


// MARK: - Image Picker Delegate

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        picker.dismiss(animated: true)
        
        guard let image = info[.editedImage] as? UIImage else { return }
        
        selectedImage = image
        profileImageView.image = image
    }
}
