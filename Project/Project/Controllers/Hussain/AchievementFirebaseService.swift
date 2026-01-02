import FirebaseFirestore
import FirebaseAuth

class AchievementFirebaseService {

    static let shared = AchievementFirebaseService()
    private let db = Firestore.firestore()

    func fetchAchievements(completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        db.collection("users").document(uid).getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                completion(false)
                return
            }

            AchievementManager.shared.applyRemoteData(data)
            completion(true)
        }
    }
}
