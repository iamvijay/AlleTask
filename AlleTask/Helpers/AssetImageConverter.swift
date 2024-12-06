//
//  AssetImageConverter.swift
//  AlleTask
//
//  Created by V!jay on 04/12/24.
//

import Foundation
import Photos
import UIKit

// MARK: - AssetImageConverter

/// A utility class for converting `PHAsset` to `UIImage` using the `PHCachingImageManager`.
/// Provides optimized image fetching based on the view type (enlarged or thumbnail).
class AssetImageConverter {
    // MARK: - Properties
    
    private static let cachingManager = PHCachingImageManager()
    
    // MARK: - Public Methods
    
    /// Converts a `PHAsset` to a `UIImage` with size and format based on the provided view type.
    ///
    /// - Parameters:
    ///   - asset: The `PHAsset` to be converted into an image.
    ///   - viewType: The type of view (`enlarged` or `thumbnail`) to determine image size and format.
    ///   - completion: A closure that returns the resulting `UIImage` or `nil` if the conversion fails.
    static func assetToImageConverter(
        asset: PHAsset,
        viewType: ViewType,
        completion: @escaping (UIImage?) -> Void
    ) {
        let itemSize = targetSize(for: viewType)
        let contentMode: PHImageContentMode = viewType == .enlarged ? .aspectFit : .aspectFill
        
        // Configure image request options
        let options = PHImageRequestOptions()
        options.deliveryMode = viewType == .enlarged ? .highQualityFormat : .fastFormat
        
        // Use the caching manager to fetch the preloaded image
        cachingManager.requestImage(
            for: asset,
            targetSize: itemSize,
            contentMode: contentMode,
            options: options
        ) { image, _ in
            completion(image)
        }
    }
    
    /// Returns the target size for the image based on the view type.
    /// - Parameter viewType: The type of view (`enlarged` or `thumbnail`).
    /// - Returns: The size of the image for the specified view type.
    private static func targetSize(for viewType: ViewType) -> CGSize {
        return viewType == .enlarged
        ? CGSize(width: UIScreen.main.bounds.width * UIScreen.main.scale, height: UIScreen.main.bounds.height * UIScreen.main.scale)
        : CGSize(width: 50, height: 70)
    }
}

