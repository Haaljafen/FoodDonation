import UIKit
import FirebaseAuth
import FirebaseFirestore

final class CalendarViewController: UIViewController {

    private enum Role: String {
        case donor
        case ngo
        case admin
    }

    private struct CalendarEvent {
        enum Source {
            case pickupRequest
            case custom
            case expiry
        }

        let source: Source
        let id: String
        let donationId: String
        let method: String
        let date: Date
        let donorId: String?
        let ngoId: String?
        let facilityName: String?

        let title: String?
        let notes: String?

        var shortDonationId: String {
            donationId.components(separatedBy: "-").first ?? donationId
        }

        var displayTitle: String {
            if let title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return title
            }
            let m = method.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if m == "dropoff" || m == "drop-off" {
                return "Drop-off"
            }
            if m == "locationpickup" || m == "pickup" {
                return "Pickup"
            }
            return method.capitalized
        }

        var displayColor: UIColor {
            switch source {
            case .custom:
                return .systemPurple
            case .expiry:
                return .systemOrange
            case .pickupRequest:
                let m = method.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if m == "dropoff" || m == "drop-off" {
                    return .systemGreen
                }
                return .systemBlue
            }
        }
    }

    private let db = Firestore.firestore()

    private var role: Role? = nil
    private var uid: String? = nil

    private var monthAnchor: Date = Date()
    private var days: [Date] = []

    private var eventsByDayKey: [String: [CalendarEvent]] = [:]
    private var selectedDate: Date = Date()

    private lazy var monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "LLLL yyyy"
        return f
    }()

    private lazy var dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private lazy var timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()

    private let headerBar = UIView()
    private let monthLabel = UILabel()
    private let prevButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)

    private let weekdayStack = UIStackView()
    private var collectionView: UICollectionView!
    private let agendaLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)

    private var agenda: [CalendarEvent] {
        let key = dayKeyFormatter.string(from: selectedDate)
        return (eventsByDayKey[key] ?? []).sorted { $0.date < $1.date }
    }

    private func agendaSubtitle(for ev: CalendarEvent) -> String {
        switch ev.source {
        case .custom:
            return ev.notes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? (ev.notes ?? "") : "Personal"
        case .expiry:
            return "Donation: \(ev.shortDonationId)"
        case .pickupRequest:
            return "ID: \(ev.shortDonationId)"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        navigationItem.title = "Calendar"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                            target: self,
                                                            action: #selector(closeTapped))

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                           target: self,
                                                           action: #selector(addEventTapped))

        setupUI()
        setMonth(anchor: Date())

        resolveRoleAndLoad()
    }

    @objc private func addEventTapped() {
        presentAddEventSheet()
    }

    @objc private func closeTapped() {
        if presentingViewController != nil {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    private func setupUI() {
        headerBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerBar)

        monthLabel.translatesAutoresizingMaskIntoConstraints = false
        monthLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        monthLabel.textAlignment = .center

        prevButton.translatesAutoresizingMaskIntoConstraints = false
        prevButton.setTitle("‹", for: .normal)
        prevButton.titleLabel?.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
        prevButton.addTarget(self, action: #selector(prevMonth), for: .touchUpInside)

        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.setTitle("›", for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
        nextButton.addTarget(self, action: #selector(nextMonth), for: .touchUpInside)

        headerBar.addSubview(monthLabel)
        headerBar.addSubview(prevButton)
        headerBar.addSubview(nextButton)

        weekdayStack.translatesAutoresizingMaskIntoConstraints = false
        weekdayStack.axis = .horizontal
        weekdayStack.distribution = .fillEqually
        weekdayStack.alignment = .center
        view.addSubview(weekdayStack)

        let symbols = Calendar.current.shortWeekdaySymbols
        // Make it Sunday-first to match many calendar UIs
        let ordered = Array(symbols[0..<symbols.count])
        for s in ordered {
            let l = UILabel()
            l.text = s.uppercased()
            l.textAlignment = .center
            l.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            l.textColor = .secondaryLabel
            weekdayStack.addArrangedSubview(l)
        }

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(DayCell.self, forCellWithReuseIdentifier: DayCell.reuseId)
        view.addSubview(collectionView)

        agendaLabel.translatesAutoresizingMaskIntoConstraints = false
        agendaLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        agendaLabel.textColor = .label
        agendaLabel.text = "Agenda"
        view.addSubview(agendaLabel)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AgendaCell.self, forCellReuseIdentifier: AgendaCell.reuseId)
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            headerBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            headerBar.heightAnchor.constraint(equalToConstant: 44),

            prevButton.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor),
            prevButton.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),
            prevButton.widthAnchor.constraint(equalToConstant: 44),

            nextButton.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor),
            nextButton.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 44),

            monthLabel.centerXAnchor.constraint(equalTo: headerBar.centerXAnchor),
            monthLabel.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),
            monthLabel.leadingAnchor.constraint(greaterThanOrEqualTo: prevButton.trailingAnchor, constant: 8),
            monthLabel.trailingAnchor.constraint(lessThanOrEqualTo: nextButton.leadingAnchor, constant: -8),

            weekdayStack.topAnchor.constraint(equalTo: headerBar.bottomAnchor, constant: 8),
            weekdayStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            weekdayStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            weekdayStack.heightAnchor.constraint(equalToConstant: 20),

            collectionView.topAnchor.constraint(equalTo: weekdayStack.bottomAnchor, constant: 6),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            collectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.42),

            agendaLabel.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 10),
            agendaLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            agendaLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: agendaLabel.bottomAnchor, constant: 6),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func prevMonth() {
        guard let d = Calendar.current.date(byAdding: .month, value: -1, to: monthAnchor) else { return }
        setMonth(anchor: d)
        loadEventsForVisibleMonth()
    }

    @objc private func nextMonth() {
        guard let d = Calendar.current.date(byAdding: .month, value: 1, to: monthAnchor) else { return }
        setMonth(anchor: d)
        loadEventsForVisibleMonth()
    }

    private func setMonth(anchor: Date) {
        monthAnchor = anchor
        monthLabel.text = monthFormatter.string(from: monthAnchor)

        let cal = Calendar.current
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: monthAnchor)) ?? monthAnchor
        let weekday = cal.component(.weekday, from: monthStart) // 1..7
        // We assume Sunday-first grid; shift back to Sunday
        let leading = weekday - 1

        let gridStart = cal.date(byAdding: .day, value: -leading, to: monthStart) ?? monthStart
        days = (0..<42).compactMap { cal.date(byAdding: .day, value: $0, to: gridStart) }

        // Keep selected date within current month grid
        if !days.contains(where: { cal.isDate($0, inSameDayAs: selectedDate) }) {
            selectedDate = monthStart
        }

        collectionView.reloadData()
        tableView.reloadData()
    }

    private func resolveRoleAndLoad() {
        guard let uid = Auth.auth().currentUser?.uid else {
            self.uid = nil
            self.role = nil
            loadEventsForVisibleMonth()
            return
        }

        self.uid = uid
        db.collection("Users").document(uid).getDocument { [weak self] snap, _ in
            guard let self else { return }

            let roleStr = ((snap?.data()?["role"] as? String) ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            self.role = Role(rawValue: roleStr)
            self.loadEventsForVisibleMonth()
        }
    }

    private func loadEventsForVisibleMonth() {
        eventsByDayKey = [:]
        tableView.reloadData()
        collectionView.reloadData()

        let cal = Calendar.current
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: monthAnchor)) ?? monthAnchor
        guard let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart) else { return }

        var pickupQuery: Query = db.collection("PickupRequests")
            .whereField("pickupDateTime", isGreaterThanOrEqualTo: Timestamp(date: monthStart))
            .whereField("pickupDateTime", isLessThan: Timestamp(date: monthEnd))

        var customQuery: Query = db.collection("CalendarEvents")
        var donationExpiryQuery: Query = db.collection("Donations")

        // Custom agenda events are PRIVATE for everyone (even admin): only owner can see.
        // To avoid composite-index needs, we filter by month on the client.
        if let uid = uid {
            customQuery = customQuery.whereField("ownerId", isEqualTo: uid)

            if let role = role {
                switch role {
                case .donor:
                    pickupQuery = pickupQuery.whereField("donorId", isEqualTo: uid)
                    donationExpiryQuery = donationExpiryQuery.whereField("donorId", isEqualTo: uid)
                case .ngo:
                    pickupQuery = pickupQuery.whereField("ngoId", isEqualTo: uid)
                    donationExpiryQuery = donationExpiryQuery.whereField("collectorId", isEqualTo: uid)
                case .admin:
                    // Admin sees all pickup requests; expiry events are global.
                    donationExpiryQuery = donationExpiryQuery
                        .whereField("expiryDate", isGreaterThanOrEqualTo: Timestamp(date: monthStart))
                        .whereField("expiryDate", isLessThan: Timestamp(date: monthEnd))
                }
            } else {
                // Role not resolved yet: show only user's own custom events; block other queries.
                pickupQuery = pickupQuery.whereField("donorId", isEqualTo: "__none__")
                donationExpiryQuery = donationExpiryQuery.whereField("donorId", isEqualTo: "__none__")
            }
        } else {
            // Not logged in: show nothing
            customQuery = customQuery.whereField("ownerId", isEqualTo: "__none__")
            pickupQuery = pickupQuery.whereField("donorId", isEqualTo: "__none__")
            donationExpiryQuery = donationExpiryQuery.whereField("donorId", isEqualTo: "__none__")
        }

        let group = DispatchGroup()
        var byKey: [String: [CalendarEvent]] = [:]

        group.enter()
        pickupQuery.getDocuments { [weak self] snap, error in
            defer { group.leave() }
            guard let self else { return }
            if let error = error {
                print("❌ Calendar pickup fetch error:", error.localizedDescription)
                return
            }

            for doc in (snap?.documents ?? []) {
                let d = doc.data()
                guard let ts = d["pickupDateTime"] as? Timestamp else { continue }
                let date = ts.dateValue()

                let donationId = (d["donationId"] as? String) ?? ""
                let method = (d["method"] as? String) ?? ""

                let ev = CalendarEvent(
                    source: .pickupRequest,
                    id: (d["id"] as? String) ?? doc.documentID,
                    donationId: donationId,
                    method: method,
                    date: date,
                    donorId: d["donorId"] as? String,
                    ngoId: d["ngoId"] as? String,
                    facilityName: d["facilityName"] as? String,
                    title: nil,
                    notes: nil
                )

                let key = self.dayKeyFormatter.string(from: date)
                byKey[key, default: []].append(ev)
            }
        }

        group.enter()
        donationExpiryQuery.getDocuments { [weak self] snap, error in
            defer { group.leave() }
            guard let self else { return }
            if let error = error {
                print("❌ Calendar donation expiry fetch error:", error.localizedDescription)
                return
            }

            for doc in (snap?.documents ?? []) {
                let d = doc.data()
                guard let ts = d["expiryDate"] as? Timestamp else { continue }
                let date = ts.dateValue()
                if !(date >= monthStart && date < monthEnd) { continue }

                let donationId = (d["id"] as? String) ?? doc.documentID

                let ev = CalendarEvent(
                    source: .expiry,
                    id: doc.documentID,
                    donationId: donationId,
                    method: "expiry",
                    date: date,
                    donorId: d["donorId"] as? String,
                    ngoId: d["collectorId"] as? String,
                    facilityName: nil,
                    title: "Expires",
                    notes: nil
                )

                let key = self.dayKeyFormatter.string(from: date)
                byKey[key, default: []].append(ev)
            }
        }

        group.enter()
        customQuery.getDocuments { [weak self] snap, error in
            defer { group.leave() }
            guard let self else { return }
            if let error = error {
                print("❌ Calendar custom events fetch error:", error.localizedDescription)
                return
            }

            for doc in (snap?.documents ?? []) {
                let d = doc.data()
                guard let ts = d["startAt"] as? Timestamp else { continue }
                let date = ts.dateValue()

                if !(date >= monthStart && date < monthEnd) { continue }

                let title = d["title"] as? String
                let notes = d["notes"] as? String

                let ev = CalendarEvent(
                    source: .custom,
                    id: doc.documentID,
                    donationId: "",
                    method: "event",
                    date: date,
                    donorId: nil,
                    ngoId: nil,
                    facilityName: nil,
                    title: title,
                    notes: notes
                )

                let key = self.dayKeyFormatter.string(from: date)
                byKey[key, default: []].append(ev)
            }
        }

        group.notify(queue: .main) {
            self.eventsByDayKey = byKey
            self.collectionView.reloadData()
            self.tableView.reloadData()
        }
    }

    private func presentAddEventSheet() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .wheels
        picker.date = selectedDate

        let alert = UIAlertController(title: "New Event", message: "\n\n\n\n\n\n\n\n", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Title"
        }
        alert.addTextField { tf in
            tf.placeholder = "Notes (optional)"
        }

        alert.view.addSubview(picker)
        picker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            picker.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            picker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 100),
            picker.heightAnchor.constraint(equalToConstant: 180)
        ])

        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self else { return }

            let title = (alert.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let notes = (alert.textFields?.dropFirst().first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { return }

            let ref = self.db.collection("CalendarEvents").document()
            let data: [String: Any] = [
                "title": title,
                "notes": notes,
                "startAt": Timestamp(date: picker.date),
                "ownerId": uid,
                "createdAt": Timestamp(date: Date())
            ]

            ref.setData(data) { err in
                if let err = err {
                    print("❌ Failed to create CalendarEvent:", err.localizedDescription)
                    return
                }
                DispatchQueue.main.async {
                    self.selectedDate = picker.date
                    self.setMonth(anchor: picker.date)
                    self.loadEventsForVisibleMonth()
                }
            }
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }
}

