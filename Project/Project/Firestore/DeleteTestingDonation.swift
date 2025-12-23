//
//  DeleteTestingDonation.swift
//  Takaffal
//
//  Created by Noora Humaid on 23/12/2025.
//

import Foundation
import FirebaseFirestore

func deleteDonation(donationId: String) {
    let db = Firestore.firestore()

    db.collection("donations").document(donationId).delete { error in
        if let error = error {
            print("❌ Error deleting donation:", error.localizedDescription)
        } else {
            print("✅ Donation successfully deleted")
        }
    }
}

