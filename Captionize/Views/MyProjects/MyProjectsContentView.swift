//
//  MyProjectsContentView.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 07.05.23.
//

import SwiftUI
import Photos

struct MyProjectsContentView: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject private var viewModel: MyProjectsViewModel
    @State var showAlert = false
    
    private let projectsGridLayout: [GridItem] = [GridItem(.flexible()),
                                                  GridItem(.flexible())]
    
    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: projectsGridLayout, spacing: 10) {
                    ForEach($viewModel.myProjects) { project in
                        ProjectItemView(viewModel: viewModel,
                                        project: project)
                        .aspectRatio(1, contentMode: .fill)
                    }
                }
                .padding(20)
            }
            .refreshable {}
            if viewModel.isMultipleSelection {
                Button {
                    showAlert = true
                } label: {
                    HStack(spacing: 5) {
                        Text("Delete \(viewModel.myProjects.filter { $0.isSelected }.count) projects")
                            .foregroundColor(.red)
                    }
                    
                }
                .alert("Delete Projects",
                       isPresented: $showAlert,
                       actions: {
                    Button(role: .destructive) {
                        viewModel.deleteSelectedProjects(from: viewModel.myProjects, context: moc)
                        viewModel.isMultipleSelection = false
                        showAlert = false
                    } label: {
                        Text("Delete")
                    }
                    Button(role: .cancel) {
                        showAlert = false
                    } label: {
                        Text("Cancel")
                    }
                }, message: {
                    Text("Do you really want to delete selected projects? \n Projects will be deleted permanently.")
                })
                .preferredColorScheme(.dark)
            } else {
                CreateButtonView(openPickVideoView: $viewModel.openPickVideoView)
            }
        }
    }
}