// MARK: - Month grid
extension CalendarViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        days.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DayCell.reuseId, for: indexPath) as? DayCell else {
            return UICollectionViewCell()
        }

        let date = days[indexPath.item]
        let cal = Calendar.current
        let isInMonth = cal.component(.month, from: date) == cal.component(.month, from: monthAnchor)
        let isSelected = cal.isDate(date, inSameDayAs: selectedDate)

        let key = dayKeyFormatter.string(from: date)
        let colors = (eventsByDayKey[key] ?? [])
            .sorted { $0.date < $1.date }
            .map { $0.displayColor }

        cell.configure(
            day: cal.component(.day, from: date),
            inMonth: isInMonth,
            selected: isSelected,
            eventColors: colors
        )

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedDate = days[indexPath.item]
        collectionView.reloadData()
        tableView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = collectionView.bounds.width / 7
        let h = collectionView.bounds.height / 6
        return CGSize(width: floor(w), height: floor(h))
    }
}

// MARK: - Agenda list
extension CalendarViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        agenda.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AgendaCell.reuseId, for: indexPath) as? AgendaCell else {
            return UITableViewCell()
        }

        let ev = agenda[indexPath.row]
        cell.configure(
            time: timeFormatter.string(from: ev.date),
            title: ev.displayTitle,
            subtitle: agendaSubtitle(for: ev),
            color: ev.displayColor
        )
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
}

