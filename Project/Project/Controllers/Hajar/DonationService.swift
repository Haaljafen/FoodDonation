import Foundation
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

final class DonationService {
    static let shared = DonationService()
    private init() {}

    private let db = Firestore.firestore()
    private var didRequestNotificationPermission = false

    enum NotificationEventType: String {
        // MARK: - Donor Notification Cases
        case donationCreated = "DONATION_CREATED"
        case donationAccepted = "DONATION_ACCEPTED"
        case donationRejected = "DONATION_REJECTED"
        case donationPickupScheduled = "DONATION_PICKUP_SCHEDULED"
        case donationPickedUp = "DONATION_PICKED_UP"
        case donationExpired = "DONATION_EXPIRED"

        // MARK: - NGO Notification Cases
        case newDonationAvailable = "NEW_DONATION_AVAILABLE"
        case donationAcceptedByYou = "DONATION_ACCEPTED_BY_YOU"
        case donationRejectedByYou = "DONATION_REJECTED_BY_YOU"
        case donationCancelledByDonor = "DONATION_CANCELLED_BY_DONOR"
        case pickupConfirmed = "PICKUP_CONFIRMED"
        case donationCompleted = "DONATION_COMPLETED"

        // MARK: - Admin Notification Cases
        case newDonationCreated = "NEW_DONATION_CREATED"
        case donationAcceptedAdmin = "ADMIN_DONATION_ACCEPTED"
        case donationRejectedAdmin = "ADMIN_DONATION_REJECTED"
        case donationCancelledAdmin = "ADMIN_DONATION_CANCELLED"
        case donationCompletedAdmin = "ADMIN_DONATION_COMPLETED"
        case systemAlert = "SYSTEM_ALERT"

        // MARK: - Existing (legacy) cases used elsewhere in the app
        case donationCollected
        case userRegistered
        case userApproved
        case profileUpdated
        case ngoAssignedDonation
        case ngoPickupScheduled
        case pickupReminder
        case itemExpiryWarning

        // Swift enums can't share the same rawValue, but Firestore event keys must match the spec.
        // Use this computed property when writing notification docs.
        var eventKey: String {
            switch self {
            case .donationAcceptedAdmin:
                return "DONATION_ACCEPTED"
            case .donationRejectedAdmin:
                return "DONATION_REJECTED"
            case .donationCancelledAdmin:
                return "DONATION_CANCELLED"
            case .donationCompletedAdmin:
                return "DONATION_COMPLETED"
            default:
                return rawValue
            }
        }
    }

    private func content(for type: NotificationEventType) -> (title: String, subtitle: String, iconName: String) {
        switch type {
        case .donationCreated:
            return ("Donation Created", "Donation posted.", "notif_donation")
        case .donationAccepted:
            return ("Donation Accepted", "Accepted by an NGO.", "notif_accept")
        case .donationRejected:
            return ("Donation Not Accepted", "Not accepted.", "notif_reject")
        case .donationPickupScheduled:
            return ("Pickup Scheduled", "Pickup scheduled.", "notif_pickup")
        case .donationPickedUp:
            return ("Donation Collected", "Picked up.", "notif_pickup")
        case .donationExpired:
            return ("Donation Expired", "Expired.", "notif_warning")

        case .newDonationAvailable:
            return ("New Donation Available", "New donation posted.", "notif_donation")
        case .donationAcceptedByYou:
            return ("Donation Accepted", "You accepted it.", "notif_accept")
        case .donationRejectedByYou:
            return ("Donation Rejected", "You rejected it.", "notif_reject")
        case .donationCancelledByDonor:
            return ("Donation Cancelled", "Cancelled by donor.", "notif_warning")
        case .pickupConfirmed:
            return ("Pickup Confirmed", "Pickup confirmed.", "notif_pickup")
        case .donationCompleted:
            return ("Donation Completed", "Completed.", "notif_accept")

        case .newDonationCreated:
            return ("New Donation Created", "New donation added.", "notif_admin")
        case .donationAcceptedAdmin:
            return ("Donation Accepted", "Accepted by NGO.", "notif_accept")
        case .donationRejectedAdmin:
            return ("Donation Rejected", "Rejected by NGO.", "notif_reject")
        case .donationCancelledAdmin:
            return ("Donation Cancelled", "Cancelled by donor.", "notif_warning")
        case .donationCompletedAdmin:
            return ("Donation Completed", "Completed.", "notif_accept")
        case .systemAlert:
            return ("System Alert", "Action required.", "notif_warning")

        case .donationCollected:
            return ("Donation Collected", "Picked up.", "notif_pickup")

        case .userRegistered:
            return ("Welcome to Takaffal", "Account created.", "notif_user")
        case .userApproved:
            return ("User Approved", "Verified.", "notif_accept")
        case .profileUpdated:
            return ("Profile updated", "Updated.", "notif_user")
        case .ngoAssignedDonation:
            return ("Donation assigned", "Assigned to your NGO.", "notif_donation")
        case .ngoPickupScheduled:
            return ("Pickup scheduled", "Pickup scheduled.", "notif_pickup")
        case .pickupReminder:
            return ("Pickup reminder", "Scheduled pickup.", "notif_pickup")
        case .itemExpiryWarning:
            return ("Expiry warning", "Expiring soon.", "notif_warning")
        }
    }

