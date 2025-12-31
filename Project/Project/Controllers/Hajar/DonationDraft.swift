import Foundation

struct DonationDraft {
    let id: String
    let donorId: String
    let item: String
    let quantity: Int
    let unit: String
    let manufacturingDate: Date?
    let expiryDate: Date?
    let category: DonationCategory
    let impactType: DonationType
    var imageUrl: String
    let donorName: String?
    let donorCity: String?
}
