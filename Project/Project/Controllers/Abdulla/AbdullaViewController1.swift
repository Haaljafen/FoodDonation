import UIKit
import FirebaseFirestore  // ✅ ADD THIS

class AbdullaViewController1: UIViewController {

    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var navContainer: UIView!
    @IBOutlet weak var filterAllButton: UIButton!
    @IBOutlet weak var filterAZButton: UIButton!
    @IBOutlet weak var filterZAButton: UIButton!
    @IBOutlet weak var tableView: UITableView!

    private var headerView: HeaderView?
    private var bottomNav: BottomNavView?
    private var didSetupViews = false
    
    private var selectedFilter = 0
    
    // ✅ CHANGED: User objects instead of String
    private var ngos: [User] = []
    private var allNGOs: [User] = []
    
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
                    
                    self.tableView.reloadData()
                    
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
        switch selectedFilter {
        case 1:
            ngos.sort { ($0.organizationName ?? "") < ($1.organizationName ?? "") }
        case 2:
            ngos.sort { ($0.organizationName ?? "") > ($1.organizationName ?? "") }
        default:
            ngos = allNGOs
        }
        tableView.reloadData()
    }

    private func setupHeader() {
        guard let header = Bundle.main
            .loadNibNamed("HeaderView", owner: nil, options: nil)?
            .first as? HeaderView else {
            return
        }

        header.frame = headerContainer.bounds
        header.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        header.takaffalLabel.text = "Takaffal"
        header.backBtn.isHidden = true
        header.notiBtn.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)

        headerContainer.addSubview(header)
        self.headerView = header
    }

    @objc private func openNotifications() {
        print("🔔 Notifications")
    }

    private func setupNav() {
        guard let nav = Bundle.main
            .loadNibNamed("BottomNavView", owner: nil, options: nil)?
            .first as? BottomNavView else {
            return
        }

        nav.frame = navContainer.bounds
        nav.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navContainer.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)

        nav.listBtn.isHidden = false
        nav.listLab.isHidden = false
        nav.hisBtn.isHidden = false
        nav.hisLab.isHidden = false
        nav.impBtn.isHidden = false
        nav.ompLab.isHidden = false
        nav.proBtn.isHidden = false
        nav.proLab.isHidden = false
        
        nav.userBtn.isHidden = true
        nav.userLab.isHidden = true
        nav.heartBtn.isHidden = true
        nav.donLab.isHidden = true
        nav.formBtn.isHidden = true
        nav.ngoLab.isHidden = true

        navContainer.addSubview(nav)
        self.bottomNav = nav
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
