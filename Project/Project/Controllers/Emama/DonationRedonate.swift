//
//  DonationRedonate.swift
//  Takaffal
//
//  Created by Noora Humaid on 31/12/2025.
//

import Foundation
import FirebaseFirestore

final class DonationRedonate {

    static func redonate(
        from donation: [String: Any],
        completion: @escaping (Bool) -> Void
    ) {

        let db = Firestore.firestore()
        let newDonationId = UUID().uuidString

        guard
            let donorId = donation["donorId"] as? String,
            let item = donation["item"] as? String,
            let quantity = donation["quantity"],
            let unit = donation["unit"] as? String,
            let category = donation["category"] as? String,
            let donationMethod = donation["donationMethod"] as? String,
            let impactType = donation["impactType"] as? String,
            let originalDonationId = donation["id"] as? String
        else {
            print("❌ Missing required donation fields")
            completion(false)
            return
        }

        let newDonationData: [String: Any] = [
            "id": newDonationId,
            "donorId": donorId,
            "collectorId": donation["collectorId"] ?? "",
            "item": item,
            "quantity": quantity,
            "unit": unit,
            "expiryDate": donation["expiryDate"] ?? "",
            "category": category,
            "impactType": impactType,
            "donationMethod": donationMethod,

            // Re‑donation metadata
            "status": "pending",
            "isRedonation": true,
            "originalDonationId": originalDonationId,
            "createdAt": Timestamp(date: Date())
        ]

        db.collection("Donations")
            .document(newDonationId)
            .setData(newDonationData) { error in
                if let error = error {
                    print("❌ Re-donation failed:", error.localizedDescription)
                    completion(false)
                } else {
                    print("✅ Re-donation successful")
                    completion(true)
                }
            }
    }
}
