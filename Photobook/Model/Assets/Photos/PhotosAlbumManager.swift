//
//  PhotosAlbumManager.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos

class PhotosAlbumManager: AlbumManager {
    
    private struct Constants {
        static let permissionsTitle = NSLocalizedString("Controllers/EmptyScreenViewController/PermissionDeniedTitle",
                                                        value: "Permissions Required",
                                                        comment: "Title shown when the photo library access has been disabled")
        static let permissionsMessage = NSLocalizedString("Controllers/EmptyScreenViewController/PermissionDeniedMessage",
                                                          value: "Photo access has been restricted, but it's needed to create beautiful photo books.\nYou can turn it back on in the system settings",
                                                          comment: "Message shown when the photo library access has been disabled")
        static let permissionsButtonTitle = NSLocalizedString("Controllers/StoriesviewController/PermissionDeniedSettingsButton",
                                                              value: "Open Settings",
                                                              comment: "Button title to direct the user to the app permissions screen in the phone settings")
    }
    
    var albums:[Album] = [Album]()
    static let imageManager = PHCachingImageManager()
    
    func loadAlbums(completionHandler: ((ErrorMessage?) -> Void)?) {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else {
            let errorMessage = ErrorMessage(title: Constants.permissionsTitle, message: Constants.permissionsMessage, buttonTitle: Constants.permissionsButtonTitle, buttonAction: {
                if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                }
            })
            completionHandler?(errorMessage)
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            let options = PHFetchOptions()
            options.wantsIncrementalChangeDetails = false
            options.includeHiddenAssets = false
            options.includeAllBurstAssets = false
            
            // Get "All Photos" album
            if let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: options).firstObject{
                let album = PhotosAlbum(collection)
                
                // Load assets here so that we know the number of assets in this album
                album.loadAssetsFromPhotoLibrary()
                if album.assets.count > 0 {
                    self.albums.append(album)
                }
                
            }
            
            // Get Favorites album
            if let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: options).firstObject{
                let album = PhotosAlbum(collection)
                
                // Load assets here so that we know the number of assets in this album
                album.loadAssetsFromPhotoLibrary()
                if album.assets.count > 0 {
                    self.albums.append(album)
                }
            }
            
            // Get Selfies album
            if let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSelfPortraits, options: options).firstObject{
                let album = PhotosAlbum(collection)
                
                // Load assets here so that we know the number of assets in this album
                album.loadAssetsFromPhotoLibrary()
                if album.assets.count > 0 {
                    self.albums.append(album)
                }
            }
            
            // Get Portrait album
            if #available(iOS 10.2, *) {
                if let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumDepthEffect, options: options).firstObject{
                    let album = PhotosAlbum(collection)
                    
                    // Load assets here so that we know the number of assets in this album
                    album.loadAssetsFromPhotoLibrary()
                    if album.assets.count > 0 {
                        self.albums.append(album)
                    }
                }
            }
            
            // Get Panoramas album
            if let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumPanoramas, options: options).firstObject{
                let album = PhotosAlbum(collection)
                
                // Load assets here so that we know the number of assets in this album
                album.loadAssetsFromPhotoLibrary()
                if album.assets.count > 0 {
                    self.albums.append(album)
                }
            }
            
            // Get User albums
            let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
            collections.enumerateObjects({ [weak welf = self] (collection, _, _) in
                guard collection.estimatedAssetCount != 0 else { return }
                let album = PhotosAlbum(collection)
                welf?.albums.append(album)
            })
            
            DispatchQueue.main.async(execute: {() -> Void in
                completionHandler?(nil)
            })
        }
    }
    
    func stopCachingImagesForAllAssets() {
        PhotosAlbumManager.imageManager.stopCachingImagesForAllAssets()
    }
    
    func startCachingImages(for assets: [Asset], targetSize: CGSize) {
        PhotosAlbumManager.imageManager.startCachingImages(for: photosAssets(from: assets), targetSize: targetSize, contentMode: .aspectFill, options: nil)
    }
    
    func stopCachingImages(for assets: [Asset], targetSize: CGSize) {
        PhotosAlbumManager.imageManager.stopCachingImages(for: photosAssets(from: assets), targetSize: targetSize, contentMode: .aspectFill, options: nil)
    }
    
    func photosAssets(from assets:[Asset]) -> [PHAsset]{
        var photosAssets = [PHAsset]()
        for asset in assets{
            guard let photosAsset = asset as? PhotosAsset else { continue }
            photosAssets.append(photosAsset.photosAsset)
        }
        
        return photosAssets
    }

}
