//
//  LoginViewController.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 10/12/2025.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class LoginViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private var userRole: UserRole?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - UI Setup
    private func setupUI() {
        passwordTextField.isSecureTextEntry = true
    }

    // MARK: - Actions
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        loginUser()
    }

    // MARK: - Login Flow
    private func loginUser() {

        let email = emailTextField.text?.trimmed ?? ""
        let password = passwordTextField.text?.trimmed ?? ""

        if let errorMessage = validateInputs(email: email, password: password) {
            showAlert(title: "Error", message: errorMessage)
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error as NSError? {
                self.handleAuthError(error)
                return
            }

            guard let uid = result?.user.uid else {
                self.showAlert(title: "Error", message: "Unable to retrieve user ID.")
                return
            }

            self.fetchUserRole(userId: uid)
        }
    }

    // MARK: - Validation
    private func validateInputs(email: String, password: String) -> String? {

        if email.isEmpty || password.isEmpty {
            return "Please fill in all fields."
        }

        if !email.contains("@") {
            return "Please enter a valid email address."
        }

        if password.count < 6 {
            return "Password must be at least 6 characters."
        }

        return nil
    }

    // MARK: - Fetch Role from Firestore
    private func fetchUserRole(userId: String) {

        db.collection("Users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                self.showAlert(title: "Error", message: error.localizedDescription)
                return
            }

            guard
                let data = snapshot?.data(),
                let roleString = data["role"] as? String,
                let role = UserRole(rawValue: roleString)
            else {
                self.showAlert(title: "Error", message: "User role not found.")
                return
            }

            self.userRole = role
            self.showSuccessAlert()
        }
    }

    // MARK: - Alerts
    private func showSuccessAlert() {

        let alert = UIAlertController(
            title: "Success",
            message: "You logged in successfully!",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.handleRoleRouting()
        })

        present(alert, animated: true)
    }

    private func showAlert(title: String, message: String) {

        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Role Routing
    private func handleRoleRouting() {

        guard let role = userRole else {
            showAlert(title: "Error", message: "No role assigned.")
            return
        }

        switch role {
        case .donor:
            print("Logged in as DONOR")
            // TODO: Navigate to Donor dashboard

        case .ngo:
            print("Logged in as NGO")
            // TODO: Navigate to NGO dashboard

        case .admin:
            print("Logged in as ADMIN")
            // Optional: Admin flow
        }
    }

    // MARK: - Firebase Auth Errors
    private func handleAuthError(_ error: NSError) {

        guard let code = AuthErrorCode(rawValue: error.code) else {
            showAlert(title: "Error", message: error.localizedDescription)
            return
        }

        switch code {
        case .userNotFound:
            showAlert(title: "Error", message: "No account found with this email.")

        case .wrongPassword:
            showAlert(title: "Error", message: "Incorrect password.")

        case .invalidEmail:
            showAlert(title: "Error", message: "Invalid email address.")

        case .networkError:
            showAlert(title: "Error", message: "Network error. Please try again.")

        default:
            showAlert(title: "Error", message: error.localizedDescription)
        }
    }

    //MARK: - Signup Redirecting
    
    @IBAction func registerTapped(_ sender: UIButton) {
        let vc = storyboard?.instantiateViewController(
            withIdentifier: "SignupViewController"
        ) as! SignupViewController

        present(vc, animated: true)
    }
    
}

    // MARK: - Helpers
    private extension String {
        var trimmed: String {
            trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
