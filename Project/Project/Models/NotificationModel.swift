//
//  NotificationModel.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 30/11/2025.
//

import Foundation
import FirebaseFirestore


struct NotificationModel: Codable {
    let id: String
    let userId: String
    
    let title: String
    let message: String
    
    let createdAt: Date
    let isRead: Bool
}
