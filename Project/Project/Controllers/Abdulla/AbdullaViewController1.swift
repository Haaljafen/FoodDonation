import UIKit

class AbdullaViewController1: UIViewController {

    // MARK: - Outlets
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
    private var ngos: [String] = [
        "Kaaf",
        "Hope Kitchen",
        "Food Rescue Alliance",
        "Community Meals Inc",
        "Care & Share",
        "Food Rescue Alliance",
        "Community Meals Inc",
        "Care & Share"
    ]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupFilterButtons()
        

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !didSetupViews {
            didSetupViews = true
            setupHeader()
            setupNav()
        }
    }
    
    // MARK: - Setup Table View
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    // MARK: - Setup Filter Buttons
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
        case 1: ngos.sort { $0 < $1 }
        case 2: ngos.sort { $0 > $1 }
        default: ngos = ["Kaaf", "Hope Kitchen", "Food Rescue Alliance", "Community Meals Inc", "Care & Share"]
        }
        tableView.reloadData()
    }

    // MARK: - Setup Header
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

    // MARK: - Setup Nav
    private func setupNav() {
        guard let nav = Bundle.main
            .loadNibNamed("BottomNavView", owner: nil, options: nil)?
            .first as? BottomNavView else {
            print("XXXXX")
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

// MARK: - Table View Delegate & DataSource
extension AbdullaViewController1: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ngos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NGOCell", for: indexPath) as! NGOCell
        cell.configure(with: ngos[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedNGO = ngos[indexPath.row]
            print("🔵 Selected: \(selectedNGO)")
            
            // Debug: Check storyboard
            let storyboard = UIStoryboard(name: "AbdullaStoryboard1", bundle: nil)
            print("🔵 Storyboard loaded:", storyboard)
            
            // Debug: Try to instantiate
            if let detailVC = storyboard.instantiateViewController(withIdentifier: "NGODetailViewController") as? NGODetailViewController {
                print("✅ Detail VC created successfully")
                
                // Debug: Check navigation controller
                if let navController = navigationController {
                    print("✅ Navigation controller exists:", navController)
                    navController.pushViewController(detailVC, animated: true)
                    print("✅ Push completed")
                } else {
                    print("❌ No navigation controller!")
                }
            } else {
                print("❌ Failed to instantiate NGODetailViewController")
                print("   Check: Is Storyboard ID set to 'NGODetailViewController'?")
                print("   Check: Is Custom Class set to 'NGODetailViewController'?")
            }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}
