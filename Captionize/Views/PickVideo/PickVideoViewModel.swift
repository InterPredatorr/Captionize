//
//  PickVideoViewModel.swift
//  Captionize
//
//  Created by 2830327inc on 26/03/23.
//

import Foundation
import PhotosUI

class PickVideoViewModel: ObservableObject {
    
    @Published var selectedAlbum: VideoAlbum? = nil
    @Published var albums: [VideoAlbum] = []
    
    let videoLibrary: VideoLibrary
    
    init(videoLibrary: VideoLibrary) {
        self.videoLibrary = videoLibrary
        self.fetchVideoAlbums()
    }
    
    func fetchVideoAlbums() {
        videoLibrary.getVideoAlbums { [weak self] albums in
            self?.albums = albums
            self?.selectByDefaultAlbum()
        }
    }
    
    func selectByDefaultAlbum() {
        self.selectedAlbum = self.albums.first
    }
}
