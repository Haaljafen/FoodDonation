import UIKit
import FirebaseFirestore
import FirebaseAuth

class AbdullaViewController1: UIViewController {

    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var navContainer: UIView!
    @IBOutlet weak var filterAllButton: UIButton!
    @IBOutlet weak var filterAZButton: UIButton!
    @IBOutlet weak var filterZAButton: UIButton!
    @IBOutlet weak var tableView: UITableView!

    private var headerView: HeaderView?
    private var bottomNav: BottomNavView?
    private var currentUserRole: UserRole?
    private var didSetupViews = false
    
    private var selectedFilter = 0
    
    // ✅ CHANGED: User objects instead of String
    private var ngos: [User] = []
    private var allNGOs: [User] = []
    private var currentSearchText: String = ""
    
    private let db = Firestore.firestore()  // ✅ ADD THIS

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupFilterButtons()
        fetchNGOs()  // ✅ ADD THIS
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !didSetupViews {
            didSetupViews = true
            setupHeader()
            setupNav()
        }
    }
    
    // ✅ ADD THIS ENTIRE FUNCTION
    private func fetchNGOs() {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔵 STEP 1: Starting Firebase fetch...")
        print("   Collection: Users")
        print("   Filter: role = 'ngo'")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        db.collection("Users")
            .whereField("role", isEqualTo: "ngo")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    print("❌ CRITICAL: self is nil")
                    return
                }
                
                print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                print("🔵 STEP 2: Got response from Firebase")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                
                // Check for errors
                if let error = error {
                    print("❌ ERROR DETECTED!")
                    print("   Error Type:", type(of: error))
                    print("   Error Message:", error.localizedDescription)
                    print("   Error Domain:", (error as NSError).domain)
                    print("   Error Code:", (error as NSError).code)
                    return
                }
                print("✅ No errors detected")
                
                // Check snapshot
                guard let snapshot = snapshot else {
                    print("❌ CRITICAL: Snapshot is nil")
                    return
                }
                print("✅ Snapshot exists")
                
                // Check documents
                let documents = snapshot.documents
                print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                print("🔵 STEP 3: Checking documents")
                print("   Total documents found:", documents.count)
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                
                if documents.isEmpty {
                    print("⚠️ WARNING: No documents found!")
                    print("   Possible reasons:")
                    print("   1. No users with role='ngo' in Firebase")
                    print("   2. Firestore rules blocking access")
                    print("   3. Wrong collection name")
                    return
                }
                
                // Parse each document
                print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                print("🔵 STEP 4: Parsing documents...")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                
                var successCount = 0
                var failCount = 0
                
                self.allNGOs = documents.compactMap { doc in
                    print("\n📄 Document ID:", doc.documentID)
                    
                    let data = doc.data()
                    print("   Raw data keys:", data.keys.sorted())
                    print("   Role value:", data["role"] ?? "MISSING")
                    print("   Organization name:", data["organizationName"] ?? "MISSING")
                    
                    do {
                        let user = try doc.data(as: User.self)
                        print("   ✅ Successfully decoded!")
                        print("   → Organization:", user.organizationName ?? "nil")
                        print("   → Email:", user.email)
                        successCount += 1
                        return user
                    } catch {
                        print("   ❌ Decode FAILED!")
                        print("   → Error:", error)
                        failCount += 1
                        return nil
                    }
                }
                
                print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                print("📊 PARSING SUMMARY:")
                print("   ✅ Successful:", successCount)
                print("   ❌ Failed:", failCount)
                print("   📦 Total NGOs loaded:", self.allNGOs.count)
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                
                self.ngos = self.allNGOs
                
                // Update UI
                print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                print("🔵 STEP 5: Updating UI...")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                
                DispatchQueue.main.async {
                    let beforeCount = self.tableView.numberOfRows(inSection: 0)
                    print("   Table rows BEFORE reload:", beforeCount)

                    self.applySearch(text: self.currentSearchText)
                    
                    let afterCount = self.tableView.numberOfRows(inSection: 0)
                    print("   Table rows AFTER reload:", afterCount)
                    
                    if afterCount == 0 {
                        print("   ⚠️ WARNING: Table still shows 0 rows!")
                    } else {
                        print("   ✅ SUCCESS: Table updated!")
                    }
                    
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    print("✅ FETCH COMPLETE!")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                }
            }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupFilterButtons() {
        filterAllButton.addTarget(self, action: #selector(filterTapped(_:)), for: .touchUpInside)
        filterAZButton.addTarget(self, action: #selector(filterTapped(_:)), for: .touchUpInside)
        filterZAButton.addTarget(self, action: #selector(filterTapped(_:)), for: .touchUpInside)
        
        filterAllButton.tag = 0
        filterAZButton.tag = 1
        filterZAButton.tag = 2
        
        updateFilterStyles()
    }
    
    @objc private func filterTapped(_ sender: UIButton) {
        selectedFilter = sender.tag
        updateFilterStyles()
        sortNGOs()
    }
    
    private func updateFilterStyles() {
        let buttons = [filterAllButton, filterAZButton, filterZAButton]
        
        for (index, button) in buttons.enumerated() {
            if index == selectedFilter {
                button?.backgroundColor = UIColor(red: 0.15, green: 0.3, blue: 0.6, alpha: 1.0)
                button?.setTitleColor(.white, for: .normal)
            } else {
                button?.backgroundColor = .clear
                button?.setTitleColor(.white.withAlphaComponent(0.7), for: .normal)
            }
        }
    }
    
    private func sortNGOs() {
        var base = allNGOs
        let q = currentSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            base = base.filter { u in
                (u.organizationName ?? "").lowercased().contains(q) ||
                (u.username ?? "").lowercased().contains(q) ||
                u.email.lowercased().contains(q)
            }
        }

        switch selectedFilter {
        case 1:
            ngos = base.sorted { ($0.organizationName ?? "") < ($1.organizationName ?? "") }
        case 2:
            ngos = base.sorted { ($0.organizationName ?? "") > ($1.organizationName ?? "") }
        default:
            ngos = base
        }
        tableView.reloadData()
    }

    private func setupHeader() {
        guard let header = Bundle.main
            .loadNibNamed("HeaderView", owner: nil, options: nil)?
            .first as? HeaderView else {
            return
        }

        header.clear.isHidden = true
        header.frame = headerContainer.bounds
        header.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        header.takaffalLabel.text = "Takaffal"
        header.backBtn.isHidden = true
        header.search.isHidden = false
        header.notiBtn.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)

        header.onSearchTextChanged = { [weak self] text in
            self?.applySearch(text: text)
        }

        headerContainer.addSubview(header)
        self.headerView = header
    }

    private func applySearch(text: String) {
        currentSearchText = text
        sortNGOs()
    }

    @objc private func openNotifications() {
        print("🔔 Notifications")
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

extension AbdullaViewController1: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("📊 Table asking for row count: \(ngos.count)")
        return ngos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("🔵 Creating cell for row \(indexPath.row)")
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "NGOCell", for: indexPath) as! NGOCell
        
        let ngo = ngos[indexPath.row]
        print("   → NGO name:", ngo.organizationName ?? "nil")
        
        cell.configure(with: ngo)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedNGO = ngos[indexPath.row]
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔵 User tapped row:", indexPath.row)
        print("🔵 Selected NGO:", selectedNGO.organizationName ?? "Unknown")
        print("🔵 Selected NGO ID:", selectedNGO.id)
        print("🔵 Selected NGO Email:", selectedNGO.email)
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        let storyboard = UIStoryboard(name: "AbdullaStoryboard1", bundle: nil)
        
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "NGODetailViewController") as? NGODetailViewController {
            
            print("✅ Detail VC created")
            
            detailVC.selectedUser = selectedNGO
            
            print("✅ selectedUser set to:", detailVC.selectedUser?.organizationName ?? "nil")
            
            navigationController?.pushViewController(detailVC, animated: true)
            
            print("✅ Navigation pushed")
        } else {
            print("❌ Failed to create detail VC")
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}
