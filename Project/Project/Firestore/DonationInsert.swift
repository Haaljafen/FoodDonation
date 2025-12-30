//
//  DonationInsert.swift
//  Takaffal
//
//  Created by Noora Humaid on 19/12/2025.
//

import Foundation
import FirebaseFirestore

final class DonationInsert {

    static func insertTestDonation() {

        let db = Firestore.firestore()
        let donationId = UUID().uuidString

        let data: [String: Any] = [
            "id": "donationTest123",
            "donorId": "ij0OTAo2nASJ1Zk6lr9U8buRJ412",
            "collectorId": "tmp3A5GbeFMQceAhcsS6j8MJlRI2",

            "item": "pizza",
            "quantity": 12,
            "unit": "pcs",

            "manufacturingDate": NSNull(),
            "expiryDate": "18/04/2027",

            "category": "Cooked Meals",
            "impactType": "Meals Provided",

            "imageUrl": "https://res.cloudinary.com/dquu356xs/image/upload/v1766880277/xjd3de2fplwarcvx2ad7.jpg",
            "donationMethod": "locationPickup",

            "status": "accepted",

            "pickupRequestId": "pickupTest123",

            "donorName": "Sarah",
            "donorCity": "Manama",

            "createdAt": Timestamp(date: Date())
        ]

        db.collection("Donations")
            .document(donationId)
            .setData(data) { error in
                if let error = error {
                    print("❌ Firestore insert error:", error.localizedDescription)
                } else {
                    print("✅ Donation inserted successfully")
                }
            }
    }
}
