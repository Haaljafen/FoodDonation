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
            "id": donationId,
            "donorId": "ij0OTAo2nASJ1Zk6lr9U8buRJ412",
            "collectorId": "tmp3A5GbeFMQceAhcsS6j8MJlRI2",

            "item": "pasts",
            "quantity": 12,
            "unit": "pcs",

            "manufacturingDate": NSNull(),
            "expiryDate": "10/04/2027",

            "category": "Cooked Meals",
            "impactType": "Meals Provided",

            "imageUrl": "https://res.cloudinary.com/dquu356xs/image/upload/v1765719626/qgcfxotbtwj4psxh6fjm.jpg",
            "donationMethod": "locationPickup",

            "status": "delivered",

            "pickupRequestId": NSNull(),

            "donorName": "Sarah",
            "donorCity": "Manama",

            "createdAt": Timestamp(date: Date())
        ]

        db.collection("donations")
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
