//
//  FacilityDropOffViewController.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 25/12/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class FacilityDropOffViewController: UIViewController, DonationDraftReceivable {
    
    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var navContainer: UIView!
    @IBOutlet weak var facilityButton: UIButton!
    
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var timeButton: UIButton!

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

    
    var selectedNGO: NGOOption?
    
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "hh:mm a"
        return f
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        
        fixChevronLayout(for: facilityButton)
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
    
    struct NGOOption {
        let id: String
        let name: String
    }

    func fetchNGOs(completion: @escaping ([NGOOption]) -> Void) {
        let db = Firestore.firestore()

        db.collection("Users")
            .whereField("role", isEqualTo: "ngo")
            .getDocuments { snapshot, error in

                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }

                let ngos = documents.compactMap { doc -> NGOOption? in
                    let data = doc.data()

                    let verified = data["verified"] as? Bool ?? false
                    guard verified else { return nil }

                    guard let name = data["organizationName"] as? String else {
                        return nil
                    }

                    return NGOOption(id: doc.documentID, name: name)
                }

                print("NGOs found:", ngos.count)
                completion(ngos)
            }
    }


    @IBAction func facilityTapped(_ sender: UIButton) {
        fetchNGOs { ngos in
            DispatchQueue.main.async {
                self.showNGOPicker(ngos)
            }
        }
    }

    func showNGOPicker(_ ngos: [NGOOption]) {

        guard !ngos.isEmpty else {
            showAlert(
                title: "No Organizations",
                message: "No NGOs are available for drop-off right now."
            )
            return
        }

        let alert = UIAlertController(
            title: "Select Organization",
            message: "Choose an NGO for drop-off",
            preferredStyle: .actionSheet
        )

        for ngo in ngos {
            alert.addAction(UIAlertAction(
                title: ngo.name,
                style: .default
            ) { _ in
                self.selectedNGO = ngo
                self.facilityButton.setTitle(ngo.name, for: .normal)
                self.facilityButton.setTitleColor(.black, for: .normal)
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
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
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byTruncatingTail
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
    
    // MARK: - Date and Time Pickers
    
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
        selectedDate = datePicker.date
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        setValue(formatter.string(from: datePicker.date), for: dateButton)
        hiddenDateTextField.becomeFirstResponder()
    }

    @objc private func dateChanged(_ picker: UIDatePicker) {
        selectedDate = picker.date

        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"

        setValue(formatter.string(from: picker.date), for: dateButton)
    }

    @objc private func doneDateTapped() {
        hiddenDateTextField.resignFirstResponder()
    }
    
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
        selectedTime = timePicker.date
        setValue(timeFormatter.string(from: timePicker.date), for: timeButton)
        hiddenTimeTextField.becomeFirstResponder()
    }

    @objc private func timeChanged(_ picker: UIDatePicker) {
        selectedTime = picker.date

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "hh:mm a"

        setValue(formatter.string(from: picker.date), for: timeButton)
    }

    @objc private func doneTimeTapped() {
        hiddenTimeTextField.resignFirstResponder()
    }
    
    private func merge(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        var merged = DateComponents()
        merged.year = dateComponents.year
        merged.month = dateComponents.month
        merged.day = dateComponents.day
        merged.hour = timeComponents.hour
        merged.minute = timeComponents.minute

        return calendar.date(from: merged)!
    }
    
    @IBAction func saveTapped(_ sender: UIButton) {
        
        print("SAVE CHECK:")
        print("NGO:", selectedNGO?.name ?? "nil")
        print("Date:", selectedDate ?? "nil")
        print("Time:", selectedTime ?? "nil")

        guard
            let draft = donationDraft,
            let ngo = selectedNGO,
            let date = selectedDate,
            let time = selectedTime
        else {
            showAlert(
                title: "Missing Info",
                message: "Please complete all required fields."
            )
            return
        }

        let dropoffDateTime = merge(date: date, time: time)

        saveDropoffAndDonation(
            draft: draft,
            facilityName: ngo.name,
            dropoffDateTime: dropoffDateTime
        )
    }
    
    private func saveDropoffAndDonation(
        draft: DonationDraft,
        facilityName: String,
        dropoffDateTime: Date
    ) {

        let db = Firestore.firestore()
        let pickupRef = db.collection("PickupRequests").document()

        let pickupRequest = PickupRequest(
            id: pickupRef.documentID,
            donationId: draft.id,
            method: DonationMethod.dropoff.rawValue,

            facilityName: facilityName,
            dropoffDate: dropoffDateTime,
            dropoffTime: timeFormatter.string(from: dropoffDateTime),

            pickupAddress: nil,
            pickupCity: nil,
            pickupCountry: nil,
            pickupDateTime: nil,

            scheduledAt: Date()
        )

        pickupRef.setData(pickupRequest.toDict()) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.showAlert(
                    title: "Error",
                    message: "Failed to save pickup request: \(error.localizedDescription)"
                )
                return
            }

            do {
                try self.saveDonation(
                    draft: draft,
                    pickupRequestId: pickupRequest.id,
                    method: .dropoff
                )

                self.showSuccessAndRedirect()

            } catch {
                self.showAlert(
                    title: "Error",
                    message: "Failed to save donation: \(error.localizedDescription)"
                )
            }
        }
    }

    
    private func saveDonation(
        draft: DonationDraft,
        pickupRequestId: String,
        method: DonationMethod
    ) throws {

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
            donationMethod: method,
            status: .pending,

            pickupRequestId: pickupRequestId,

            donorName: draft.donorName,
            donorCity: draft.donorCity,

            createdAt: Date()
        )

        try Firestore.firestore()
            .collection("Donations")
            .document(donation.id)
            .setData(from: donation)
    }
    
    private func showSuccessAndRedirect() {

        let alert = UIAlertController(
            title: "Success ",
            message: "Your donation has been created successfully.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            let sb = UIStoryboard(name: "History&statusNoora", bundle: nil)
            let historyVC = sb.instantiateViewController(
                withIdentifier: "History&statusNoora"
            )

            self.navigationController?.setViewControllers(
                [historyVC],
                animated: true
            )
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

        let sb = UIStoryboard(name: "MariamStoryboard2", bundle: nil)
        let vc = sb.instantiateViewController(
            withIdentifier: "CreateDonationViewController"
        )

        push(vc)
    }
}

extension PickupRequest {
    func toDict() -> [String: Any] {
        return [
            "id": id,
            "donationId": donationId,
            "method": method,
            "facilityName": facilityName as Any,
            "dropoffDate": dropoffDate as Any,
            "dropoffTime": dropoffTime as Any,
            "pickupAddress": pickupAddress as Any,
            "pickupCity": pickupCity as Any,
            "pickupCountry": pickupCountry as Any,
            "pickupDateTime": pickupDateTime as Any,
            "scheduledAt": scheduledAt
        ]
    }
}

