//
//  PickVideoViewModel.swift
//  Captionize
//
//  Created by 2830327inc on 26/03/23.
//

import Foundation
import PhotosUI

@MainActor
class PickVideoViewModel: ObservableObject {

    @Published var selectedAlbum: VideoAlbum? = nil
    @Published var albums: [VideoAlbum] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let videoLibrary: VideoLibrary

    init(videoLibrary: VideoLibrary) {
        self.videoLibrary = videoLibrary
        Task {
            await self.fetchVideoAlbums()
        }
    }

    func fetchVideoAlbums() async {
        isLoading = true
        errorMessage = nil

        do {
            albums = try await videoLibrary.getVideoAlbums()
            selectByDefaultAlbum()
        } catch let error as VideoLibraryError {
            errorMessage = error.localizedDescription
            print("Video library error: \(error.localizedDescription)")
        } catch {
            errorMessage = "An unexpected error occurred"
            print("Unexpected error: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func selectByDefaultAlbum() {
        self.selectedAlbum = self.albums.first
    }
}