    // MARK: - Create Donation
    func createDonation(
        _ donation: Donation,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        do {
            var data = try Firestore.Encoder().encode(donation)

            // ✅ Force createdAt as Timestamp (createdAt is non-optional)
            data["createdAt"] = Timestamp(date: donation.createdAt)

            // ✅ expiryDate optional -> Timestamp
            if let expiryDate = donation.expiryDate {
                data["expiryDate"] = Timestamp(date: expiryDate)
            } else {
                data["expiryDate"] = NSNull()
            }

            db.collection("Donations")
                .document(donation.id)
                .setData(data) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        self.createNotificationsForDonation(donation)
                        self.scheduleLocalNotificationForDonationCreated(donation)
                        completion(.success(()))
                    }
                }

        } catch {
            completion(.failure(error))
        }
    }

    private func createNotificationsForDonation(_ donation: Donation) {
        writeNotification(
            type: .donationCreated,
            relatedDonationId: donation.id,
            toUserId: donation.donorId,
            audience: nil
        )

        writeNotification(
            type: .newDonationAvailable,
            relatedDonationId: donation.id,
            toUserId: nil,
            audience: ["admin", "ngo"]
        )

        writeNotification(
            type: .newDonationCreated,
            relatedDonationId: donation.id,
            toUserId: nil,
            audience: ["admin"]
        )
    }

    func notify(
        type: NotificationEventType,
        relatedDonationId: String? = nil,
        toUserId: String? = nil,
        audience: [String]? = nil
    ) {
        writeNotification(
            type: type,
            relatedDonationId: relatedDonationId,
            toUserId: toUserId,
            audience: audience
        )
    }

    private func writeNotification(
        type: NotificationEventType,
        relatedDonationId: String?,
        toUserId: String?,
        audience: [String]?
    ) {
        let createdAt = Timestamp(date: Date())
        let c = content(for: type)

        var data: [String: Any] = [
            "type": type.eventKey,
            "title": c.title,
            "subtitle": c.subtitle,
            "iconName": c.iconName,
            "createdAt": createdAt
        ]

        if let relatedDonationId {
            data["donationId"] = relatedDonationId
        }

        if let toUserId {
            data["toUserId"] = toUserId
        }
        if let audience {
            data["audience"] = audience
        }

        let target = toUserId ?? "audience"
        let scope = relatedDonationId ?? "none"
        let docId = "\(type.eventKey)_\(scope)_\(target)"

        let ref = db.collection("Notifications").document(docId)
        ref.getDocument { snap, err in
            if let err {
                print("❌ Failed to check notification existence:", err.localizedDescription)
                return
            }
            if snap?.exists == true {
                return
            }
            ref.setData(data, merge: false) { error in
                if let error = error {
                    print("❌ Failed to write notification:", error.localizedDescription)
                }
            }
        }
    }

    private func processExpiryNotifications(_ donations: [Donation]) {
        let now = Date()
        let warningThresholdSeconds: TimeInterval = 24 * 60 * 60

        for d in donations {
            guard let expiry = d.expiryDate else { continue }

            if expiry <= now {
                notify(type: .donationExpired, relatedDonationId: d.id, toUserId: d.donorId, audience: nil)
                notify(type: .donationExpired, relatedDonationId: d.id, toUserId: nil, audience: ["admin", "ngo"])
            } else if expiry.timeIntervalSince(now) <= warningThresholdSeconds {
                notify(type: .itemExpiryWarning, relatedDonationId: d.id, toUserId: d.donorId, audience: nil)
                notify(type: .itemExpiryWarning, relatedDonationId: d.id, toUserId: nil, audience: ["admin", "ngo"])
            }
        }
    }

    private func scheduleLocalNotificationForDonationCreated(_ donation: Donation) {
        let notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        guard notificationsEnabled else { return }

        guard let currentUid = Auth.auth().currentUser?.uid, currentUid == donation.donorId else {
            return
        }

        let center = UNUserNotificationCenter.current()

        if !didRequestNotificationPermission {
            didRequestNotificationPermission = true
            center.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        }

        let content = UNMutableNotificationContent()
        content.title = "You have created a new donation"
        content.body = "Your donation is now submitted"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "donation_created_\(donation.id)", content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("❌ Local notification schedule failed:", error.localizedDescription)
            }
        }
    }

    // MARK: - Live Listener (NGO: Pending Donations)
    func listenPendingDonations(
        onChange: @escaping (Result<[Donation], Error>) -> Void
    ) -> ListenerRegistration {

        return db.collection("Donations")
            .whereField("status", isEqualTo: DonationStatus.pending.rawValue)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in

                if let error = error {
                    onChange(.failure(error))
                    return
                }

                guard let docs = snapshot?.documents else {
                    onChange(.success([]))
                    return
                }

                let donations: [Donation] = docs.compactMap { doc in
                    var data = doc.data()

                    // ✅ Inject Firestore docID so decoder fills `let id`
                    data["id"] = doc.documentID

                    // 🔁 Handle legacy expiryDate saved as String
                    if let expiryString = data["expiryDate"] as? String {
                        let df = DateFormatter()
                        df.dateFormat = "dd/MM/yyyy" // match your form
                        if let parsedDate = df.date(from: expiryString) {
                            data["expiryDate"] = Timestamp(date: parsedDate)
                        } else {
                            data["expiryDate"] = nil
                        }
                    }

                    do {
                        return try Firestore.Decoder().decode(Donation.self, from: data)
                    } catch {
                        print("❌ Donation decode failed:", error)
                        print("📄 Raw Firestore data:", data)
                        return nil
                    }
                }

                self?.processExpiryNotifications(donations)

                onChange(.success(donations))
            }
    }
}