// MARK: - Day cell
private final class DayCell: UICollectionViewCell {

    static let reuseId = "DayCell"

    private let dayLabel = UILabel()
    private let dotsStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true

        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        dayLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        dayLabel.textAlignment = .center

        dotsStack.translatesAutoresizingMaskIntoConstraints = false
        dotsStack.axis = .horizontal
        dotsStack.spacing = 3
        dotsStack.alignment = .center
        dotsStack.distribution = .fillEqually

        contentView.addSubview(dayLabel)
        contentView.addSubview(dotsStack)

        NSLayoutConstraint.activate([
            dayLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            dayLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            dotsStack.topAnchor.constraint(equalTo: dayLabel.bottomAnchor, constant: 4),
            dotsStack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dotsStack.heightAnchor.constraint(equalToConstant: 6),
            dotsStack.widthAnchor.constraint(equalToConstant: 24)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(day: Int, inMonth: Bool, selected: Bool, eventColors: [UIColor]) {
        dayLabel.text = "\(day)"
        dayLabel.textColor = inMonth ? .label : .tertiaryLabel

        contentView.backgroundColor = selected ? UIColor.systemBlue.withAlphaComponent(0.15) : .clear

        dotsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let dots = min(3, eventColors.count)
        guard dots > 0 else { return }

        for i in 0..<dots {
            let v = UIView()
            v.translatesAutoresizingMaskIntoConstraints = false
            v.backgroundColor = eventColors[i]
            v.layer.cornerRadius = 3
            NSLayoutConstraint.activate([
                v.widthAnchor.constraint(equalToConstant: 6),
                v.heightAnchor.constraint(equalToConstant: 6)
            ])
            dotsStack.addArrangedSubview(v)
        }
    }
}

// MARK: - Agenda cell
private final class AgendaCell: UITableViewCell {

    static let reuseId = "AgendaCell"

    private let timeLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let colorDot = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        colorDot.translatesAutoresizingMaskIntoConstraints = false
        colorDot.layer.cornerRadius = 5

        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        timeLabel.textColor = .secondaryLabel

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel

        contentView.addSubview(timeLabel)
        contentView.addSubview(colorDot)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            timeLabel.widthAnchor.constraint(equalToConstant: 70),

            colorDot.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 12),
            colorDot.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorDot.widthAnchor.constraint(equalToConstant: 10),
            colorDot.heightAnchor.constraint(equalToConstant: 10),

            titleLabel.leadingAnchor.constraint(equalTo: colorDot.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(time: String, title: String, subtitle: String, color: UIColor) {
        timeLabel.text = time
        titleLabel.text = title
        subtitleLabel.text = subtitle
        colorDot.backgroundColor = color
    }
}
