//
//  AssetCachingManager.swift
//  AlleTask
//
//  Created by V!jay on 06/12/24.
//

import Foundation
import Photos

// MARK: - AssetCachingManager

/// A utility class for managing image caching using `PHCachingImageManager`.
/// Handles the preloading of thumbnail and enlarged images for `PHAsset` to improve performance.
class AssetCachingManager {
    
    // MARK: - Properties
    
    /// The caching manager provided by `Photos` framework for efficient image retrieval.
    private let cachingManager = PHCachingImageManager()
    
    // MARK: - Public Methods
    
    /// Starts caching thumbnail-sized images for the given assets.
    ///
    /// - Parameters:
    ///   - assets: An array of `PHAsset` objects to be cached.
    ///   - targetSize: The target size for the cached thumbnails.
    ///   - contentMode: The mode for displaying the image (usually `.aspectFill` for thumbnails).
    func startCachingThumbnails(for assets: [PHAsset], targetSize: CGSize, contentMode: PHImageContentMode) {
        cachingManager.startCachingImages(for: assets, targetSize: targetSize, contentMode: .aspectFill, options: nil)
    }
    
    /// Starts caching enlarged-sized images for the given assets.
    ///
    /// - Parameters:
    ///   - assets: An array of `PHAsset` objects to be cached.
    ///   - targetSize: The target size for the cached enlarged images.
    ///   - contentMode: The mode for displaying the image (usually `.aspectFit` for enlarged views).
    func startCachingEnlarged(for assets: [PHAsset], targetSize: CGSize, contentMode: PHImageContentMode) {
        cachingManager.startCachingImages(for: assets, targetSize: targetSize, contentMode: .aspectFit, options: nil)
    }
}
