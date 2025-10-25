//
//  PickVideoView.swift
//  Captionize
//
//  Created by 2830327inc on 26/03/23.
//

import SwiftUI
import PhotosUI

struct PickVideoView: View {
    
    let cardWidth = (UIScreen.main.bounds.size.width - 40) / 3
    @EnvironmentObject private var viewModel: PickVideoViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var open: ((Video) -> ())?
    
    var videoGridLayout: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Loading videos...")
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Retry") {
                        Task {
                            await viewModel.fetchVideoAlbums()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                VStack {
                    topView
                    videoGrid
                    bottomView
                }.padding()
            }
        }
    }
    
    func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
    
    var topView: some View {
        HStack {
            Button {
                self.dismiss()
            } label: {
                Images.SFSymbol.xCircleFill
                    .foregroundColor(.red)
            }
            Spacer()
            HStack(spacing: 8) {
                Menu {
                    ForEach(viewModel.albums, id: \.name) { album in
                        Button {
                            viewModel.selectedAlbum = album
                        } label: {
                            Text(album.name)
                        }
                        
                    }
                } label: {
                    Text(viewModel.selectedAlbum?.name ?? "---")
                        .font(.roboto(size: 16, weight: .bold))
                    Images.SFSymbol.chevronDown
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Colors.appPurple)
                        .frame(width: 10, height: 10)
                }
                .tint(.white)
            }
            Spacer()
        }.padding()
    }
    
    var videoGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: videoGridLayout, spacing: 8) {
                ForEach(viewModel.selectedAlbum?.videos ?? [], id: \.asset.localIdentifier) { video in
                    videoGridItem(video)
                }
            }
        }
    }
    
    @ViewBuilder
    func videoGridItem(_ video: Video) -> some View {
        ZStack {
            Image(uiImage: video.thumbnail!)
                .resizable()
                .scaledToFill()
                .frame(width: cardWidth, height: cardWidth)
                .clipped()
                .cornerRadius(12)
            ZStack {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(" \(video.duration ?? "00:00") ")
                            .font(.roboto(size: 12, weight: .regular))
                            .padding(4)
                            .background(Colors.appTaupe)
                            .cornerRadius(8)
                            .padding(.bottom,4)
                            .padding(.trailing,4)
                    }
                }
            }
        }
        .onTapGesture {
            self.open?(video)
            self.dismiss()
        }
    }
    
    var bottomView: some View {
        HStack {
            Spacer()
            Text(String(localized: "Select at least one video to continue"))
                .font(.roboto(size: 12, weight: .regular))
            Spacer()
        }
    }
}
