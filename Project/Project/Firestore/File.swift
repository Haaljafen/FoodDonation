//
//  File.swift
//  Takaffal
//
//  Created by Noora Humaid on 31/12/2025.
//

import Foundation
import FirebaseFirestore

func createPickupRequest() {

    let db = Firestore.firestore()
    let pickupId = UUID().uuidString
    let pickupRequestData: [String: Any] = [

        // Required
        "donationId": "pbMwtpX7pMXU7orppD1jNLRiL4C2",
        "id": pickupId,
        "method": "locationPickup",

        // Pickup info
        "pickupAddress": "Saar 1234, street 2578",
        "pickupCity": "manama",
        "pickupCountry": "bahrain",
        "pickupDateTime": Timestamp(date: Date(timeIntervalSince1970: 1839960600)), // example

        // Dropoff (null)
        "dropoffDate": "30/08/2027",
        "dropoffTime": "8:00AM",
        "facilityName": "kaff",

        // Meta
        "scheduledAt": Timestamp(date: Date())
    ]

    db.collection("PickupRequests")
        .document("fnOyEdfiuV2Xyj5QfdMj") // optional: use your own ID
        .setData(pickupRequestData) { error in

            if let error = error {
                print("❌ Error creating PickupRequest:", error.localizedDescription)
            } else {
                print("✅ PickupRequest successfully created")
            }
        }
}
