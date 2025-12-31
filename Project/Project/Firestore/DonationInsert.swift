//
//  DonationInsert.swift
//  Takaffal
//
//  Created by Noora Humaid on 19/12/2025.
//

import Foundation
import FirebaseFirestore

final class DonationInsert {

    static func insertMultipleDonationsIndividually() {

        let db = Firestore.firestore()

        let items = ["pizza", "sandwiches", "rice boxes"]
        let methods = ["dropoff", "locationPickup", "dropoff"]
        let impacts = ["Meals Provided", "Other", "Waste Prevented"]

        // Safety check
        guard items.count == methods.count,
              items.count == impacts.count else {
            print("❌ Arrays count mismatch")
            return
        }

        for index in items.indices {

            let donationId = UUID().uuidString

            let data: [String: Any] = [
                "id": donationId,
                "donorId": "pbMwtpX7pMXU7orppD1jNLRiL4C2",
                "collectorId": "swM6gGUOCLbsnQ3puuL4oTjSaBn2",

                "item": items[index],
                "quantity": 10,
                "unit": "pcs",
                "expiryDate": "18/04/2027",
                "category": "Cooked Meals",

                // ✅ Correct: single values
                "impactType": impacts[index],
                "donationMethod": methods[index],

                "status": "accepted",
                "createdAt": Timestamp(date: Date())
            ]

            db.collection("Donations")
                .document(donationId)
                .setData(data) { error in
                    if let error = error {
                        print("❌ Failed for \(items[index]):", error.localizedDescription)
                    } else {
                        print("✅ Inserted \(items[index])")
                    }
                }
        }
    }
}
