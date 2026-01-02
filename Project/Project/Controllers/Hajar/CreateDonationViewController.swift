import UIKit
import FirebaseAuth
import FirebaseFirestore

// ✅ Add this protocol ONCE (can be in this file or a shared file)
protocol DonationDraftReceivable: AnyObject {
    var donationDraft: DonationDraft? { get set }
}

final class CreateDonationViewController: UIViewController,
                                         UIImagePickerControllerDelegate,
                                         UINavigationControllerDelegate {

    // MARK: - Outlets
    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var btnSubmitForm: UIButton!

    @IBOutlet weak var categoryTF: UITextField?
    @IBOutlet weak var typeTF: UITextField?

    @IBOutlet weak var expiryTF: UITextField!
    @IBOutlet weak var mfgTF: UITextField!
    @IBOutlet weak var quantityTF: UITextField!
    @IBOutlet weak var itemTF: UITextField!
    @IBOutlet weak var spaceView: UIView!

    @IBOutlet weak var photoUpload: UIImageView!

    @IBOutlet weak var btnCategorey: UIButton?
    @IBOutlet weak var btnType: UIButton!

    // Donation method buttons
    @IBOutlet weak var btnDropoff: UIButton!
    @IBOutlet weak var btnLocationPickup: UIButton!

    // MARK: - State
    private var headerView: HeaderView?
    private var selectedImage: UIImage?

    private var selectedCategory: String?
    private var selectedType: String?
    private var selectedMethod: DonationMethod?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupHeader()
        setupUI()
        setupImageUploadTap()
        setupCategoryDropdown()
        setupTypeDropdown()
    }

    private func setupUI() {
        quantityTF.keyboardType = .numberPad
        scrollView.keyboardDismissMode = .interactive

        btnDropoff.layer.cornerRadius = 12
        btnLocationPickup.layer.cornerRadius = 12
    }

    // MARK: - Dropdowns
    private func setupCategoryDropdown() {
        guard let button = btnCategorey else { return }

        // ✅ No allCases needed
        let categories: [String] = [
            DonationCategory.fruits.rawValue,
            DonationCategory.vegetables.rawValue,
            DonationCategory.bakery.rawValue,
            DonationCategory.cookedMeals.rawValue,
            DonationCategory.cannedMeals.rawValue,
            DonationCategory.beverages.rawValue
        ]

        button.menu = UIMenu(
            title: "Select Category",
            children: categories.map { cat in
                UIAction(title: cat) { [weak self] _ in
                    self?.selectedCategory = cat
                    button.setTitle(cat, for: .normal)
                    button.setTitleColor(.label, for: .normal)
                }
            }
        )

        button.showsMenuAsPrimaryAction = true
        button.setTitle("Select Category", for: .normal)
        button.setTitleColor(.placeholderText, for: .normal)
    }

    private func setupTypeDropdown() {
        guard let button = btnType else { return }

        // ✅ No DonationType.allCases needed (use your real app labels)
        let types: [String] = [
            "Waste Prevented",
            "Meals Provided"
        ]

        button.menu = UIMenu(
            title: "Select Type",
            children: types.map { t in
                UIAction(title: t) { [weak self] _ in
                    self?.selectedType = t
                    button.setTitle(t, for: .normal)
                    button.setTitleColor(.label, for: .normal)
                }
            }
        )

        button.showsMenuAsPrimaryAction = true
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
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        if let image = info[.originalImage] as? UIImage {
            selectedImage = image
            photoUpload.image = image
            photoUpload.contentMode = .scaleAspectFill
            photoUpload.layer.cornerRadius = 16
            photoUpload.clipsToBounds = true
        }

        picker.dismiss(animated: true)
    }

    // MARK: - Donation Method Selection
    @IBAction func dropoffTapped(_ sender: UIButton) {
        selectedMethod = .dropoff
        buildDraftAndNavigate()
    }

    @IBAction func locationPickupTapped(_ sender: UIButton) {
        selectedMethod = .locationPickup
        buildDraftAndNavigate()
    }

    // MARK: - Draft + Navigation
    private func buildDraftAndNavigate() {
        guard let uid = Auth.auth().currentUser?.uid else {
            showAlert(message: "Please login first")
            return
        }

        let item = itemTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let qtyText = quantityTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let expiryText = expiryTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let mfgText = mfgTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !item.isEmpty else { showAlert(message: "Enter item name"); return }
        guard let quantity = Int(qtyText), quantity > 0 else { showAlert(message: "Enter valid quantity"); return }
        guard let categoryStr = selectedCategory else { showAlert(message: "Select category"); return }
        guard let typeStr = selectedType else { showAlert(message: "Select type"); return }
        guard let method = selectedMethod else { showAlert(message: "Choose donation method"); return }
        guard let image = selectedImage else { showAlert(message: "Select an image"); return }

        guard let categoryEnum = DonationCategory(rawValue: categoryStr) else {
            showAlert(message: "Invalid category")
            return
        }

        // If your DonationType enum raw values match these strings, keep this.
        // Otherwise, map string -> enum properly.
        guard let typeEnum = DonationType(rawValue: typeStr) else {
            showAlert(message: "Invalid type")
            return
        }

        let dateParser: DateFormatter = {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "dd MMM yyyy"
            return f
        }()

        let expiryDate: Date?
        if expiryText.isEmpty {
            expiryDate = nil
        } else if let d = dateParser.date(from: expiryText) {
            expiryDate = d
        } else {
            showAlert(message: "Invalid expiry date")
            return
        }

        let manufacturingDate: Date?
        if mfgText.isEmpty {
            manufacturingDate = nil
        } else if let d = dateParser.date(from: mfgText) {
            manufacturingDate = d
        } else {
            showAlert(message: "Invalid manufacturing date")
            return
        }

        setUploadingUI(true)
        CloudinaryService.shared.upload(image: image) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.setUploadingUI(false)

                switch result {
                case .success(let imageUrl):
                    let draft = DonationDraft(
                        id: UUID().uuidString,
                        donorId: uid,
                        item: item,
                        quantity: quantity,
                        unit: typeStr,
                        manufacturingDate: manufacturingDate,
                        expiryDate: expiryDate,
                        category: categoryEnum,
                        impactType: typeEnum,
                        imageUrl: imageUrl,
                        donorName: nil,
                        donorCity: nil
                    )

                    switch method {
                    case .dropoff:
                        self.pushDraft(toStoryboard: "ScheduleDropOffStoryboard",
                                      vcIdentifier: "FacilityDropOffViewController",
                                      draft: draft)
                    case .locationPickup:
                        self.pushDraft(toStoryboard: "ScheduleLocationPickup",
                                      vcIdentifier: "LocationPickupViewController",
                                      draft: draft)
                    }

                case .failure:
                    self.showAlert(message: "Image upload failed")
                }
            }
        }
    }

     private func setUploadingUI(_ uploading: Bool) {
         btnDropoff.isEnabled = !uploading
         btnLocationPickup.isEnabled = !uploading
         view.isUserInteractionEnabled = !uploading
     }

    private func pushDraft(toStoryboard name: String,
                           vcIdentifier: String,
                           draft: DonationDraft) {

        let sb = UIStoryboard(name: name, bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: vcIdentifier)

        // ✅ No hard dependency on DropoffViewController type
        if var receivable = vc as? DonationDraftReceivable {
            receivable.donationDraft = draft
        } else {
            print("❌ \(vcIdentifier) does not conform to DonationDraftReceivable")
        }

        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Alerts
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Header
    private func setupHeader() {
        guard let header = Bundle.main
            .loadNibNamed("HeaderView", owner: nil)?
            .first as? HeaderView else { return }

        header.frame = headerContainer.bounds
        header.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        header.takaffalLabel.text = "Takaffal"
        header.backBtn.isHidden = false
        header.clear.isHidden = true
        header.search.isHidden = true

        header.notiBtn.isHidden = false
        header.backBtn.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        header.notiBtn.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)

        headerContainer.addSubview(header)
        self.headerView = header
    }

    @objc private func backTapped() {
        if let nav = navigationController, nav.viewControllers.first != self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func openNotifications() {
        let sb = UIStoryboard(name: "NotificationsStoryboard", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "NotificationVC") as? NotificationViewController else {
            return
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}
