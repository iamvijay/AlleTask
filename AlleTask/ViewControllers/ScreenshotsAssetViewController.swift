//
//  ScreenshotsAssetViewController.swift
//  AlleTask
//
//  Created by V!jay on 04/12/24.
//

import UIKit

class ScreenshotsAssetViewController: UIViewController {
    // MARK: - Properties
    
    /// Indicates whether a scroll event is triggered programmatically to avoid recursive delegate calls.
    var isProgrammaticScroll = false
    
    /// A collection view for displaying enlarged screenshot assets.
    var enlargedCollectionView : ScreenshotAssetCollectionView = {
        let collectionViewFlowLayout = UICollectionViewFlowLayout()
        collectionViewFlowLayout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        collectionViewFlowLayout.scrollDirection = .horizontal
        collectionViewFlowLayout.minimumLineSpacing = 0
        collectionViewFlowLayout.sectionInset = .zero
        
        let collectionView = ScreenshotAssetCollectionView.init(collectionViewLayout: collectionViewFlowLayout, viewType: .enlarged)
        collectionView.isPagingEnabled = true
        collectionView.backgroundColor = .black
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isHidden = true
        return collectionView
    }()
    
    /// A collection view for displaying thumbnail-sized screenshot assets.
    var thumbnailCollectionView : ScreenshotAssetCollectionView = {
        let collectionViewFlowLayout = CenterTransformFlowLayout()
        collectionViewFlowLayout.scrollDirection = .horizontal
        collectionViewFlowLayout.itemSize = CGSize(width: 40, height: 60) // Default size
        collectionViewFlowLayout.minimumLineSpacing = 5
        collectionViewFlowLayout.sectionInset = UIEdgeInsets(top: 0, left: UIScreen.main.bounds.midX, bottom: 0, right: UIScreen.main.bounds.midX)
        
        let collectionView = ScreenshotAssetCollectionView.init(collectionViewLayout: collectionViewFlowLayout, viewType: .thumbnail)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .black
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    /// A container view for the thumbnail collection view with a blur effect.
    var thumbnailViewContainer : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.backgroundColor = .clear
        
        let blurEffect = UIBlurEffect(style: .systemMaterialDark)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(visualEffectView)
        
        NSLayoutConstraint.activate([
            visualEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            visualEffectView.topAnchor.constraint(equalTo: view.topAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        return view
    }()
    
    /// A status label used to display loading or error messages.
    var statusLabel : UILabel = {
        let label = UILabel()
        label.text = "Loading..."
        label.textAlignment = .center
        label.font = UIFont(name: "Helvetica", size: 20)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        
        return label
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViewUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update layout dynamically if the view size changes.
        guard let layout = enlargedCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let newSize = CGSize(width: enlargedCollectionView.bounds.width, height: enlargedCollectionView.bounds.height)
        
        // Only update if size changes significantly
        if abs(layout.itemSize.width - newSize.width) > 1 || abs(layout.itemSize.height - newSize.height) > 1 {
            layout.itemSize = newSize
            layout.invalidateLayout()
        }
    }
    
    // MARK: - Setup Methods
    
    /// Sets up the UI elements and constraints for the view controller.
    private func setupViewUI () {
        enlargedCollectionView.collectionViewDelegate = self
        thumbnailCollectionView.collectionViewDelegate = self
        
        view.addSubview(statusLabel)
        view.addSubview(enlargedCollectionView)
        view.addSubview(thumbnailViewContainer)
        thumbnailViewContainer.addSubview(thumbnailCollectionView)
        
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            statusLabel.heightAnchor.constraint(equalToConstant: 80),
            statusLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),
            
            enlargedCollectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            enlargedCollectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            enlargedCollectionView.topAnchor.constraint(equalTo: self.view.topAnchor),
            enlargedCollectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            
            thumbnailViewContainer.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            thumbnailViewContainer.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            thumbnailViewContainer.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            thumbnailViewContainer.heightAnchor.constraint(equalToConstant: 140.0),
            
            thumbnailCollectionView.leadingAnchor.constraint(equalTo: self.thumbnailViewContainer.safeAreaLayoutGuide.leadingAnchor),
            thumbnailCollectionView.trailingAnchor.constraint(equalTo: self.thumbnailViewContainer.safeAreaLayoutGuide.trailingAnchor),
            thumbnailCollectionView.topAnchor.constraint(equalTo: self.thumbnailViewContainer.topAnchor),
            thumbnailCollectionView.heightAnchor.constraint(equalToConstant: 60.0)
        ])
        
        statusLabel.text = "No Authorization \n Goto setting and give access"
    }
}

