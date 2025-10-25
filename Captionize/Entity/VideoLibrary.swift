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
        
        if allAlbums.isEmpty {
            let allVideosAssets = getAllVideos()
            var videos: [Video] = []
            let dispatchGroup = DispatchGroup()
            for asset in allVideosAssets {
                dispatchGroup.enter()
                self.map(asset: asset) { video in
                    videos.append(video)
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: .main) {
                let album = VideoAlbum(name: String(localized: "All Videos"), videos: videos)
                completionHandler([album])
            }
            return
        }
        
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
            let allVideosAssets = self.getAllVideos()
            var allVideos: [Video] = []
            let allVideosGroup = DispatchGroup()
            for asset in allVideosAssets {
                allVideosGroup.enter()
                self.map(asset: asset) { video in
                    allVideos.append(video)
                    allVideosGroup.leave()
                }
            }
            allVideosGroup.notify(queue: .main) {
                let allVideosAlbum = VideoAlbum(name: String(localized: "All Videos"), videos: allVideos)
                completionHandler([allVideosAlbum] + videoAlbums)
            }
        }
    }
    
    private func map(asset: PHAsset, completionHandler: @escaping ((Video) -> ())) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact
        options.deliveryMode = .highQualityFormat
        options.version = .current
        let duration = asset.duration.formateInSecondsMinute()
        PHImageManager.default().requestImage(for: asset,
                                              targetSize: CGSize(width: 400, height: 400),
                                              contentMode: .aspectFill,
                                              options: options) { (image, _) in
            completionHandler(Video(thumbnail: image, duration: duration, asset: asset))
        }
    }
    
    private func fetchAlbums() -> [PHAssetCollection] {
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        
        var result: [PHAssetCollection] = []
        smartAlbums.enumerateObjects { (collection, _, _) in
            result.append(collection)
        }
        userAlbums.enumerateObjects { (collection, _, _) in
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
    
    private func getAllVideos() -> [PHAsset] {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let result = PHAsset.fetchAssets(with: .video, options: options)
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
