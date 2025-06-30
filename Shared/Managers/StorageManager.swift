//
//  StorageManager.swift
//  AuthenticateUser
//
//  Created by Your Name
//

import Foundation
import Supabase
import UIKit

@MainActor
class StorageManager: ObservableObject {
    
    // MARK: - Supabase Client
    private let supabase = SupabaseManager.shared.client
    
    // MARK: - Constants
    private let bucketName = "profile-images"
    private let imageQuality: CGFloat = 0.8
    private let maxImageSize: CGSize = CGSize(width: 1024, height: 1024)
    
    // MARK: - Profile Image Management
    
    /// Uploads a profile image for the current user
    /// - Parameter imageData: The image data to upload
    /// - Returns: The public URL of the uploaded image
    func uploadProfileImage(_ imageData: Data) async throws -> String {
        print("🔄 Starting profile image upload...")
        
        // Get current user
        let currentUser = try await supabase.auth.session.user
        let userId = currentUser.id.uuidString.lowercased()
        
        // Process and compress the image
        let processedImageData = try processImageData(imageData)
        
        // Create file path: userId/profile.jpg
        let fileName = "\(userId)/profile.jpg"
        print("📁 Upload path: \(fileName)")
        
        do {
            // Upload to Supabase storage
            try await supabase.storage
                .from(bucketName)
                .upload(
                    fileName,
                    data: processedImageData,
                    options: FileOptions(
                        contentType: "image/jpeg",
                        upsert: true // Allow overwriting existing profile image
                    )
                )
            
            print("✅ Successfully uploaded to bucket '\(bucketName)'")
            
            // Get the public URL
            let publicURL = try supabase.storage
                .from(bucketName)
                .getPublicURL(path: fileName)
            
            print("🔗 Public URL: \(publicURL)")
            return publicURL.absoluteString
            
        } catch {
            print("❌ Storage upload error: \(error)")
            throw StorageError.uploadFailed(error.localizedDescription)
        }
    }
    
    /// Downloads profile image data for a given URL
    /// - Parameter url: The URL of the profile image
    /// - Returns: The image data
    func downloadProfileImage(from url: String) async throws -> Data {
        guard let imageURL = URL(string: url) else {
            throw StorageError.invalidURL
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            return data
        } catch {
            print("❌ Failed to download image from \(url): \(error)")
            throw StorageError.downloadFailed(error.localizedDescription)
        }
    }
    
    /// Deletes the profile image for the current user
    func deleteProfileImage() async throws {
        let currentUser = try await supabase.auth.session.user
        let userId = currentUser.id.uuidString.lowercased()
        let fileName = "\(userId)/profile.jpg"
        
        do {
            try await supabase.storage
                .from(bucketName)
                .remove(paths: [fileName])
            
            print("✅ Successfully deleted profile image")
        } catch {
            print("❌ Failed to delete profile image: \(error)")
            throw StorageError.deleteFailed(error.localizedDescription)
        }
    }
    
    /// Gets the public URL for the current user's profile image
    /// - Returns: The public URL if the image exists, nil otherwise
    func getCurrentUserProfileImageURL() async -> String? {
        do {
            let currentUser = try await supabase.auth.session.user
            let userId = currentUser.id.uuidString.lowercased()
            let fileName = "\(userId)/profile.jpg"
            
            // Check if file exists by trying to get its public URL
            let publicURL = try supabase.storage
                .from(bucketName)
                .getPublicURL(path: fileName)
            
            return publicURL.absoluteString
        } catch {
            print("⚠️ Could not get profile image URL: \(error)")
            return nil
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Processes and compresses image data to optimize for storage
    /// - Parameter imageData: Original image data
    /// - Returns: Processed image data
    private func processImageData(_ imageData: Data) throws -> Data {
        guard let image = UIImage(data: imageData) else {
            throw StorageError.invalidImageData
        }
        
        // Resize image if needed
        let resizedImage = image.resized(to: maxImageSize)
        
        // Convert to JPEG with compression
        guard let compressedData = resizedImage.jpegData(compressionQuality: imageQuality) else {
            throw StorageError.compressionFailed
        }
        
        print("📦 Original size: \(imageData.count) bytes, Compressed size: \(compressedData.count) bytes")
        
        return compressedData
    }
}

// MARK: - Storage Error Types

enum StorageError: LocalizedError {
    case uploadFailed(String)
    case downloadFailed(String)
    case deleteFailed(String)
    case invalidURL
    case invalidImageData
    case compressionFailed
    
    var errorDescription: String? {
        switch self {
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        case .deleteFailed(let message):
            return "Delete failed: \(message)"
        case .invalidURL:
            return "Invalid image URL"
        case .invalidImageData:
            return "Invalid image data"
        case .compressionFailed:
            return "Failed to compress image"
        }
    }
}

// MARK: - UIImage Extension for Resizing

extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        // Determine the scale factor that preserves aspect ratio
        let scaleFactor = min(widthRatio, heightRatio)
        
        // Only resize if the image is larger than target
        guard scaleFactor < 1.0 else { return self }
        
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        
        let renderer = UIGraphicsImageRenderer(size: scaledImageSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: scaledImageSize))
        }
    }
}