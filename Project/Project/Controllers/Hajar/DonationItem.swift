import Foundation

struct DonationItem {
    let id: String
    let donorId: String

    let category: String
    let name: String
    let quantity: String
    let location: String
    let expiryDate: String
    let donorName: String
    let imageURL: String

    // optional (useful for detail screen)
    let donationMethod: String?
    let impactType: String?
}
