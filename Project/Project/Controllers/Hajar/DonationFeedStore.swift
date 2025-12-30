import Foundation

extension Notification.Name {
    static let donationAdded = Notification.Name("donationAdded")
}

/// In-memory store to share the donation feed between screens.
/// (Great for demo now. Later replace with Firestore / API.)
final class DonationFeedStore {
    static let shared = DonationFeedStore()

    private(set) var items: [DonationItem] = [
        DonationItem(
            category: "Meals",
            name: "Grape leaves",
            quantity: "24 pieces",
            location: "Hamad Town",
            expiryDate: "11 Nov 2025",
            donorName: "Hajar",
            imageURL: "https://res.cloudinary.com/dquu356xs/image/upload/w_300,h_250,c_fill,q_auto,f_auto/grape_leaves"
        ),
                DonationItem(
                    category: "Beverages",
                    name: "Juices",
                    quantity: "9 bottles",
                    location: "Riffa",
                    expiryDate: "11 Nov 2025",
                    donorName: "Safa",
                    imageURL: "https://res.cloudinary.com/dquu356xs/image/upload/v1766447000/juice.png"
                ),
                DonationItem(
                    category: "Bakery",
                    name: "Bakery box",
                    quantity: "12 items",
                    location: "Isa Town",
                    expiryDate: "11 Nov 2025",
                    donorName: "Noor",
                    imageURL: "https://res.cloudinary.com/dquu356xs/image/upload/v1766447000/donuts_box.png"
                )
            
    ]

    private init() {}

    func add(_ item: DonationItem) {
        items.insert(item, at: 0) // newest first
        NotificationCenter.default.post(name: .donationAdded, object: item)
    }
}
