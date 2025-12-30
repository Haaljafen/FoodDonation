import Foundation
import FirebaseFirestore
import FirebaseAuth

final class DonationService {
    static let shared = DonationService()
    private init() {}

    private let db = Firestore.firestore()

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
                        completion(.success(()))
                    }
                }

        } catch {
            completion(.failure(error))
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
