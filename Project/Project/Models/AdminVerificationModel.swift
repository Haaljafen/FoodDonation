//
//  AdminVerificationModel.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 30/11/2025.
//

import Foundation
import FirebaseFirestore

struct AdminVerification: Codable {
    let ngoId: String
    let status: UserStatus
    
    let reviewedBy: String?
    let reviewedAt: Date?
    let adminNotes: String?
}
