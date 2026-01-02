import FirebaseFirestore
import FirebaseAuth

class AchievementFirebaseService {

    static let shared = AchievementFirebaseService()
    private init() {}

    func fetchAchievements(completion: @escaping (Bool) -> Void) {

        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        let db = Firestore.firestore()

        db.collection("Donations")
            .whereField("donorId", isEqualTo: uid)
            .getDocuments { snapshot, error in

                guard let documents = snapshot?.documents, error == nil else {
                    completion(false)
                    return
                }

                // RESET local counters
                let manager = AchievementManager.shared
                manager.donationCount = 0
                manager.mealsProvided = 0
                manager.collectionsCompleted = 0
                manager.uniqueNGOs = []
                manager.weeklyDonationDates = []
                manager.monthlyDonationDates = []

                for doc in documents {
                    let data = doc.data()

                    manager.donationCount += 1

                    // Meals
                    if data["impactType"] as? String == "Meals Provided" {
                        let qty = data["quantity"] as? Int ?? 0
                        manager.mealsProvided += qty
                    }

                    // Collected
                    if data["status"] as? String == "collected" {
                        manager.collectionsCompleted += 1
                    }

                    // NGOs
                    if let collectorId = data["collectorId"] as? String {
                        manager.uniqueNGOs.insert(collectorId)
                    }

                    // Dates
                    if let ts = data["createdAt"] as? Timestamp {
                        let date = ts.dateValue()
                        manager.weeklyDonationDates.append(date)
                        manager.monthlyDonationDates.append(date)
                    }
                }

                completion(true)
            }
    }
}
