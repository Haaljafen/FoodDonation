//
//  UserModel.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 30/11/2025.
//

import Foundation
import FirebaseFirestore

struct User: Codable {
    let id: String
    let role: UserRole
    
    // Common fields
    let email: String
    let phone: String
    let country: String
    let city: String
    let address: String
    let profileImageUrl: String?
    let createdAt: Date
    
    // Donor fields
    let username: String?
    
    // NGO fields
    let organizationName: String?
    let mission: String?
    let about: String?
    let logoUrl: String?
    
    // Admin verification for NGOs
    let status: UserStatus?
    let verified: Bool?
}
