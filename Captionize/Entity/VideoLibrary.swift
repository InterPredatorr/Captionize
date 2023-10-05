//
//  VideoLibrary.swift
//  Captionize
//
//  Created by 2830327inc on 26/03/23.
//

import Foundation
import PhotosUI

protocol VideoLibrary {
    func getVideoAlbums(_ completionHandler: @escaping (([VideoAlbum]) -> ()))
}

class DefaultVideoLibrary: VideoLibrary {
    
    func getVideoAlbums(_ completionHandler: @escaping (([VideoAlbum]) -> ())) {
        let allAlbums = fetchAlbumsWhichHasVideo()
        var videoAlbums: [VideoAlbum] = []
        let mainDispatchGroup = DispatchGroup()
        for album in allAlbums {
            mainDispatchGroup.enter()
            let videosData = getVideos(from: album)
            var videos: [Video] = []
            let dispatchGroup = DispatchGroup()
            for asset in videosData {
                dispatchGroup.enter()
                self.map(asset: asset) { video in
                    videos.append(video)
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: .main) {
                videoAlbums.append(.init(name: album.localizedTitle ?? album.localIdentifier, videos: videos))
                mainDispatchGroup.leave()
            }
        }
        mainDispatchGroup.notify(queue: .main) {
            completionHandler(videoAlbums)
        }
    }
    
    private func map(asset: PHAsset, completionHandler: @escaping ((Video) -> ())) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.version = .current
        let duration = asset.duration.formateInSecondsMinute()
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFit, options: options) { (image, info) in
            completionHandler(Video(thumbnail: image, duration: duration, asset: asset))
        }
    }
    
    private func fetchAlbums() -> [PHAssetCollection] {
        let options = PHFetchOptions()
        let albums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: options)
        var result: [PHAssetCollection] = []
        albums.enumerateObjects { (collection, _, _) in
            result.append(collection)
        }
        return result
    }
    
    private func getVideos(from collection: PHAssetCollection) -> [PHAsset] {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let result = PHAsset.fetchAssets(in: collection, options: options)
        var assets = [PHAsset]()
        result.enumerateObjects { (asset, _, _) in
            assets.append(asset)
        }
        return assets
    }
    
    private func fetchAlbumsWhichHasVideo() -> [PHAssetCollection] {
        let allAlbums = fetchAlbums()
        var albums: [PHAssetCollection] = []
        allAlbums.forEach { album in
            let videos = self.getVideos(from: album)
            if videos.count != 0 {
                albums.append(album)
            }
        }
        return albums
    }
}
