//
//  DonationInsert.swift
//  Takaffal
//
//  Created by Noora Humaid on 19/12/2025.
//

import Foundation
import FirebaseFirestore

final class DonationInsert {

    static func insertDonation() {

        let db = Firestore.firestore()
        let donationId = UUID().uuidString

        let data: [String: Any] = [
            "id": donationId,
            "donorId": "7yfpJrFgU3YfH1vm8CiGRpwjpjj2",
            "collectorId": "ZwGkvR1MoCMS6UV6jY9qDO0OcZX2",

            "item": "cookies",
            "quantity": 24,
            "unit": "pcs",

            "manufacturingDate": NSNull(),
            "expiryDate": "12/5/2027",

            "category": "Cooked Meals",
            "impactType": "mealsProvided",

            "imageUrl": "https://example.com/grapeleaves.jpg",
            "donationMethod": "dropoff",

            "status": "pending",

            "pickupRequestId": NSNull(),

            "donorName": "Noora Humaid",
            "donorCity": "Muharaq",

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
