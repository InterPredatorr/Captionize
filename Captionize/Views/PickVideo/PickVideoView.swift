//
//  PickVideoView.swift
//  Captionize
//
//  Created by 2830327inc on 26/03/23.
//

import SwiftUI
import PhotosUI

struct PickVideoView: View {
    
    @StateObject var viewModel: PickVideoViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var open: ((Video) -> ())?
    
    var videoGridLayout: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            VStack {
                topView
                videoGrid
                bottomView
            }.padding()
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
            LazyVGrid(columns: videoGridLayout) {
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
                .aspectRatio(1, contentMode: .fit)
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
        .padding(2)
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

struct PickVideoView_Previews: PreviewProvider {
    static var previews: some View {
        PickVideoView(viewModel: .init(videoLibrary: DefaultVideoLibrary()))
    }
}
