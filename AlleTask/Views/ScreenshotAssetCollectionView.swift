//
//  ScreenshotAssetCollectionView.swift
//  AlleTask
//
//  Created by V!jay on 04/12/24.
//

import UIKit
import Photos

// MARK: - ViewType Enum

/// Defines the type of the view for the collection view.
enum ViewType {
    case enlarged
    case thumbnail
}

// MARK: - ScreenShotViewDelegate Protocol

/// Delegate protocol for handling collection view actions.
protocol ScreenShotViewDelegate  : NSObject {
    /// Called when an item in the collection view is clicked.
    func didCollectionViewClicked (indexPath : IndexPath)
    
    /// Called when the collection view is being scrolled.
    func didCollectionViewScrolled (indexPath : IndexPath, collectionView : UICollectionView)
    
    /// Called when scrolling in the collection view ends.
    func didCollectionViewScrollEnded (indexPath : IndexPath, collectionView : UICollectionView)
    
    /// Called when the collection view's data is updated with a single item or no items.
    func didCollectionViewHasSingleData(_ count : Int)
}

// MARK: - ScreenshotAssetCollectionView

/// Custom collection view for displaying screenshots in thumbnail or enlarged views.
class ScreenshotAssetCollectionView: UICollectionView {
    
    // MARK: - Properties
    
    private var assetModel : ScreenshotAssetsViewModel
    private var screenshotDataSource : UICollectionViewDiffableDataSource<Int, PHAsset>!
    private var viewType : ViewType
    weak var collectionViewDelegate : ScreenShotViewDelegate?
    let cachingManager = PHCachingImageManager()
    // MARK: - Initialization
    
    /// Initializes the custom collection view with the given layout and view type.
    init(collectionViewLayout layout: UICollectionViewLayout, viewType : ViewType = .thumbnail) {
        assetModel = ScreenshotAssetsViewModel()
        self.viewType = viewType
        super.init(frame: .zero, collectionViewLayout: layout)
        
        setupCollectionView()
        loadScreenshotsFromModel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    /// Configures the collection view's delegate, data source, and appearance.
    private func setupCollectionView () {
        delegate = self
        self.register(ScreenShotCollectionCell.self, forCellWithReuseIdentifier: "screenshotCell")
        
        setDataSource()
    }
    
    /// Loads screenshots from the ViewModel and updates the collection view.
    private func loadScreenshotsFromModel () {
        assetModel.fetchScreenshotsFromPhotoLibrary { [weak self] status in
            guard let self = self else { return }
            switch status {
            case .success(let newAssets):
                self.updateSnapshot(with: newAssets)
                self.collectionViewDelegate?.didCollectionViewHasSingleData(self.assetModel.allAssets?.count ?? 0)
            case .failure(let error):
                self.collectionViewDelegate?.didCollectionViewHasSingleData(0)
                print("No data: \(error)")
            }
        }
    }
    
    /// Updates the diffable data source snapshot with new assets.
    /// - Parameter newAssets: Array of `PHAsset` objects to be added to the collection view.
    func updateSnapshot(with newAssets: [PHAsset]) {
        DispatchQueue.global(qos: .userInitiated).async {
            var snapshot = self.screenshotDataSource.snapshot()
            let existingItems = Set(snapshot.itemIdentifiers)
            
            // Filter new assets to exclude duplicates
            let filteredAssets = newAssets.filter { !existingItems.contains($0) }
            
            if snapshot.sectionIdentifiers.isEmpty {
                snapshot.appendSections([0])
            }
            
            snapshot.appendItems(filteredAssets)
            DispatchQueue.main.async {
                self.screenshotDataSource.apply(snapshot, animatingDifferences: false)
            }
        }
    }
}

// MARK: - Data Source Setup
extension ScreenshotAssetCollectionView  {
    
    /// Configures the diffable data source for the collection view.
    private func setDataSource () {
        screenshotDataSource = UICollectionViewDiffableDataSource(collectionView: self, cellProvider: { collectionView, indexPath, imageAsset in
            guard let screenshotCell = collectionView.dequeueReusableCell(withReuseIdentifier: "screenshotCell", for: indexPath) as? ScreenShotCollectionCell else {
                fatalError("Could not deque cell")
            }
            
            screenshotCell.configureCell(imageAsset, self.viewType)
            return screenshotCell
        })
    }
}

// MARK: - UICollectionViewDelegate

extension ScreenshotAssetCollectionView : UICollectionViewDelegate {
    /// Handles item selection in the collection view.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionViewDelegate?.didCollectionViewClicked(indexPath: indexPath)
    }
}

// MARK: - UIScrollViewDelegate

extension ScreenshotAssetCollectionView: UIScrollViewDelegate {
    /// Called when the scroll view ends decelerating.
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let collectionView = scrollView as? UICollectionView, viewType == .enlarged {
            let pageIndex = Int(scrollView.contentOffset.x / scrollView.frame.width)
            let indexPath = IndexPath(row: pageIndex, section: 0)
            
            collectionViewDelegate?.didCollectionViewScrollEnded(indexPath: indexPath, collectionView: collectionView)
        }
    }
    
    /// Called when the scroll view is scrolling.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let collectionView = scrollView as? UICollectionView else { return }
        
        if viewType == .thumbnail {
            // Calculate the center X of the visible collection view
            let centerX = scrollView.contentOffset.x + (scrollView.bounds.width / 2)
            let centerPoint = CGPoint(x: centerX, y: scrollView.bounds.height / 2)
            
            // Find the closest cell to the center
            if let closestIndexPath = collectionView.indexPathForItem(at: centerPoint) {
                collectionViewDelegate?.didCollectionViewScrolled(indexPath: closestIndexPath, collectionView: collectionView)
            }
        }
    }
}

