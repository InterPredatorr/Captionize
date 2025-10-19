//
//  VideoLibrary.swift
//  Captionize
//
//  Created by 2830327inc on 26/03/23.
//

import Foundation
import PhotosUI

enum VideoLibraryError: Error {
    case permissionDenied
    case noVideosFound
    case fetchFailed(Error)

    var localizedDescription: String {
        switch self {
        case .permissionDenied:
            return "Photo library access denied. Please enable in Settings."
        case .noVideosFound:
            return "No videos found in your library."
        case .fetchFailed(let error):
            return "Failed to load videos: \(error.localizedDescription)"
        }
    }
}

protocol VideoLibrary {
    func getVideoAlbums() async throws -> [VideoAlbum]
}

class DefaultVideoLibrary: VideoLibrary {

    func getVideoAlbums() async throws -> [VideoAlbum] {
        // Check photo library authorization
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            throw VideoLibraryError.permissionDenied
        }

        let allAlbums = fetchAlbumsWhichHasVideo()
        guard !allAlbums.isEmpty else {
            throw VideoLibraryError.noVideosFound
        }

        return try await withThrowingTaskGroup(of: VideoAlbum?.self) { group in
            for album in allAlbums {
                group.addTask {
                    try await self.fetchVideosForAlbum(album)
                }
            }

            var videoAlbums: [VideoAlbum] = []
            for try await album in group {
                if let album = album {
                    videoAlbums.append(album)
                }
            }
            return videoAlbums
        }
    }

    private func fetchVideosForAlbum(_ album: PHAssetCollection) async throws -> VideoAlbum? {
        let videosData = getVideos(from: album)
        guard !videosData.isEmpty else { return nil }

        let videos = try await withThrowingTaskGroup(of: Video.self) { group in
            for asset in videosData {
                group.addTask {
                    try await self.map(asset: asset)
                }
            }

            var result: [Video] = []
            for try await video in group {
                result.append(video)
            }
            return result
        }

        return VideoAlbum(name: album.localizedTitle ?? album.localIdentifier, videos: videos)
    }

    private func map(asset: PHAsset) async throws -> Video {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.version = .current
        options.isSynchronous = false

        let duration = asset.duration.formateInSecondsMinute()

        return try await withCheckedThrowingContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 100, height: 100),
                contentMode: .aspectFit,
                options: options
            ) { (image, info) in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: VideoLibraryError.fetchFailed(error))
                } else {
                    continuation.resume(returning: Video(thumbnail: image, duration: duration, asset: asset))
                }
            }
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
