//
//  ForgotPasswordViewController.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 14/12/2025.
//

import UIKit
import FirebaseAuth

class ForgotPasswordViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    
    // MARK: - IBOutlets
    
    @IBOutlet weak var resetPasswordButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    
    // MARK: - Actions
    
    @IBAction func resetPasswordTapped(_ sender: UIButton) {
        sendPasswordReset()
    }
    
    // MARK: - Reset Logic
    private func sendPasswordReset() {

        let email = emailTextField.text?.trimmed ?? ""

        if email.isEmpty {
            showAlert(title: "Error", message: "Please enter your email address.")
            return
        }

        if !isValidEmail(email) {
            showAlert(title: "Error", message: "Please enter a valid email address.")
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            guard let self = self else { return }

            if let error = error as NSError? {
                self.handleAuthError(error)
                return
            }

            self.showSuccessAlert()
        }
    }

    // MARK: - Alerts
    private func showSuccessAlert() {

        let alert = UIAlertController(
            title: "Email Sent",
            message: "A password reset link has been sent to your email",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
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

    // MARK: - Firebase Error Handling
    private func handleAuthError(_ error: NSError) {

        guard let code = AuthErrorCode(rawValue: error.code) else {
            showAlert(title: "Error", message: error.localizedDescription)
            return
        }

        switch code {
        case .invalidEmail:
            showAlert(title: "Error", message: "Invalid email address")

        case .userNotFound:
            showAlert(title: "Error", message: "No account found with this email")

        case .networkError:
            showAlert(title: "Error", message: "Network error. Please try again")

        default:
            showAlert(title: "Error", message: error.localizedDescription)
        }
    }

    // MARK: - Email Validation
    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
}
    // MARK: - Helpers
    private extension String {
        var trimmed: String {
            trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
