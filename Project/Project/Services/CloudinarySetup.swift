//
//  CloudinarySetup.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 26/11/2025.
//

import Foundation
import Cloudinary
import UIKit

final class CloudinaryService {
    static let shared = CloudinaryService()
    
    private let cloudinary: CLDCloudinary
    private let cloudName = "dquu356xs"
    private let uploadPreset = "ios_dev"


    private init() {
        let config = CLDConfiguration(cloudName: cloudName, secure: true)
        self.cloudinary = CLDCloudinary(configuration: config)
    }
    
    func upload(image: UIImage,
                completion: @escaping (Result<String, Error>) -> Void) {
        
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            let err = NSError(domain: "CloudinaryService",
                              code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Could not convert image to JPEG"])
            completion(.failure(err))
            return
        }
        
        let params = CLDUploadRequestParams()
        params.setUploadPreset(uploadPreset)
        
        cloudinary.createUploader().upload(
            data: data,
            uploadPreset: uploadPreset,
            params: params,
            progress: nil
        ) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let url = result?.secureUrl {
                completion(.success(url))
            } else {
                let err = NSError(domain: "CloudinaryService",
                                  code: -2,
                                  userInfo: [NSLocalizedDescriptionKey: "No URL returned from Cloudinary"])
                completion(.failure(err))
            }
        }
    }
}
