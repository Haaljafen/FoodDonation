//
//  SignupViewController.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 13/12/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import Cloudinary

class SignupViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let db = Firestore.firestore()
    private var selectedRole: UserRole = .donor
    private var selectedProfileImage: UIImage?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        roleSegmentedControl.selectedSegmentIndex = 0
        selectedRole = .donor
        updateUIForRole()
        profileImageView.image = UIImage(named: "no-pfp")

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        profileImageView.clipsToBounds = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    
    // MARK: - IBOutlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var organizationContainerView: UIView!
    @IBOutlet weak var usernameContainerView: UIView!
    @IBOutlet weak var roleSegmentedControl: UISegmentedControl!
    @IBOutlet weak var organizationNameTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!
    
    
    // MARK: - Role Switching
    @IBAction func roleChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            selectedRole = .donor
        case 1:
            selectedRole = .ngo
        default:
            break
        }

        updateUIForRole()
    }
    
    private func updateUIForRole() {
        if selectedRole == .donor {
            usernameContainerView.isHidden = false
            organizationContainerView.isHidden = true
        } else {
            usernameContainerView.isHidden = true
            organizationContainerView.isHidden = false
        }
    }
    
    // MARK: - Alerts
    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    
    private func showSuccessAlert() {
        let alert = UIAlertController(title: "Success", message: "Account created successfully!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    
    // MARK: - Profile Image
    @IBAction func profileImageTapped(_ sender: UITapGestureRecognizer) {
        openImagePicker()
    }
    
    
    private func openImagePicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        let image =
            (info[.editedImage] ?? info[.originalImage]) as? UIImage

        profileImageView.image = image
        selectedProfileImage = image

        dismiss(animated: true)
    }

    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    
    private func uploadProfileImageIfNeeded(completion: @escaping (String) -> Void) {
        
        let defaultImageUrl =
        "https://res.cloudinary.com/dquu356xs/image/upload/v1765716822/no-pfp_uc0zvk.jpg"

        guard let image = selectedProfileImage else {
            completion(defaultImageUrl)
            return
        }

        CloudinaryService.shared.upload(image: image) { result in
            switch result {
            case .success(let url):
                completion(url)

            case .failure(let error):
                print("Cloudinary upload failed:", error.localizedDescription)
                completion(defaultImageUrl)
            }
        }
    }
    
    
    // MARK: - Validation
    private func validateFields() -> String? {

        let email = emailTextField.text?.trimmed ?? ""
        let password = passwordTextField.text?.trimmed ?? ""
        let phone = phoneTextField.text?.trimmed ?? ""
        let country = countryTextField.text?.trimmed ?? ""
        let city = cityTextField.text?.trimmed ?? ""
        let address = addressTextField.text?.trimmed ?? ""

        if email.isEmpty || password.isEmpty ||
           phone.isEmpty || country.isEmpty ||
           city.isEmpty || address.isEmpty {
            return "All fields are required"
        }

        if !isValidEmail(email) {
            return "Please enter a valid email address"
        }

        if password.count < 6 {
            return "Password must be at least 6 characters"
        }

        if selectedRole == .donor && usernameTextField.text?.trimmed.isEmpty == true {
            return "Username is required for donors"
        }

        if selectedRole == .ngo && organizationNameTextField.text?.trimmed.isEmpty == true {
            return "Organization name is required for NGOs"
        }

        return nil
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }


    // MARK: - Signup
    @IBAction func signUpTapped(_ sender: UIButton) {
        
        if let error = validateFields() {
            showErrorAlert(error)
            return
        }

        let email = emailTextField.text!.trimmed
        let password = passwordTextField.text!.trimmed

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error as NSError? {
                self.handleAuthError(error)
                return
            }

            guard let userId = result?.user.uid else {
                self.showErrorAlert("Failed to create account.")
                return
            }

            self.uploadProfileImageIfNeeded { imageUrl in

                let user = User(
                    id: userId,
                    role: self.selectedRole,
                    email: email,
                    phone: self.phoneTextField.text!.trimmed,
                    country: self.countryTextField.text!.trimmed,
                    city: self.cityTextField.text!.trimmed,
                    address: self.addressTextField.text!.trimmed,
                    profileImageUrl: imageUrl,
                    createdAt: Date(),
                    username: self.selectedRole == .donor ? self.usernameTextField.text?.trimmed : nil,
                    organizationName: self.selectedRole == .ngo ? self.organizationNameTextField.text?.trimmed : nil,
                    mission: nil,
                    about: nil,
                    logoUrl: nil,
                    status: self.selectedRole == .ngo ? .pending : nil,
                    verified: self.selectedRole == .ngo ? false : nil
                )

                do {
                    let data = try Firestore.Encoder().encode(user)
                    self.db.collection("Users").document(userId).setData(data)
                    self.showSuccessAlert()
                } catch {
                    self.showErrorAlert("Failed to save user data.")
                }
            }
        }
    }
    
    
    // MARK: - Firebase Auth Errors
    private func handleAuthError(_ error: NSError) {
        guard let code = AuthErrorCode(rawValue: error.code) else {
            showErrorAlert(error.localizedDescription)
            return
        }

        switch code {
        case .emailAlreadyInUse:
            showErrorAlert("This email is already registered")
        case .invalidEmail:
            showErrorAlert("Invalid email address")
        case .weakPassword:
            showErrorAlert("Password is too weak")
        case .networkError:
            showErrorAlert("Network error. Try again")
        default:
            showErrorAlert(error.localizedDescription)
        }
    }
    
    //MARK: - Login Redirecting

    @IBAction func loginTappedloginTapped(_ sender: UIButton) {
        
        let vc = storyboard?.instantiateViewController(
               withIdentifier: "LoginViewController"
           ) as! LoginViewController

        navigationController?.popViewController(animated: true)
        
    }
    
}

    // MARK: - Helpers
    private extension String {
        var trimmed: String {
            trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
