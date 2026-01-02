//
//  LocationPickupViewController.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 25/12/2025.
//

import UIKit
import Firebase
import FirebaseAuth

class LocationPickupViewController: UIViewController, DonationDraftReceivable {
    
    // MARK: - Outlets
    
    @IBOutlet weak var navContainer: UIView!
    @IBOutlet weak var headerContainer: UIView!
    
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var timeButton: UIButton!

    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!

    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var hiddenDateTextField: UITextField!

    @IBOutlet weak var hiddenTimeTextField: UITextField!
    
    private var currentUserRole: UserRole?
    var donationDraft: DonationDraft?
    
    private var headerView: HeaderView?
    private var bottomNav: BottomNavView?
    private var didSetupViews = false
    
    private let datePicker = UIDatePicker()
    private let timePicker = UIDatePicker()

    private var selectedDate: Date?
    private var selectedTime: Date?
    
    private lazy var receiptDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.hidesBackButton = true
        
        fetchUserLocation()
        fixChevronLayout(for: dateButton)
        fixChevronLayout(for: timeButton)
        setupDatePicker()
        setupTimePicker()

    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !didSetupViews {
            didSetupViews = true
            setupHeader()
            setupNav()
        }
    }
    
    
    // MARK: - Fetch user location
    
    private func fetchUserLocation() {

           guard let uid = Auth.auth().currentUser?.uid else { return }

           Firestore.firestore()
               .collection("Users")
               .document(uid)
               .getDocument { snapshot, _ in

                   guard let data = snapshot?.data() else { return }

                   self.addressLabel.text = data["address"] as? String ?? "-"
                   self.cityLabel.text = data["city"] as? String ?? "-"
                   self.countryLabel.text = data["country"] as? String ?? "-"
               }
       }

    
    private func makeToolbar(doneSelector: Selector) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let flex = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )

        let done = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: doneSelector
        )

        toolbar.items = [flex, done]
        return toolbar
    }
    
    private func setValue(_ text: String, for button: UIButton) {
        var config = button.configuration ?? UIButton.Configuration.plain()
        config.title = text
        config.baseForegroundColor = .black
        button.configuration = config
    }
    
    private func fixChevronLayout(for button: UIButton) {
        var config = button.configuration ?? UIButton.Configuration.plain()

        config.imagePlacement = .trailing
        config.imagePadding = 8

        config.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: 16,
            bottom: 0,
            trailing: 16
        )

        button.configuration = config

        button.contentHorizontalAlignment = .fill
        button.titleLabel?.lineBreakMode = .byTruncatingTail
    }

    

    // MARK: - Date Picker
    
    private func setupDatePicker() {
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.minimumDate = Date()

        datePicker.addTarget(
            self,
            action: #selector(dateChanged(_:)),
            for: .valueChanged
        )

        hiddenDateTextField.inputView = datePicker
        hiddenDateTextField.inputAccessoryView = makeToolbar(
            doneSelector: #selector(doneDateTapped)
        )
    }
    
     @IBAction func dateTapped(_ sender: UIButton) {
         hiddenDateTextField.becomeFirstResponder()
     }
    
    @objc private func dateChanged(_ picker: UIDatePicker) {
        selectedDate = picker.date

        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"

        setValue(formatter.string(from: picker.date), for: dateButton)
//        updateSaveButtonState()
    }

    @objc private func doneDateTapped() {
        hiddenDateTextField.resignFirstResponder()
    }
    
    
    // MARK: - Time Picker
    
    private func setupTimePicker() {
        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .wheels
        timePicker.minuteInterval = 15

        timePicker.addTarget(
            self,
            action: #selector(timeChanged(_:)),
            for: .valueChanged
        )

        hiddenTimeTextField.inputView = timePicker
        hiddenTimeTextField.inputAccessoryView = makeToolbar(
            doneSelector: #selector(doneTimeTapped)
        )
    }
    
    @IBAction func timeTapped(_ sender: UIButton) {
        print("TIME TAPPED")
        hiddenTimeTextField.becomeFirstResponder()
    }
    
    @objc private func timeChanged(_ picker: UIDatePicker) {
        selectedTime = picker.date

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "hh:mm a"

        setValue(formatter.string(from: picker.date), for: timeButton)
//        updateSaveButtonState()
    }
    
    @objc private func doneTimeTapped() {
        hiddenTimeTextField.resignFirstResponder()
    }
    
    
    // MARK: - Save Flow
    
    @IBAction func saveTapped(_ sender: UIButton) {
        guard
            let draft = donationDraft,
            let date = selectedDate,
            let time = selectedTime
        else {
            showAlert("Missing Info", "Please complete all required fields.")
            return
        }

        let pickupDateTime = merge(date: date, time: time)

        savePickupAndDonation(
            draft: draft,
            pickupDateTime: pickupDateTime
        )
    }
    
    private func savePickupAndDonation(
        draft: DonationDraft,
        pickupDateTime: Date
    ) {

        let db = Firestore.firestore()
        let pickupRef = db.collection("PickupRequests").document()

        let pickupRequest = PickupRequest(
            id: pickupRef.documentID,
            donationId: draft.id,
            method: DonationMethod.locationPickup.rawValue,

            facilityName: nil,
            dropoffDate: nil,
            dropoffTime: nil,

            pickupAddress: addressLabel.text,
            pickupCity: cityLabel.text,
            pickupCountry: countryLabel.text,
            pickupDateTime: pickupDateTime,

            scheduledAt: Date()
        )

        pickupRef.setData(pickupRequest.toDict()) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.showAlert(
                    "Error",
                    "Failed to save pickup request: \(error.localizedDescription)"
                )
                return
            }

            self.saveDonation(
                draft: draft,
                pickupRequestId: pickupRequest.id
            ) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.showSuccessAndRedirect()
                    case .failure(let error):
                        self.showAlert(
                            "Error",
                            "Failed to save donation: \(error.localizedDescription)"
                        )
                    }
                }
            }
        }
    }

    
    private func saveDonation(
        draft: DonationDraft,
        pickupRequestId: String
        , completion: @escaping (Result<Void, Error>) -> Void
    ) {

        let donation = Donation(
            id: draft.id,
            donorId: draft.donorId,
            collectorId: nil,

            item: draft.item,
            quantity: draft.quantity,
            unit: draft.unit,

            manufacturingDate: draft.manufacturingDate,
            expiryDate: draft.expiryDate,

            category: draft.category,
            impactType: draft.impactType,

            imageUrl: draft.imageUrl,
            donationMethod: .locationPickup,
            status: .pending,

            pickupRequestId: pickupRequestId,

            donorName: draft.donorName,
            donorCity: draft.donorCity,

            createdAt: Date()
        )

        DonationService.shared.createDonation(donation, completion: completion)
    }


        private func merge(date: Date, time: Date) -> Date {
            let calendar = Calendar.current
            let dateComp = calendar.dateComponents([.year, .month, .day], from: date)
            let timeComp = calendar.dateComponents([.hour, .minute], from: time)

            var final = DateComponents()
            final.year = dateComp.year
            final.month = dateComp.month
            final.day = dateComp.day
            final.hour = timeComp.hour
            final.minute = timeComp.minute

            return calendar.date(from: final) ?? date
        }

        private func showAlert(_ title: String, _ message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }


    
    private func showSuccessAndRedirect() {

            let itemName = donationDraft?.item ?? "—"
            let category = donationDraft?.category.rawValue ?? "—"
            let quantity = donationDraft?.quantity.description ?? "—"

            let pickupMethod = "Pickup"

            let pickupDate: String = {
                guard let date = selectedDate, let time = selectedTime else { return "—" }
                let merged = merge(date: date, time: time)
                return receiptDateFormatter.string(from: merged)
            }()

            let location: String = {
                let city = cityLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let address = addressLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if city.isEmpty { return address.isEmpty ? "—" : address }
                if address.isEmpty { return city }
                return "\(city) / \(address)"
            }()

            let body = """
    🧾 Receipt 1: Donation Created (DONOR)
    Title: Donation Creation Receipt
    Thank you for your generosity.
    This receipt confirms that your donation has been successfully created in our system.
    Donation Details:
    • Item Name: \(itemName)
    • Category: \(category)
    • Quantity: \(quantity)
    • Pickup Method: \(pickupMethod)
    • Pickup Date: \(pickupDate)
    • Location: \(location)
    Your donation is now visible to eligible NGOs.
    We sincerely appreciate your contribution in supporting those in need.
    """

            let qrPayload = ReceiptPopupViewController.makeGithubPagesReceiptUrl(from: body)

            let popup = ReceiptPopupViewController(
                receiptTitle: "Donation Creation Receipt",
                receiptBody: body,
                qrPayload: qrPayload
            )
            popup.onDismiss = { [weak self] in
                guard let self = self else { return }
                let sb = UIStoryboard(name: "History&statusNoora", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "History&statusNoora")
                self.navigationController?.setViewControllers([vc], animated: true)
            }
            present(popup, animated: true)
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

        header.clear.isHidden = true
        header.takaffalLabel.text = "Takaffal"
        header.search.isHidden = true
        header.backBtn.isHidden = false

        header.backBtn.addTarget(
            self,
            action: #selector(didTapBack),
            for: .touchUpInside
        )

        header.notiBtn.addTarget(
            self,
            action: #selector(openNotifications),
            for: .touchUpInside
        )

        headerContainer.addSubview(header)
        headerContainer.backgroundColor = .clear
        self.headerView = header
    }

    
    @objc private func didTapBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func openNotifications() {
        print("Notifications tapped")
        
        let sb = UIStoryboard(name: "NotificationsStoryboard", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "NotificationVC") as? NotificationViewController else {
            print("Could not instantiate NotificationViewController")
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
            nav.formBtn.isHidden = false
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
        let vc = sb.instantiateViewController(withIdentifier: "ImpactNoora")
        push(vc)
    }
    
    @objc private func openProfile() {
        let sb = UIStoryboard(name: "MariamStoryboard2", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "ProfileViewController")
        push(vc)
    }
    
    @objc private func openUsers() {
        let sb = UIStoryboard(name: "AbdullaStoryboard2", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "AbdullaViewController2")
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
