import UIKit
import FirebaseFirestore

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

    @IBOutlet weak var tableView: UITableView!
    // Keep references if you need them later
    private var headerView: HeaderView?
    private var bottomNav: BottomNavView?
    
    private var listener: ListenerRegistration?
    // Make sure we only add them once
    private var didSetupViews = false
    private var items: [DonationItem] = []

    private var donationListener: ListenerRegistration?

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "dd MMM yyyy"
        return df
    }()

    private let db = Firestore.firestore()


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

        // Keep your current registration (but see note below if it crashes)

        listenForPendingDonations()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]

        let sb = UIStoryboard(name: "HajarStoryboard", bundle: nil)
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

        listener = db.collection("Donations")
            .whereField("status", isEqualTo: "pending")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snap, error in

                if let error = error {
                    print("❌ Firestore listen error:", error.localizedDescription)
                    return
                }

                let docs = snap?.documents ?? []

                self?.items = docs.compactMap { doc in
                    let d = doc.data()

                    return DonationItem(
                        id: doc.documentID, // ✅ use Firestore doc id
                        donorId: d["donorId"] as? String ?? "",

                        category: d["category"] as? String ?? "",
                        name: d["item"] as? String ?? "",
                        quantity: "\(d["quantity"] as? Int ?? 1) \(d["unit"] as? String ?? "")",
                        location: d["donorCity"] as? String ?? "Bahrain",
                        expiryDate: d["expiryDate"] as? String ?? "",
                        donorName: d["donorName"] as? String ?? "Donor",
                        imageURL: d["imageUrl"] as? String ?? "",

                        donationMethod: d["donationMethod"] as? String,
                        impactType: d["impactType"] as? String
                    )
                }

                DispatchQueue.main.async {
                    self?.tableView.reloadData()
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

        header.notiBtn.addTarget(self,
                                 action: #selector(openNotifications),
                                 for: .touchUpInside)

        headerContainer.addSubview(header)
        headerContainer.backgroundColor = .clear

        self.headerView = header

        print("✅ Header added to container, header frame:", header.frame)
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
               print("❌ Failed to load BottomNavView.xib")
               return
           }

           nav.frame = navContainer.bounds
           nav.autoresizingMask = [.flexibleWidth, .flexibleHeight]

           // Example role handling
           let currentRole: UserRole = .ngo

           switch currentRole {
           case .donor:
               nav.formBtn.isHidden = false
               nav.listBtn.isHidden = true
               nav.proBtn.isHidden = true
               nav.impBtn.isHidden = true
               nav.userBtn.isHidden = true
               nav.hisBtn.isHidden = true
               nav.heartBtn.isHidden = true

        case .ngo:
        
            // Hide EVERYTHING in BottomNavView
            nav.listBtn.isHidden = false
            nav.listLab.isHidden = false

            nav.ngoLab.isHidden = true

            nav.proBtn.isHidden = false
            nav.proLab.isHidden = false

            nav.impBtn.isHidden = false
            nav.ompLab.isHidden = false  // (impact label)

            nav.userBtn.isHidden = true
            nav.userLab.isHidden = true

            nav.hisBtn.isHidden = false
            nav.hisLab.isHidden = false

            nav.heartBtn.isHidden = true
            nav.donLab.isHidden = true

            nav.formBtn.isHidden = true
            
        case .admin:
            // Hide EVERYTHING in BottomNavView
            nav.listBtn.isHidden = true
            nav.listLab.isHidden = true

            nav.ngoLab.isHidden = true

            nav.proBtn.isHidden = true
            nav.proLab.isHidden = true

            nav.impBtn.isHidden = true
            nav.ompLab.isHidden = true   // (impact label)

            nav.userBtn.isHidden = true
            nav.userLab.isHidden = true

            nav.hisBtn.isHidden = true
            nav.hisLab.isHidden = true

            nav.heartBtn.isHidden = true
            nav.donLab.isHidden = true

            nav.formBtn.isHidden = true

        }

        // ====== BUTTON ACTIONS ======
        nav.listBtn.addTarget(self,
                              action: #selector(openHome),
                              for: .touchUpInside)

        nav.hisBtn.addTarget(self,
                                 action: #selector(openHistory),
                                 for: .touchUpInside)

        nav.impBtn.addTarget(self,
                                action: #selector(openImpact),
                                for: .touchUpInside)

        nav.proBtn.addTarget(self,
                                 action: #selector(openProfile),
                                 for: .touchUpInside)

        nav.userBtn.addTarget(self,
                               action: #selector(openUsers),
                               for: .touchUpInside)

           nav.backgroundColor = .clear
           navContainer.addSubview(nav)
           bottomNav = nav
       }

       // MARK: - Nav Actions
       @objc private func openHome() { print("🏠 Home tapped") }
       @objc private func openHistory() { print("📜 History tapped") }
       @objc private func openImpact() { print("📈 Impact tapped") }
       @objc private func openProfile() { print("👤 Profile tapped") }
       @objc private func openUsers() { print("👥 Users tapped") }
   }
