//
//  DonationModel.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 30/11/2025.
//

import Foundation
import FirebaseFirestore

struct Donation: Codable {
    let id: String
    let donorId: String
    let collectorId: String?
    
    let item: String
    let quantity: Int
    let unit: String
    
    let manufacturingDate: Date?
    let expiryDate: Date?
    
    let category: DonationCategory
    let impactType: DonationType
    
    let imageUrl: String
    let donationMethod: DonationMethod
    
    let status: DonationStatus
    
    // Pickup request reference
    let pickupRequestId: String?
    
    // For fast listing
    let donorName: String?
    let donorCity: String?
    
    let createdAt: Date
}
