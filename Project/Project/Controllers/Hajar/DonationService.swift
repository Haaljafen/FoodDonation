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
        case donationCreated
        case newDonationAvailable
        case donationCollected
        case donationExpired
        case userRegistered
        case profileUpdated
        case ngoAssignedDonation
        case ngoPickupScheduled
        case pickupReminder
        case itemExpiryWarning
    }

    private func content(for type: NotificationEventType) -> (title: String, subtitle: String, iconName: String) {
        switch type {
        case .donationCreated:
            return ("You have created a new donation", "Your donation is now submitted", "notif_user")
        case .newDonationAvailable:
            return ("New donation is now available", "A donor has created a new donation", "notif_user")
        case .donationCollected:
            return ("Donation collected", "Your donation has been collected successfully", "notif_user")
        case .donationExpired:
            return ("Donation expired", "A donation has expired and is no longer available", "notif_user")
        case .userRegistered:
            return ("Welcome to Takaffal", "Your account has been created successfully", "notif_user")
        case .profileUpdated:
            return ("Profile updated", "Your profile information has been updated", "notif_user")
        case .ngoAssignedDonation:
            return ("Donation assigned", "A donation has been assigned to your NGO", "notif_user")
        case .ngoPickupScheduled:
            return ("Pickup scheduled", "A pickup has been scheduled for a donation", "notif_user")
        case .pickupReminder:
            return ("Pickup reminder", "Reminder: you have a scheduled pickup", "notif_user")
        case .itemExpiryWarning:
            return ("Expiry warning", "An item is close to expiring", "notif_user")
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
            "type": type.rawValue,
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
        let docId = "\(type.rawValue)_\(scope)_\(target)"

        db.collection("Notifications").document(docId).setData(data, merge: true) { error in
            if let error = error {
                print("❌ Failed to write notification:", error.localizedDescription)
            }
        }
    }

    private func scheduleLocalNotificationForDonationCreated(_ donation: Donation) {
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
            .addSnapshotListener { snapshot, error in

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

                onChange(.success(donations))
            }
    }
}
