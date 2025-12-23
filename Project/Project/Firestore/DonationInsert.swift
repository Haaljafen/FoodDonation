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
            "donorId": "jOUkkHYArvYZvO5WAU0bgtHsqbN2",
            "collectorId": "tmp3A5GbeFMQceAhcsS6j8MJlRI2",

            "item": "banana",
            "quantity": 6,
            "unit": "pcs",

            "manufacturingDate": NSNull(),
            "expiryDate": NSNull(),

            "category": "Fruits",
            "impactType": "Meals Provided",

            "imageUrl": NSNull(),
            "donationMethod": "pickup",

            "status": "pending",

            "pickupRequestId": NSNull(),

            "donorName": "anfal",
            "donorCity": "Muharraq",

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
