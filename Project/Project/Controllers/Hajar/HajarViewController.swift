import UIKit
import FirebaseFirestore
import FirebaseAuth

//struct DonationItem {
//    let category: String
//    let name: String
//    let quantity: String
//    let location: String
//    let expiryDate: String
//    let donorName: String
//    let imageURL: String   // ✅ add this
//}


class HajarViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Outlets (from storyboard)
    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var navContainer: UIView!

    @IBOutlet weak var filter2: UISegmentedControl!
    @IBOutlet weak var filter1: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    // Keep references if you need them later
    private var headerView: HeaderView?
    private var bottomNav: BottomNavView?
    
    private var listener: ListenerRegistration?
    // Make sure we only add them once
    private var didSetupViews = false
    private var items: [DonationItem] = []
    private var allItems: [DonationItem] = []
    private var currentSearchText: String = ""

    private var selectedCategoryFilter: String? = nil

    private var donationListener: ListenerRegistration?

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "dd MMM yyyy"
        return df
    }()

    private let db = Firestore.firestore()
    private var currentUserRole: UserRole?


    // MARK: - Lifecycle
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // This is called multiple times so protect it
        if !didSetupViews {
            didSetupViews = true
            setupHeader()
            setupNav()
        }
    }

    // TEMP: fake data just to make the table show something
//    var items: [DonationItem] = [
//        DonationItem(
//            category: "Meals",
//            name: "Grape leaves",
//            quantity: "24 pieces",
//            location: "Hamad Town",
//            expiryDate: "11 Nov 2025",
//            donorName: "Hajar",
//            imageURL: "https://res.cloudinary.com/dquu356xs/image/upload/w_300,h_250,c_fill,q_auto,f_auto/grape_leaves"
//        ),
//        DonationItem(
//            category: "Beverages",
//            name: "Juices",
//            quantity: "9 bottles",
//            location: "Riffa",
//            expiryDate: "11 Nov 2025",
//            donorName: "Safa",
//            imageURL: "https://res.cloudinary.com/dquu356xs/image/upload/v1766447000/juice.png"
//        ),
//        DonationItem(
//            category: "Bakery",
//            name: "Bakery box",
//            quantity: "12 items",
//            location: "Isa Town",
//            expiryDate: "11 Nov 2025",
//            donorName: "Noor",
//            imageURL: "https://res.cloudinary.com/dquu356xs/image/upload/v1766447000/donuts_box.png"
//        )
//    ]



    // In HajarViewController.swift

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = .clear
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tableView.allowsSelection = true

        filter1.addTarget(self, action: #selector(filter1Changed(_:)), for: .valueChanged)
        filter2.addTarget(self, action: #selector(filter2Changed(_:)), for: .valueChanged)

        // Keep your current registration (but see note below if it crashes)

        listenForPendingDonations()
    }

    @objc private func filter1Changed(_ sender: UISegmentedControl) {
        filter2.selectedSegmentIndex = UISegmentedControl.noSegment

        if sender.selectedSegmentIndex == 0 {
            selectedCategoryFilter = nil
        } else {
            selectedCategoryFilter = sender.titleForSegment(at: sender.selectedSegmentIndex)
        }

        applyFiltersAndReload()
    }

    @objc private func filter2Changed(_ sender: UISegmentedControl) {
        filter1.selectedSegmentIndex = 0

        selectedCategoryFilter = sender.titleForSegment(at: sender.selectedSegmentIndex)
        applyFiltersAndReload()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]

        let sb = UIStoryboard(name: "DetailsStoryboard", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "DonationDetailVC")
                as? DonationDetailViewController else {
            print("❌ Storyboard ID not set for DonationDetailViewController")
            return
        }

        // ✅ pass what detail needs
        vc.donationId = item.id
        vc.donorId = item.donorId

        // ✅ optional: show instantly without waiting firestore
        vc.passedItem = item

        navigationController?.pushViewController(vc, animated: true)
    }

    private func listenForPendingDonations() {
        listener?.remove()

        guard let ngoId = Auth.auth().currentUser?.uid else {
            print("❌ No logged in user")
            return
        }

        listener = db.collection("Donations")
            .whereField("status", isEqualTo: "pending")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snap, error in

                if let error = error {
                    print("❌ Firestore listen error:", error.localizedDescription)
                    return
                }

                let docs = snap?.documents ?? []

                let visibleDocs = docs.filter { doc in
                    let data = doc.data()
                    let rejectedBy = data["rejectedBy"] as? [String] ?? []
                    return !rejectedBy.contains(ngoId)
                }

                let latestItems: [DonationItem] = visibleDocs.compactMap { doc in
                    let d = doc.data()

                    let expiryDateString: String = {
                        if let ts = d["expiryDate"] as? Timestamp {
                            return self?.dateFormatter.string(from: ts.dateValue()) ?? ""
                        }
                        if let s = d["expiryDate"] as? String {
                            return s
                        }
                        return ""
                    }()

                    return DonationItem(
                        id: doc.documentID, // ✅ use Firestore doc id
                        donorId: d["donorId"] as? String ?? "",

                        category: d["category"] as? String ?? "",
                        name: d["item"] as? String ?? "",
                        quantity: "\(d["quantity"] as? Int ?? 1) \(d["unit"] as? String ?? "")",
                        location: d["donorCity"] as? String ?? "Bahrain",
                        expiryDate: expiryDateString,
                        donorName: d["donorName"] as? String ?? "Donor",
                        imageURL: d["imageUrl"] as? String ?? "",

                        donationMethod: d["donationMethod"] as? String,
                        impactType: d["impactType"] as? String
                    )
                }

                DispatchQueue.main.async {
                    guard let self else { return }
                    self.allItems = latestItems
                    self.applyFiltersAndReload()
                }
            }
        
    }

    deinit { listener?.remove() }

    private func startListeningForPendingDonations() {
        donationListener = DonationService.shared.listenPendingDonations { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let donations):
                    self?.items = donations.map { d in
                        DonationItem(
                            id: d.id,                                  // ✅ add
                            donorId: d.donorId,                        // ✅ add

                            category: d.category.rawValue,
                            name: d.item,
                            quantity: "\(d.quantity) \(d.unit)",
                            location: d.donorCity ?? "Bahrain",
                            expiryDate: d.expiryDate.map { self?.dateFormatter.string(from: $0) ?? "" } ?? "",
                            donorName: d.donorName ?? "Donor",
                            imageURL: d.imageUrl,

                            donationMethod: d.donationMethod.rawValue,
                            impactType: d.impactType.rawValue
                        )
                    }

                    self?.tableView.reloadData()

                case .failure(let e):
                    print("❌ listenPendingDonations error:", e.localizedDescription)
                }
            }
        }
    }


    @objc private func handleDonationAdded(_ notification: Notification) {
        // Ensure we're on the main thread when updating the UI
        DispatchQueue.main.async { [weak self] in
            // Get the latest items from the shared store
            self?.items = DonationFeedStore.shared.items
            // Reload the table view with a nice animation
            UIView.transition(with: self?.tableView ?? UIView(),
                             duration: 0.35,
                             options: .transitionCrossDissolve,
                             animations: { self?.tableView.reloadData() })
        }
    }

