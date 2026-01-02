import UIKit
import FirebaseFirestore
import FirebaseAuth

class AbdullaViewController2: UIViewController {

    // MARK: - Outlets (from storyboard)
    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var navContainer: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var userTypeSegment: UISegmentedControl!

    @IBOutlet weak var totalCountLabel: UILabel!
    @IBOutlet weak var donorsCountLabel: UILabel!
    @IBOutlet weak var ngosCountLabel: UILabel!
    // MARK: - Properties
    private var headerView: HeaderView?
    private var bottomNav: BottomNavView?
    private var didSetupViews = false
    private var currentUserRole: UserRole?
    // ✅ Firebase
    private let db = Firestore.firestore()
    
    // ✅ Data
    private var allUsers: [User] = []
    private var filteredUsers: [User] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupSegmentedControl()
        fetchUsers()
    }
    
    private func updateStats() {
        let donorCount = allUsers.filter { $0.role == .donor }.count
        let ngoCount = allUsers.filter { $0.role == .ngo }.count
        let totalCount = donorCount + ngoCount  // ✅ Only non-admins
        
        totalCountLabel?.text = "\(totalCount)"  // Would show 15
        donorsCountLabel?.text = "\(donorCount)"
        ngosCountLabel?.text = "\(ngoCount)"
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !didSetupViews {
            didSetupViews = true
            setupHeader()
            setupNav()
        }
    }
    
    // MARK: - Fetch Users from Firebase
    private func fetchUsers() {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔵 STEP 1: Fetching all users from Firebase...")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        db.collection("Users")
            .getDocuments { [weak self] snapshot, error in
                
                if let error = error {
                    print("❌ ERROR:", error.localizedDescription)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No users found in database")
                    return
                }
                
                print("📦 Found \(documents.count) total documents")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                
                var ngoCount = 0
                var donorCount = 0
                var otherCount = 0
                
                let users = documents.compactMap { doc -> User? in
                    do {
                        let user = try doc.data(as: User.self)
                        
                        switch user.role {
                        case .ngo:
                            ngoCount += 1
                            print("✅ NGO: \(user.organizationName ?? "Unknown") - Status: \(user.status?.rawValue ?? "N/A")")
                        case .donor:
                            donorCount += 1
                            print("✅ Donor: \(user.username ?? "Unknown") - Status: \(user.status?.rawValue ?? "N/A")")
                        case .admin:
                            otherCount += 1
                            print("✅ Admin: \(user.username ?? "Unknown")")
                        }
                        
                        return user
                    } catch {
                        print("❌ Failed to decode document \(doc.documentID):", error)
                        return nil
                    }
                }
                
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                print("📊 SUMMARY:")
                print("   Total Users: \(users.count)")
                print("   NGOs: \(ngoCount)")
                print("   Donors: \(donorCount)")
                print("   Admins: \(otherCount)")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                
                self?.allUsers = users
                
                DispatchQueue.main.async {
                    self?.updateStats()
                    
                    // ✅ REAPPLY CURRENT FILTER
                    let currentSegment = self?.userTypeSegment.selectedSegmentIndex ?? 0
                    if currentSegment == 0 {
                        self?.filteredUsers = users.filter { $0.role == .ngo }
                        print("🔄 Filtered to NGOs: \(self?.filteredUsers.count ?? 0)")
                    } else {
                        self?.filteredUsers = users.filter { $0.role == .donor }
                        print("🔄 Filtered to Donors: \(self?.filteredUsers.count ?? 0)")
                    }
                    
                    self?.tableView.reloadData()
                    print("✅ Table reloaded - Showing \(self?.filteredUsers.count ?? 0) users")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                }
            }
    }
    
    // MARK: - Setup Table View
    private func setupTableView() {
        print("🔧 Setting up table view...")
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        
        // ✅ ENABLE USER INTERACTION
        tableView.isUserInteractionEnabled = true
        tableView.allowsSelection = true
        
        print("   isUserInteractionEnabled: \(tableView.isUserInteractionEnabled)")
        print("   allowsSelection: \(tableView.allowsSelection)")
        
        // ✅ Add pull-to-refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshUsers), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        print("✅ Table view setup complete")
    }
    
    @objc private func refreshUsers() {
        print("🔄 Refreshing users...")
        fetchUsers()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    // MARK: - Setup Segmented Control
    private func setupSegmentedControl() {
        userTypeSegment.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }
    
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🔵 Filter: NGO")
            filteredUsers = allUsers.filter { $0.role == .ngo }
            print("   Showing \(filteredUsers.count) NGOs")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        } else {
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🔵 Filter: Donor")
            filteredUsers = allUsers.filter { $0.role == .donor }
            print("   Showing \(filteredUsers.count) Donors")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        }
        tableView.reloadData()
    }

    // MARK: - Header Setup
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
        header.backBtn.isHidden = true
        header.notiBtn.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)

        headerContainer.addSubview(header)
        headerContainer.backgroundColor = .clear
        self.headerView = header
    }

    @objc private func openNotifications() {
        print("🔔 Notifications tapped")
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



// MARK: - Table View Delegate & DataSource
extension AbdullaViewController2: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = filteredUsers.count
        print("📊 Table asking for row count: \(count)")
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as? UserCell else {
            print("❌ Failed to dequeue UserCell")
            return UITableViewCell()
        }
        
        let user = filteredUsers[indexPath.row]
        
        print("🔵 Creating cell for row \(indexPath.row):")
        print("   Name: \(user.organizationName ?? user.username ?? "Unknown")")
        print("   Status: \(user.status?.rawValue ?? "N/A")")
        
        let donationCount = 0
        
        // ✅ USE NEW METHOD
        cell.configure(with: user, donationCount: donationCount)
        
        cell.selectionStyle = .default
        cell.backgroundColor = .clear
        
        return cell
    }
   
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🎯 CELL TAPPED!!!")
        print("   Row: \(indexPath.row)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedUser = filteredUsers[indexPath.row]
        
        print("🔵 User Selected:")
        print("   Name: \(selectedUser.organizationName ?? selectedUser.username ?? "Unknown")")
        print("   Role: \(selectedUser.role.rawValue)")
        print("   Status: \(selectedUser.status?.rawValue ?? "N/A")")
        print("   ID: \(selectedUser.id)")
        
        // ✅ DEBUG: Check navigation controller
        print("🔍 Navigation Controller: \(String(describing: navigationController))")
        print("🔍 Is nil?: \(navigationController == nil)")
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        let storyboard = UIStoryboard(name: "AbdullaStoryboard2", bundle: nil)
        
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "UserDetailViewController") as? UserDetailViewController {
            
            print("✅ Detail VC created successfully")
            
            detailVC.user = selectedUser
            
            // ✅ DEBUG: Try to push
            if let navController = navigationController {
                print("✅ Nav controller exists, pushing...")
                navController.pushViewController(detailVC, animated: true)
                print("✅ Push called")
            } else {
                print("❌ ERROR: Navigation controller is NIL!")
                print("   Trying modal presentation instead...")
                present(detailVC, animated: true)
            }
        } else {
            print("❌ Failed to load UserDetailViewController")
        }
    }
}
