//AchievementManager.swift

import Foundation
import FirebaseFirestore
import FirebaseAuth


class AchievementManager {

    static let shared = AchievementManager()
    private init() {}

    // MARK: - Stored Data
    private let donationCountKey = "ach_donationCount"
    private let mealsProvidedKey = "ach_mealsProvided"
    private let collectionsCompletedKey = "ach_collectionsCompleted"
    private let ngosKey = "ach_uniqueNGOs"
    private let weeklyDatesKey = "ach_weeklyDates"
    private let monthlyDatesKey = "ach_monthlyDates"

    var donationCount: Int {
        get { UserDefaults.standard.integer(forKey: donationCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: donationCountKey) }
    }

    var mealsProvided: Int {
        get { UserDefaults.standard.integer(forKey: mealsProvidedKey) }
        set { UserDefaults.standard.set(newValue, forKey: mealsProvidedKey) }
    }

    var collectionsCompleted: Int {
        get { UserDefaults.standard.integer(forKey: collectionsCompletedKey) }
        set { UserDefaults.standard.set(newValue, forKey: collectionsCompletedKey) }
    }

    var uniqueNGOs: Set<String> {
        get {
            let array = UserDefaults.standard.stringArray(forKey: ngosKey) ?? []
            return Set(array)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: ngosKey)
        }
    }

    var weeklyDonationDates: [Date] {
        get { UserDefaults.standard.array(forKey: weeklyDatesKey) as? [Date] ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: weeklyDatesKey) }
    }

    var monthlyDonationDates: [Date] {
        get { UserDefaults.standard.array(forKey: monthlyDatesKey) as? [Date] ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: monthlyDatesKey) }
    }

    // MARK: - Track donation event
    func recordDonation(ngoID: String, meals: Int) {
        donationCount += 1
        mealsProvided += meals
        collectionsCompleted += 1
        uniqueNGOs.insert(ngoID)
        recordWeeklyDonation()
        recordMonthlyDonation()

        syncToFirebase()
    }

    private func syncToFirebase() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .setData([
                "donationCount": donationCount,
                "mealsProvided": mealsProvided,
                "collectionsCompleted": collectionsCompleted,
                "uniqueNGOs": Array(uniqueNGOs),
                "weeklyDonationDates": weeklyDonationDates.map { Timestamp(date: $0) },
                "monthlyDonationDates": monthlyDonationDates.map { Timestamp(date: $0) }
            ], merge: true)
    }


    // MARK: - Weekly/Monthly helpers
    private func recordWeeklyDonation() {
        weeklyDonationDates.append(Date())
    }

    private func recordMonthlyDonation() {
        monthlyDonationDates.append(Date())
    }

    // MARK: - Calculate streaks
    func weeklyStreak() -> Int {
        let calendar = Calendar.current
        let weeks = Set(weeklyDonationDates.map { calendar.component(.weekOfYear, from: $0) })
        return weeks.count
    }

    func monthlyStreak() -> Int {
        let calendar = Calendar.current
        let months = Set(monthlyDonationDates.map { calendar.component(.month, from: $0) })
        return months.count
    }

    // MARK: - Unlock dates
    func unlockDate(for id: Int) -> Date? {
        UserDefaults.standard.object(forKey: "ach_unlock_\(id)") as? Date
    }

    func saveUnlockDateIfNeeded(id: Int) {
        let key = "ach_unlock_\(id)"
        guard UserDefaults.standard.object(forKey: key) == nil,
              let uid = Auth.auth().currentUser?.uid else { return }

        let date = Date()
        UserDefaults.standard.set(date, forKey: key)

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .setData([
                "achievementsUnlocked.\(id)": Timestamp(date: date)
            ], merge: true)
    }

    
    func applyRemoteData(_ data: [String: Any]) {
        donationCount = data["donationCount"] as? Int ?? 0
        mealsProvided = data["mealsProvided"] as? Int ?? 0
        collectionsCompleted = data["collectionsCompleted"] as? Int ?? 0

        if let ngos = data["uniqueNGOs"] as? [String] {
            uniqueNGOs = Set(ngos)
        }

        if let weekly = data["weeklyDonationDates"] as? [Timestamp] {
            weeklyDonationDates = weekly.map { $0.dateValue() }
        }

        if let monthly = data["monthlyDonationDates"] as? [Timestamp] {
            monthlyDonationDates = monthly.map { $0.dateValue() }
        }

        if let unlocks = data["achievementsUnlocked"] as? [String: Timestamp] {
            for (key, value) in unlocks {
                UserDefaults.standard.set(value.dateValue(), forKey: "ach_unlock_\(key)")
            }
        }
    }

}