// MARK: - ScreenShotViewDelegate Methods
extension ScreenshotsAssetViewController: ScreenShotViewDelegate {
    /// Handles visibility of UI elements based on the number of assets.
    /// - Parameter count: The number of items available in the data source.
    func didCollectionViewHasSingleData(_ count: Int) {
        // If there are 1 or fewer items, hide the thumbnail view.
        if count <= 1 {
            thumbnailViewContainer.isHidden = true
            
            // Show status label if no items are available.
            statusLabel.isHidden = !(count == 0)
            statusLabel.text = "No Photos to show"
        }  else {
            thumbnailViewContainer.isHidden = false
        }
        
        // Show or hide the enlarged collection view based on available data.
        enlargedCollectionView.isHidden = !(count >= 1)
    }
    
    /// Synchronizes scrolling when the scroll gesture ends.
    /// - Parameters:
    ///   - indexPath: The index path of the currently visible item.
    ///   - collectionView: The collection view that was scrolled.
    func didCollectionViewScrollEnded(indexPath: IndexPath, collectionView: UICollectionView) {
        synchronizeScroll(from: collectionView, to: targetCollectionView(for: collectionView), indexPath: indexPath, animated: true)
    }
    
    /// Synchronizes scrolling while the user is actively scrolling.
    /// - Parameters:
    ///   - indexPath: The index path of the item currently in focus.
    ///   - collectionView: The collection view being scrolled.
    func didCollectionViewScrolled(indexPath: IndexPath, collectionView: UICollectionView) {
        synchronizeScroll(from: collectionView, to: targetCollectionView(for: collectionView), indexPath: indexPath, animated: false)
    }
    
    /// Handles user taps on collection view items, synchronizing both views.
    /// - Parameter indexPath: The index path of the tapped item.
    func didCollectionViewClicked(indexPath: IndexPath) {
        isProgrammaticScroll = true
        
        // Scroll both enlarged and thumbnail views to the tapped item.
        enlargedCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        thumbnailCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        resetProgrammaticScrollFlag()
    }
    
    // MARK: - Private Helper Methods
    
    /// Synchronizes scrolling between the source and target collection views.
    /// - Parameters:
    ///   - sourceCollectionView: The collection view initiating the scroll.
    ///   - targetCollectionView: The collection view to synchronize with.
    ///   - indexPath: The index path of the item to scroll to.
    ///   - animated: A Boolean indicating whether the scroll should be animated.
    private func synchronizeScroll(from sourceCollectionView: UICollectionView, to targetCollectionView: UICollectionView?, indexPath: IndexPath, animated: Bool) {
        guard let targetCollectionView = targetCollectionView, !isProgrammaticScroll else { return }
        
        // Scroll the target collection view to the specified item.
        isProgrammaticScroll = true
        targetCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
        resetProgrammaticScrollFlag()
    }
    
    /// Determines the target collection view to synchronize with.
    /// - Parameter sourceCollectionView: The collection view initiating the action.
    /// - Returns: The target collection view for synchronization, or `nil` if not applicable.
    private func targetCollectionView(for sourceCollectionView: UICollectionView) -> UICollectionView? {
        if sourceCollectionView == enlargedCollectionView {
            return thumbnailCollectionView
        } else if sourceCollectionView == thumbnailCollectionView {
            return enlargedCollectionView
        }
        return nil
    }
    
    /// Resets the programmatic scroll flag after a delay to prevent recursive scroll actions.
    private func resetProgrammaticScrollFlag() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isProgrammaticScroll = false
        }
    }
}


