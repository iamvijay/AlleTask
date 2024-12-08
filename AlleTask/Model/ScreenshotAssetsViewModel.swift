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
    private let batchSize = Constants.batchSize
    private let thumbnailSize = CGSize(width: Constants.thumbnailItemWidth, height: Constants.thumbnailHeight)
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
            // If all assets are processed, complete the process
            guard currentOffset < totalAssets else {
                completion(.success(screenShots)) // Notify when all batches are processed
                return
            }
            
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
            
            // Continue to the next batch after a short delay
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                processBatch() // Call processBatch recursively
            }
        }
        
        processBatch() // Start the first batch
    }
    
    /// Starts caching images for both thumbnail and enlarged sizes.
    ///
    /// - Parameter assets: Array of `PHAsset` to be cached.
    private func startCaching(for assets: [PHAsset]) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.cachingManager.startCachingAssets(for: assets, targetSize: self?.thumbnailSize ?? CGSize(width: 0, height: 0), contentMode: PHImageContentMode.aspectFill)
        }
    }
}
