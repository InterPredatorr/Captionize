//
//  MyProjectView.swift
//  Captionize
//
//  Created by aziz on 2023-03-24.
//

import SwiftUI
import CoreData

struct MyProjectView: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject private var viewModel: MyProjectsViewModel
    @EnvironmentObject private var pickerViewModel: MyProjectsViewModel

    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            VStack() {
                topView
                Spacer()
                if !viewModel.myProjects.isEmpty {
                    MyProjectsContentView()
                        .environment(\.managedObjectContext, moc)
                } else {
                    noProjectView
                }
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $viewModel.openPickVideoView) {
            PickVideoView { video in
                    viewModel.selectedVideo = video
            }
            .environmentObject(pickerViewModel)
        }
        .navigationDestination(for: $viewModel.selectedVideo) { video in
            VideoEditorContainerView(viewModel: viewModel.getVideoEditorViewModel(with: video, captions: []),
                                     provider: viewModel.provider)
            .environment(\.managedObjectContext, moc)
        }
        .onAppear {
            viewModel.fetchProjectsData()
        }
    }

    var topView: some View {
        HStack(alignment: .center) {
            Text(String(localized: "My projects"))
                .foregroundColor(.white)
                .font(.roboto(size: 32, weight: .bold))
                .padding(.all)
            Spacer()
            if !viewModel.myProjects.isEmpty {
                Button {
                    if viewModel.isMultipleSelection {
                        viewModel.myProjects.forEach { $0.isSelected = false }
                    }
                    viewModel.isMultipleSelection.toggle()
                } label: {
                    Text(viewModel.isMultipleSelection ? "Deselect All" : "Select")
                        .foregroundColor(.white)
                        .font(.roboto(size: 16, weight: .medium))
                }
                Spacer().frame(width: 20)
            }
        }
    }
    
    var noProjectView: some View {
        VStack(spacing: 8) {
            Images.Vector.emptyProjectVector
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 30)
                .frame(width: UIScreen.screenWidth)
            Text(String(localized: "No project yet"))
                .font(.roboto(size: 32, weight: .bold))
            Text(String(localized: "Hit the button below to add your\nfirst projects and see some magic"))
                .foregroundColor(Colors.appGray)
                .font(.roboto(size: 14, weight: .regular))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            CreateButtonView(openPickVideoView: $viewModel.openPickVideoView)
                .padding()
        }
    }
}

struct CreateButtonView: View {
    @Binding var openPickVideoView: Bool
    
    var body: some View {
        Button {
            self.openPickVideoView = true
        } label: {
            HStack {
                Text(String(localized: "+   Create"))
                    .foregroundColor(.white)
                    .font(.roboto(size: 16, weight: .bold))
            }
            .frame(width: 250, height: 60)
            .background(Colors.appPurple)
            .cornerRadius(20)
        }
    }
}
