//
//  AssetSelectorViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 04/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import Photos

/// Protocol a delegate has to conform to to be notified about asset selection
protocol AssetSelectorDelegate: class {
    func didSelect(asset: Asset)
}

class AssetSelectorViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var addMoreSelectedAssetsManager = SelectedAssetsManager()
    private var assets: [Asset] {
        get {
            if let manager = selectedAssetsManager {
                return manager.selectedAssets
            }
            return [Asset]()
        }
    }
    private lazy var timesUsed: [String: Int] = {
        var temp = [String: Int]()
        for asset in self.assets {
            temp[asset.identifier] = temp[asset.identifier] != nil ? temp[asset.identifier]! + 1 : 1
        }
        return temp
    }()
    private var selectedAssetIndex = -1
    
    var selectedAssetsManager: SelectedAssetsManager!
    weak var delegate: AssetSelectorDelegate?
    
    var selectedAsset: Asset? {
        didSet {
            guard selectedAsset != nil else {
                selectedAssetIndex = -1
                reloadAndCenter()
                return
            }
            selectedAssetIndex = assets.index { $0.identifier == selectedAsset!.identifier } ?? -1
            reloadAndCenter()
        }
    }
    var browseNavigationController: UINavigationController!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func reloadAndCenter() {
        collectionView.reloadData()
        let itemToScrollTo = selectedAssetIndex >= 0 ? selectedAssetIndex : 0
        collectionView.scrollToItem(at: IndexPath(row: itemToScrollTo, section: 0), at: .centeredHorizontally, animated: true)
    }
    
    @objc private func changedCollectedAssets() {
        
    }
}

extension AssetSelectorViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Add one for the "add more" thumbnail
        return assets.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // "Add more" thumbnail
        if indexPath.row == assets.count {
            return collectionView.dequeueReusableCell(withReuseIdentifier: AssetSelectorAddMoreCollectionViewCell.reuseIdentifier, for: indexPath) as! AssetSelectorAddMoreCollectionViewCell
        }

        let asset = assets[indexPath.row]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AssetSelectorAssetCollectionViewCell.reuseIdentifier, for: indexPath) as! AssetSelectorAssetCollectionViewCell
        cell.isBorderVisible = (selectedAssetIndex == indexPath.row)
        cell.timesUsed = timesUsed[asset.identifier] ?? 0
        cell.assetIdentifier = asset.identifier
        let itemSize = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        
        asset.image(size: itemSize, completionHandler: { (image, error) in
            guard cell.assetIdentifier == asset.identifier, error == nil else { return }
            cell.assetImage = image
        })
        
        return cell
    }
}

extension AssetSelectorViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == assets.count {
            let draggableModalViewController = storyboard?.instantiateViewController(withIdentifier: "DraggableModalViewController") as! ModalAlbumsCollectionViewController
            draggableModalViewController.albumManager = PhotosAlbumManager() // FIXME: Could be a different source
            draggableModalViewController.addingDelegate = self
            
            present(draggableModalViewController, animated: false, completion: nil)
            return
        }
        
        guard selectedAssetIndex != indexPath.row else { return }
        
        var indicesToReload = [ IndexPath(row: indexPath.row, section: 0) ]
        
        if let selectedAsset = selectedAsset {
            indicesToReload.append(IndexPath(row: selectedAssetIndex, section: 0))
            timesUsed[selectedAsset.identifier] = timesUsed[selectedAsset.identifier]! - 1
        }
        selectedAsset = selectedAssetsManager.selectedAssets[indexPath.row]
        timesUsed[selectedAsset!.identifier] = timesUsed[selectedAsset!.identifier]! + 1
        
        collectionView.reloadItems(at: indicesToReload)
        collectionView.scrollToItem(at: IndexPath(row: indexPath.row, section: 0), at: .centeredHorizontally, animated: true)
        
        delegate?.didSelect(asset: assets[indexPath.row])
    }
}

extension AssetSelectorViewController: AssetCollectorAddingDelegate {
    
    func didFinishAdding(assets: [Asset]?) {
        guard let assets = assets, assets.count > 0 else {
            self.dismiss(animated: false, completion: nil)
            return
        }
        
        selectedAssetsManager.select(assets)
        collectionView.reloadData()
        collectionView.scrollToItem(at: IndexPath(row: self.assets.count, section: 0), at: .centeredHorizontally, animated: true)
        self.dismiss(animated: false, completion: nil)
    }    
}
