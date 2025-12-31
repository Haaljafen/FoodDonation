//
//  DeleteTestingDonation.swift
//  Takaffal
//
//  Created by Noora Humaid on 23/12/2025.
//

import Foundation
import FirebaseFirestore

func deleteDonations(by donationIds: [String]) {
    let db = Firestore.firestore()
    let batch = db.batch()

    db.collection("donations")
        .whereField("id", in: donationIds)
        .getDocuments { snapshot, error in

            if let error = error {
                print("❌ Query error:", error.localizedDescription)
                return
            }

            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("⚠️ No matching donations found")
                return
            }

            documents.forEach { doc in
                batch.deleteDocument(doc.reference)
            }

            batch.commit { error in
                if let error = error {
                    print("❌ Batch delete failed:", error.localizedDescription)
                } else {
                    print("✅ Multiple donations deleted successfully")
                }
            }
        }
}


