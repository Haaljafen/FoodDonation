//
//  AchievementModel.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 30/11/2025.
//

import Foundation
import FirebaseFirestore

struct Achievement: Codable {
    let id: String
    let title: String
    let description: String
    let iconUrl: String?
    
    let isUnlocked: Bool
    let unlockedAt: Date?
    
    let progress: Int?
    let goal: Int?
}
