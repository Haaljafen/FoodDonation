//
//  AdminImpact.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 01/12/2025.
//

import Foundation
import FirebaseFirestore

struct AdminImpact: Codable {
    let totalVolunteers: Int
    let totalDonors: Int
    let totalNGOs: Int
    let totalBeneficiaries: Int
    
    let monthlyDonations: [String: Int]
    
    let updatedAt: Date
}
