//
//  ScreenShotCollectionCell.swift
//  AlleTask
//
//  Created by V!jay on 04/12/24.
//

import UIKit
import Photos

// MARK: - ScreenShotCollectionCell

/// A custom collection view cell for displaying screenshot images.
class ScreenShotCollectionCell: UICollectionViewCell {
    // MARK: - Properties
    
    private let screenshotImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        
        return imageView
    }()
    
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    
    /// Configures the cell's layout and appearance.
    private func setupUI() {
        contentView.backgroundColor = .black
        screenshotImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(screenshotImageView)
        
        NSLayoutConstraint.activate([
            screenshotImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            screenshotImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            screenshotImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            screenshotImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    // MARK: - Configuration
    
    /// Configures the cell with a given screenshot asset and view type.
    ///
    /// - Parameters:
    ///   - asset: The `PHAsset` representing the screenshot.
    ///   - viewType: The type of view (enlarged or thumbnail).
    func configureCell(_ asset: PHAsset, _ viewType: ViewType) {
        screenshotImageView.contentMode = viewType == .enlarged ? .scaleAspectFit : .scaleAspectFill
        screenshotImageView.layer.cornerRadius = viewType == .enlarged ? 0 : 6
        
        AssetImageConverter.assetToImageConverter(asset: asset, viewType: viewType) { [weak self] image in
            DispatchQueue.main.async {
                self?.screenshotImageView.image = image
            }
        }
    }
}

// MARK: - CenterTransformFlowLayout

/// A custom flow layout that applies a scaling transform to the center cell of the collection view.
class CenterTransformFlowLayout: UICollectionViewFlowLayout {
    // MARK: - Layout Adjustment
    
    /// Applies a scaling transformation to the center cell for a zoom effect.
    ///
    /// - Parameter rect: The visible rectangle of the collection view.
    /// - Returns: An array of layout attributes with applied transformations.
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }
        let centerX = collectionView!.contentOffset.x + collectionView!.bounds.width / 2
        
        for attribute in attributes {
            let distance = abs(centerX - attribute.center.x)
            let scale = max(1 - distance / collectionView!.bounds.width, 0.8) // Adjust scaling factor
            attribute.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
        return attributes
    }
    
    /// Determines whether the layout should be invalidated for bounds changes (e.g., scrolling).
    ///
    /// - Parameter newBounds: The new bounds of the collection view.
    /// - Returns: `true` to invalidate the layout, allowing recalculations.
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true // Recalculate layout when scrolling
    }
}

