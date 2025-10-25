//
//  PickVideoViewModel.swift
//  Captionize
//
//  Created by 2830327inc on 26/03/23.
//

import Foundation
import PhotosUI

@MainActor
class PickVideoViewModel: NSObject, ObservableObject {

    @Published var selectedAlbum: VideoAlbum? = nil
    @Published var albums: [VideoAlbum] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined

    let videoLibrary: VideoLibrary

    init(videoLibrary: VideoLibrary) {
        self.videoLibrary = videoLibrary
        super.init()

        PHPhotoLibrary.shared().register(self)

        Task {
            await self.checkPermissionAndFetch()
        }
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    func checkPermissionAndFetch() async {
        isLoading = true
        errorMessage = nil

        videoLibrary.checkPhotoLibraryPermission { [weak self] status in
            guard let self = self else { return }

            Task { @MainActor in
                self.authorizationStatus = status

                switch status {
                case .authorized, .limited:
                    await self.fetchVideoAlbums()
                case .notDetermined:
                    // Request permission
                    await self.requestPermission()
                case .denied, .restricted:
                    self.isLoading = false
                    self.errorMessage = String(localized: "Photo library access is required. Please enable it in Settings.")
                @unknown default:
                    self.isLoading = false
                    self.errorMessage = String(localized: "Unable to access photo library.")
                }
            }
        }
    }

    func requestPermission() async {
        await withCheckedContinuation { continuation in
            videoLibrary.requestPhotoLibraryPermission { [weak self] status in
                guard let self = self else {
                    continuation.resume()
                    return
                }

                Task { @MainActor in
                    self.authorizationStatus = status

                    switch status {
                    case .authorized, .limited:
                        await self.fetchVideoAlbums()
                    case .denied, .restricted:
                        self.isLoading = false
                        self.errorMessage = String(localized: "Photo library access is required. Please enable it in Settings.")
                    default:
                        self.isLoading = false
                        self.errorMessage = String(localized: "Unable to access photo library.")
                    }

                    continuation.resume()
                }
            }
        }
    }

    func fetchVideoAlbums() async {
        isLoading = true
        errorMessage = nil

        videoLibrary.getVideoAlbums { [weak self] albums in
            guard let self = self else { return }
            Task { @MainActor in
                self.albums = albums
                self.selectByDefaultAlbum()
                self.isLoading = false
            }
        }
    }

    func selectByDefaultAlbum() {
        self.selectedAlbum = self.albums.first
    }

    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - PHPhotoLibraryChangeObserver
extension PickVideoViewModel: PHPhotoLibraryChangeObserver {
    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        // When photo library changes (e.g., permission granted), refresh albums
        Task { @MainActor in
            // Re-check permission and fetch if granted
            await self.checkPermissionAndFetch()
        }
    }
}
