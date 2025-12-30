import UIKit

class NGODetailViewController: UIViewController {

    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var navContainer: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    private var headerView: HeaderView?
    private var bottomNav: BottomNavView?
    private var didSetupViews = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !didSetupViews {
            didSetupViews = true
            setupHeader()
            setupNav()
        }
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
        header.backBtn.isHidden = false  // Show back button
        header.backBtn.addTarget(self, action: #selector(goBack), for: .touchUpInside)
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide navigation bar
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show it again when leaving (so list screen still has it)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }
}

