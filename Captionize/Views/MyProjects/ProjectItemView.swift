//
//  ProjectItemView.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 09.05.23.
//

import SwiftUI

struct ProjectItemView: View {
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var viewModel: MyProjectsViewModel
    @Binding var project: MyProject
    @State var video: Video?
    @State var captions = [CaptionItem]()
    @State private var tappedToOpenEditor: Bool?
    
    var body: some View {
        ZStack {
            Image(uiImage: video?.thumbnail ?? UIImage(systemName: "photo.fill")!)
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .cornerRadius(10)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(" \(video?.duration ?? "--:--") ")
                        .font(.roboto(size: 12, weight: .regular))
                        .padding(4)
                        .background(Colors.appTaupe)
                        .cornerRadius(8)
                        .padding([.bottom, .trailing], 8)
                }
            }
            if project.isSelected {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(.black.opacity(0.5))
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.white)
            }
        }
        .onTapGesture {
            if viewModel.isMultipleSelection {
                project.isSelected.toggle()
                if viewModel.myProjects.first(where: { $0.isSelected }) == nil {
                    viewModel.isMultipleSelection = false
                }
                viewModel.objectWillChange.send()
            } else {
                tappedToOpenEditor = true
            }
        }
        .onLongPressGesture {
            viewModel.isMultipleSelection = true
            project.isSelected.toggle()
        }
        .onAppear {
            viewModel.fetchVideo(with: project.assetId, completion: { video in
                self.video = video
            })
            captions = viewModel.fetchCaptions(by: project.objectID).sorted { $0.startPoint < $1.startPoint }
        }
        .navigationDestination(for: $tappedToOpenEditor) { _ in
            if let video = video {
                VideoEditorContainerView(viewModel: viewModel.getVideoEditorViewModel(with: video, captions: captions),
                                         provider: viewModel.provider,
                                         project: project)
                .environment(\.managedObjectContext, moc)
            }
        }
    }
}
