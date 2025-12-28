import UIKit
import FirebaseAuth
import FirebaseFirestore

final class CreateDonationViewController: UIViewController,
                                         UIImagePickerControllerDelegate,
                                         UINavigationControllerDelegate {

    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var btnSubmitForm: UIButton!

    // These can stay if you still have textfields in UI, but we WON’T depend on them anymore
    @IBOutlet weak var categoryTF: UITextField?
    @IBOutlet weak var typeTF: UITextField?

    @IBOutlet weak var expiryTF: UITextField!
    @IBOutlet weak var mfgTF: UITextField!
    @IBOutlet weak var quantityTF: UITextField!
    @IBOutlet weak var itemTF: UITextField!
    @IBOutlet weak var spaceView: UIView!

    @IBOutlet weak var photoUpload: UIImageView!

    // Dropdown buttons (menu buttons)
    @IBOutlet weak var btnCategorey: UIButton?
    @IBOutlet weak var btnType: UIButton?

    private var headerView: HeaderView?
    private var selectedImage: UIImage?

    // ✅ Use these instead of textfields
    private var selectedCategory: String?
    private var selectedType: String?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        print("STORYBOARD =", storyboard?.value(forKey: "name") ?? "unknown")
        print("Button exists:", btnCategorey != nil)

        setupHeader()

        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive

        // Dismiss keyboard on tap
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        quantityTF.keyboardType = .numberPad

        // Setup dropdown menus
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.setupCategoryDropdown()
            self?.setupTypeDropdown()
        }

        setupImageUploadTap()
        registerForKeyboardNotifications()

        btnSubmitForm.setTitle("Submit", for: .normal)
    }

    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }

    // MARK: - Dropdowns
    private func setupCategoryDropdown() {
        guard let button = btnCategorey else {
            print("❌ btnCategorey outlet NOT connected")
            return
        }

        let categories = [
            DonationCategory.fruits.rawValue,
            DonationCategory.vegetables.rawValue,
            DonationCategory.bakery.rawValue,
            DonationCategory.cookedMeals.rawValue,
            DonationCategory.cannedMeals.rawValue,
            DonationCategory.beverages.rawValue
        ]

        let actions = categories.map { cat in
            UIAction(title: cat) { [weak self] _ in
                self?.selectedCategory = cat

                // Optional: keep TF updated if it exists
                self?.categoryTF?.text = cat

                self?.btnCategorey?.setTitle(cat, for: .normal)
                self?.btnCategorey?.setTitleColor(.label, for: .normal)
            }
        }

        button.menu = UIMenu(title: "Select Category", children: actions)
        button.showsMenuAsPrimaryAction = true
        button.changesSelectionAsPrimaryAction = true
        button.setTitle("Select Category", for: .normal)
        button.setTitleColor(.placeholderText, for: .normal)
    }

    private func setupTypeDropdown() {
        guard let button = btnType else {
            print("❌ btnType outlet NOT connected")
            return
        }

        let types = ["Waste Prevented", "Meals Provided"]

        let actions = types.map { t in
            UIAction(title: t) { [weak self] _ in
                self?.selectedType = t

                // Optional: keep TF updated if it exists
                self?.typeTF?.text = t

                self?.btnType?.setTitle(t, for: .normal)
                self?.btnType?.setTitleColor(.label, for: .normal)
            }
        }

        button.menu = UIMenu(title: "Select Type", children: actions)
        button.showsMenuAsPrimaryAction = true
        button.changesSelectionAsPrimaryAction = true
        button.setTitle("Select Type", for: .normal)
        button.setTitleColor(.placeholderText, for: .normal)
    }

    // MARK: - Image Upload
    private func setupImageUploadTap() {
        photoUpload.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(uploadTapped))
        photoUpload.addGestureRecognizer(tap)
    }

    @objc private func uploadTapped() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        if let image = info[.originalImage] as? UIImage {
            selectedImage = image
            photoUpload.image = image
            photoUpload.contentMode = .scaleAspectFill
            photoUpload.clipsToBounds = true
            photoUpload.layer.cornerRadius = 16
        }

        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    // MARK: - Keyboard Handling
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let info = notification.userInfo,
              let frame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let bottomInset = frame.height - view.safeAreaInsets.bottom
        scrollView.contentInset.bottom = bottomInset + 16
        scrollView.verticalScrollIndicatorInsets.bottom = bottomInset + 16
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }

    // MARK: - Alerts
    private func showAlert(title: String = "Error", message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
        present(alert, animated: true)
    }

    // MARK: - Actions
    @IBAction func cancelTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func submitTapped(_ sender: UIButton) {

        let itemName = itemTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let quantityText = quantityTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let expiryDate = expiryTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !itemName.isEmpty else { showAlert(message: "Please enter item name"); return }
        guard let category = selectedCategory, !category.isEmpty else {
            showAlert(message: "Please select a category"); return
        }
        guard let type = selectedType, !type.isEmpty else {
            showAlert(message: "Please select a type"); return
        }
        guard let quantityInt = Int(quantityText), quantityInt > 0 else {
            showAlert(message: "Please enter a valid quantity"); return
        }
        guard !expiryDate.isEmpty else { showAlert(message: "Please enter expiry date"); return }
        guard let image = selectedImage else { showAlert(message: "Please select an image"); return }

        // Loading
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        sender.isEnabled = false

        CloudinaryService.shared.upload(image: image) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                activityIndicator.removeFromSuperview()
                sender.isEnabled = true

                switch result {
                case .success(let urlString):

                    guard let uid = Auth.auth().currentUser?.uid else {
                        self.showAlert(message: "You are not logged in.")
                        return
                    }

                    let db = Firestore.firestore()
                    let donationId = UUID().uuidString

                    let data: [String: Any] = [
                        "id": donationId,
                        "donorId": uid,
                        "collectorId": NSNull(),

                        "item": itemName,
                        "quantity": quantityInt,
                        "unit": type,
                        "impactType": type,

                        "expiryDate": expiryDate, // String ok, DonationService handles legacy
                        "category": category,
                        "imageUrl": urlString,
                        "donationMethod": "locationPickup",
                        "status": "pending",

                        "pickupRequestId": NSNull(),
                        "donorName": "Current User",
                        "donorCity": "Bahrain",
                        "createdAt": Timestamp(date: Date())
                    ]

                    db.collection("Donations").document(donationId).setData(data) { error in
                        DispatchQueue.main.async {
                            if let error = error {
                                self.showAlert(message: "Failed to save donation: \(error.localizedDescription)")
                                return
                            }

                            self.showAlert(title: "Success", message: "Donation submitted successfully!") {
                                if self.presentingViewController != nil {
                                    self.dismiss(animated: true)
                                } else {
                                    self.navigationController?.popViewController(animated: true)
                                }
                            }
                        }
                    }

                case .failure(let error):
                    print("Image upload failed: \(error.localizedDescription)")
                    self.showAlert(title: "Upload failed", message: "Could not upload image. Try again.")
                }
            }
        }
    }

    // MARK: - Header
    @objc private func openNotifications() {
        print("🔔 Notifications tapped")
    }

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
        header.backBtn.isHidden = false
        header.search.isHidden = true

        header.notiBtn.addTarget(self,
                                 action: #selector(openNotifications),
                                 for: .touchUpInside)

        headerContainer.addSubview(header)
        headerContainer.backgroundColor = .clear
        self.headerView = header
    }
}
