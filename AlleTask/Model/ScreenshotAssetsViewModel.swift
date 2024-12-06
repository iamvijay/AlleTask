//
//  ScreenshotAssetsViewModel.swift
//  AlleTask
//
//  Created by V!jay on 04/12/24.
//

import Foundation
import Photos
import UIKit

// MARK: - Status Enum

/// Represents the result of fetching assets from the photo library.
enum Result {
    case success([PHAsset])
    case failure(String)
}

// MARK: - ScreenshotAssetsViewModel

/// ViewModel responsible for fetching and managing screenshot assets from the photo library.
class ScreenshotAssetsViewModel {
    
    // MARK: - Properties
    private let cachingManager = AssetCachingManager() // Caching manager
    private var screenShots: [PHAsset] = []
    private(set) var allAssets: PHFetchResult<PHAsset>?
    private var currentOffset = 0
    private let batchSize = 20
    private let thumbnailSize = CGSize(width: 40, height: 60)
    private let enlargedSize = CGSize(width: UIScreen.main.bounds.width * UIScreen.main.scale,
                                      height: UIScreen.main.bounds.height * UIScreen.main.scale)
    
    // MARK: - Public Methods
    
    /// Fetches screenshot assets from the photo library with authorization.
    ///
    /// - Parameter completion: A closure called with a `Status` result containing fetched assets or an error message.
    func fetchScreenshotsFromPhotoLibrary(completion: @escaping (Result) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                completion(.failure("Authorization failed"))
                return
            }
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaSubtype == %d", PHAssetMediaSubtype.photoScreenshot.rawValue)
            
            self.allAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            self.currentOffset = 0 // Reset offset
            self.screenShots = []  // Clear previous data
            self.sendBatchbyBatch(completion: completion)
        }
    }
    
    // MARK: - Private Methods
    
    /// Fetches the next batch of screenshot assets in a paginated manner.
    ///
    /// - Parameter completion: A closure called with a `Result` result containing the fetched assets or an error message.
    private func sendBatchbyBatch(completion: @escaping (Result) -> Void) {
        guard let allAssets = allAssets else {
            completion(.failure("No assets available"))
            return
        }
        
        let totalAssets = allAssets.count
        
        func processBatch() {
            let endOffset = min(currentOffset + batchSize, totalAssets)
            let newAssets = (currentOffset..<endOffset).map { allAssets.object(at: $0) }
            currentOffset = endOffset
            
            // Append the new batch to the stored assets
            screenShots.append(contentsOf: newAssets)
            
            // Start caching images for the new assets
            startCaching(for: newAssets)
            
            // Notify the completion handler with the new assets
            DispatchQueue.main.async {
                completion(.success(newAssets))
            }
        }
        processBatch() // Start the first batch
    }
    
    /// Starts caching images for both thumbnail and enlarged sizes.
    ///
    /// - Parameter assets: Array of `PHAsset` to be cached.
    private func startCaching(for assets: [PHAsset]) {
        cachingManager.startCachingThumbnails(for: assets, targetSize: thumbnailSize, contentMode: PHImageContentMode.aspectFill)
        
        // Cache enlarged images after a slight delay to optimize performance
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.cachingManager.startCachingEnlarged(for: assets, targetSize: self?.enlargedSize ?? CGSize(width: 0, height: 0), contentMode: PHImageContentMode.aspectFit)
        }
    }
}
