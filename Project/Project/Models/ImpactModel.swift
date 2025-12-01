//
//  ImpactModel.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 30/11/2025.
//

import Foundation
import FirebaseFirestore

struct ImpactStats: Codable {
    let userId: String
    
    // Donor stats
    let totalDonations: Int
    let totalMealsProvided: Int
    let totalWastePrevented: Int
    let totalBeneficiaries: Int
    
    // NGO/Collector stats
    let donationsAccepted: Int
    let donationsPicked: Int
    let donationsDelivered: Int
    let donationsOngoing: Int
    
    // Monthly activity for charts
    let monthlyDonations: [String: Int]
    
    // Achievements (Donor only)
    let achievementsUnlocked: [String]
    let achievementsProgress: [String: Int]
    
    let updatedAt: Date
}
