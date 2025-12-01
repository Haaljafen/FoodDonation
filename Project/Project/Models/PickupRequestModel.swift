//
//  PickupRequestModel.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 30/11/2025.
//

import Foundation
import FirebaseFirestore

struct PickupRequest: Codable {
    let id: String
    let donationId: String
    let method: String
    
    // Drop-off
    let facilityName: String?
    let dropoffDate: Date?
    let dropoffTime: String?
    
    // Location pickup
    let pickupAddress: String?
    let pickupCity: String?
    let pickupCountry: String?
    let pickupDateTime: Date?
    
    let scheduledAt: Date
}