//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        items = DonationFeedStore.shared.items
//        tableView.reloadData()
//    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listenForPendingDonations()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
        listener = nil
    }


    
    // MARK: - TableView Data Source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
//
//    func tableView(_ tableView: UITableView,
//                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//
//        guard let cell = tableView.dequeueReusableCell(
//            withIdentifier: "DonationCell",
//            for: indexPath
//        ) as? DonationCell else {
//            return UITableViewCell()
//        }
//
//        let item = items[indexPath.row]
//
//        cell.categoryLabel.text = item.category
//        cell.itemNameLabel.text = item.name
//        cell.quantityLabel.text = item.quantity
//        cell.locationLabel.text = item.location
//        cell.expiryDateLabel.text = item.expiryDate
//        cell.donorNameLabel.text = item.donorName
//
//        cell.selectionStyle = .none
//        return cell
//    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DonationCell", for: indexPath) as? DonationCellHajar else {
            return UITableViewCell()
        }

        let item = items[indexPath.row]
        cell.configure(with: item)

        return cell
    }


    // MARK: - Header

    private func setupHeader() {
        guard let header = Bundle.main
            .loadNibNamed("HeaderView", owner: nil, options: nil)?
            .first as? HeaderView else {
            print("❌ Failed to load HeaderView.xib")
            return
        }

        header.frame = headerContainer.bounds
        header.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Customize header
        header.takaffalLabel.text = "Takaffal"
        header.backBtn.isHidden = true
        header.clear.isHidden = true
        header.search.isHidden = false
        header.notiBtn.addTarget(self,
                                 action: #selector(openNotifications),
                                 for: .touchUpInside)

        header.onSearchTextChanged = { [weak self] text in
            self?.applySearch(text: text)
        }

        headerContainer.addSubview(header)
        headerContainer.backgroundColor = .clear

        self.headerView = header

        print("✅ Header added to container, header frame:", header.frame)
    }

    private func applySearch(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        currentSearchText = trimmed

        applyFiltersAndReload()
    }

    private func applyFiltersAndReload() {
        var base = allItems

        if let category = selectedCategoryFilter?.trimmingCharacters(in: .whitespacesAndNewlines),
           !category.isEmpty {
            let c = category.lowercased()
            base = base.filter { $0.category.lowercased() == c }
        }

        let q = currentSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            base = base.filter { item in
                item.name.lowercased().contains(q) ||
                item.category.lowercased().contains(q) ||
                item.location.lowercased().contains(q) ||
                item.donorName.lowercased().contains(q)
            }
        }

        items = base
        tableView.reloadData()
    }

    @objc private func openNotifications() {
        print("🔔 Notifications tapped")

        let sb = UIStoryboard(name: "NotificationsStoryboard", bundle: nil)

        guard let vc = sb.instantiateViewController(withIdentifier: "NotificationVC") as? NotificationViewController else {
            print("❌ Could not instantiate NotificationViewController")
            return
        }

        navigationController?.pushViewController(vc, animated: true)
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
