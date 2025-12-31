import UIKit
import FirebaseAuth
import FirebaseFirestore

final class NotificationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var tableView: UITableView!

    private var headerView: HeaderView?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    struct NotifItem {
        let id: String
        let title: String
        let subtitle: String
        let iconName: String
        let createdAt: Timestamp?
    }

    private var items: [NotifItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHeader()
        setupTable()
        fetchCurrentUserRoleAndListen()
    }

    deinit {
        listener?.remove()
    }

    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.rowHeight = 90
    }

    // MARK: - Role → then listen notifications
    private func fetchCurrentUserRoleAndListen() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ No logged in user")
            return
        }

        db.collection("Users").document(uid).getDocument { [weak self] snap, error in
            guard let self = self else { return }
            if let error = error {
                print("❌ role fetch error:", error.localizedDescription)
                return
            }

            let roleStr = ((snap?.data()?["role"] as? String) ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            let role = UserRole(rawValue: roleStr) ?? .donor
            self.listenNotifications(uid: uid, role: role)
        }
    }

    private func listenNotifications(uid: String, role: UserRole) {
        listener?.remove()

        // Query: role-based notifications
        let roleQuery = db.collection("Notifications")
            .whereField("audience", arrayContains: role.rawValue)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)

        // Query: user-specific notifications
        let userQuery = db.collection("Notifications")
            .whereField("toUserId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)

        // ✅ Easiest: listen to BOTH and merge
        // 1) role notifications
        roleQuery.addSnapshotListener { [weak self] snap, error in
            self?.handleSnapshot(snap, error)
        }

        // 2) user notifications
        userQuery.addSnapshotListener { [weak self] snap, error in
            self?.handleSnapshot(snap, error)
        }
    }

    private func handleSnapshot(_ snap: QuerySnapshot?, _ error: Error?) {
        if let error = error {
            print("❌ notifications listen error:", error.localizedDescription)
            return
        }
        guard let docs = snap?.documents else { return }

        var incoming: [NotifItem] = docs.map { d in
            let data = d.data()
            return NotifItem(
                id: d.documentID,
                title: data["title"] as? String ?? "",
                subtitle: data["subtitle"] as? String ?? "",
                iconName: data["iconName"] as? String ?? "notif_user",
                createdAt: data["createdAt"] as? Timestamp
            )
        }

        // Merge (avoid duplicates by id)
        var dict = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        for n in incoming { dict[n.id] = n }

        // Sort newest
        items = dict.values.sorted {
            ($0.createdAt?.dateValue() ?? .distantPast) > ($1.createdAt?.dateValue() ?? .distantPast)
        }

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    // MARK: - Table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath) as? NotificationCell else {
            return UITableViewCell()
        }
        let item = items[indexPath.row]
        cell.configure(title: item.title, subtitle: item.subtitle, iconName: item.iconName)
        cell.selectionStyle = .none
        return cell
    }

    // MARK: - Header
    @objc private func openNotifications() {
        navigationController?.popViewController(animated: true)
    }

    private func setupHeader() {
        guard let header = Bundle.main.loadNibNamed("HeaderView", owner: nil, options: nil)?.first as? HeaderView else {
            print("❌ Failed to load HeaderView.xib")
            return
        }

        header.frame = headerContainer.bounds
        header.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        header.takaffalLabel.text = "Takaffal"
        header.backBtn.isHidden = false
        header.search.isHidden = true
        header.notiBtn.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)

        headerContainer.addSubview(header)
        headerContainer.backgroundColor = .clear
        self.headerView = header
    }
}
