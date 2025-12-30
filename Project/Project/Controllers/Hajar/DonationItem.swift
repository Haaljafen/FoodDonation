import Foundation

/// Lightweight UI model used by the NGO listing table (DonationCell).
/// Keep this separate from the Firestore `Donation` model to make UI wiring easy.
struct DonationItem {
    let category: String
    let name: String
    let quantity: String
    let location: String
    let expiryDate: String
    let donorName: String
    let imageURL: String
}
