import UIKit
import FirebaseAuth
import FirebaseFirestore

final class NotificationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var tableView: UITableView!

    private var headerView: HeaderView?

    private var roleListener: ListenerRegistration?
    private var userListener: ListenerRegistration?

    private let db = Firestore.firestore()

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

    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.rowHeight = 85
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
            print("✅ uid:", uid)
            print("✅ roleStr:", roleStr, " -> roleEnum:", role.rawValue)
            print("✅ user doc exists:", snap?.exists ?? false)
            print("✅ user doc data:", snap?.data() ?? [:])
        }
    }

    private func listenNotifications(uid: String, role: UserRole) {
        roleListener?.remove()
        userListener?.remove()

        let roleQuery = db.collection("Notifications")
            .whereField("audience", arrayContains: role.rawValue)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)

        let userQuery = db.collection("Notifications")
            .whereField("toUserId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)

        roleListener = roleQuery.addSnapshotListener { [weak self] snap, error in
            self?.handleSnapshot(source: "ROLE", snap, error)
        }

        userListener = userQuery.addSnapshotListener { [weak self] snap, error in
            self?.handleSnapshot(source: "USER", snap, error)
        }
    }

    deinit {
        roleListener?.remove()
        userListener?.remove()
    }


    private func handleSnapshot(source: String, _ snap: QuerySnapshot?, _ error: Error?) {

        if let error = error as NSError? {
            print("❌ \(source) listen error:", error.localizedDescription,
                  " | domain:", error.domain, " code:", error.code)
            return
        }

        let docs = snap?.documents ?? []
        print("✅ \(source) got docs:", docs.count)

        if let first = docs.first {
            print("✅ \(source) first doc:", first.documentID, first.data())
        }

        let incoming: [NotifItem] = docs.map { d in
            let data = d.data()
            return NotifItem(
                id: d.documentID,
                title: data["title"] as? String ?? "",
                subtitle: data["subtitle"] as? String ?? "",
                iconName: data["iconName"] as? String ?? "notif_user",
                createdAt: data["createdAt"] as? Timestamp
            )
        }

        var dict = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        for n in incoming { dict[n.id] = n }

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
