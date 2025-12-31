import Foundation

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
        if UserDefaults.standard.object(forKey: key) == nil {
            UserDefaults.standard.set(Date(), forKey: key)
        }
    }
}
