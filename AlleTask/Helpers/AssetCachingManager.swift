//
//  AssetCachingManager.swift
//  AlleTask
//
//  Created by V!jay on 06/12/24.
//

import Foundation
import Photos
import UIKit

// MARK: - AssetCachingManager

/// A utility class for managing image caching using `PHCachingImageManager`.
/// Handles the preloading of thumbnail and enlarged images for `PHAsset` to improve performance.
class AssetCachingManager {
    
    // MARK: - Properties
    
    /// The caching manager provided by `Photos` framework for efficient image retrieval.
    private let cachingManager = PHCachingImageManager()
    
    // MARK: - Public Methods
    
    /// Starts caching  images for the given assets.
    ///
    /// - Parameters:
    ///   - assets: An array of `PHAsset` objects to be cached.
    ///   - targetSize: The target size for the cached  images.
    ///   - contentMode: The mode for displaying the image (usually `.aspectFill` for enlarged views).
    func startCachingAssets(for assets: [PHAsset], targetSize: CGSize, contentMode: PHImageContentMode) {
        cachingManager.startCachingImages(for: assets, targetSize: targetSize, contentMode: contentMode, options: nil)
    }
}


class ImageCacheManager {
    private let cache = NSCache<NSString, UIImage>()
    static let shared = ImageCacheManager() // Singleton instance

    private init() {
        cache.countLimit = 50 // Limit to 50 images
        cache.totalCostLimit = 50 * 1024 * 1024 // Limit to 50 MB
    }

    func getCachedImage(for key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }

    func cacheImage(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}
