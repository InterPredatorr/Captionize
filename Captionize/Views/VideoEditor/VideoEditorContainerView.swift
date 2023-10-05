//
//  VideoEditorView.swift
//  Captionize
//
//  Created by 2830327inc on 27/03/23.
//

import SwiftUI
import AVKit

struct VideoEditorContainerView: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: VideoEditorViewModel
    let provider: MyProjectsProvider
    @State var project: MyProject?
    @State var isExporting = false
    @State var showingAlert = false
    @State var hasSuccessfullyExported = false

    var body: some View {
        ZStack {
            if viewModel.editorStates.isLoaded {
                VStack {
                    VideoPlayerView(viewModel: viewModel)
                    Spacer().frame(height: 50)
                    VideoEditorView(viewModel: viewModel)
                        .environment(\.managedObjectContext, moc)
                }
            }
            if isExporting {
                Color.black
                ProgressView {
                    Text("Exporting...")
                }
                .frame(width: 100, height: 100)
            }
            if !viewModel.editorStates.isLoaded {
                Color.black
                ProgressView {
                    Text("Importing...")
                }
                .frame(width: 100, height: 100)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    viewModel.videoExportManager?.cancelExporting()
                    saveContext()
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.backward")
                    Spacer().frame(width: 5)
                    Text("Return")
                        .font(.roboto(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            if !isExporting && viewModel.editorStates.isLoaded {
                ToolbarItem(placement: .principal) {
                    Images.Icon.eyeIcon
                        .resizable()
                        .foregroundColor(Colors.appPurple)
                        .frame(width: 24, height: 24)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if hasSuccessfullyExported {
                            saveContext()
                            presentationMode.wrappedValue.dismiss()
                            return
                        }
                        exportVideo()
                    } label: {
                        Text(hasSuccessfullyExported ? String(localized: "Done") : "Export")
                            .font(.roboto(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .alert(isPresented: $showingAlert) {
                        Alert(title: Text(hasSuccessfullyExported ? "Successful" : "Failed"),
                              message: Text(hasSuccessfullyExported ? "Video successfully saved in gallery"
                                                                    : "Saving video in gallery failed, please try again"),
                              dismissButton: Alert.Button.cancel(Text(hasSuccessfullyExported ? "OK" : "Retry")) {
                            showingAlert = false
                            if hasSuccessfullyExported { return }
                            exportVideo()
                        })
                    }
                }
            }
        }
        .onAppear {
            if project == nil {
                createNewProject(video: viewModel.video)
            }
        }
        .onDisappear {
            saveContext()
        }
    }
    
    private func exportVideo() {
        viewModel.playerConfig.player.pause()
        if !hasSuccessfullyExported {
            isExporting = true
            viewModel.exportVideo { url in
                hasSuccessfullyExported = url != nil
                isExporting = false
                showingAlert = true
            }
        }
    }
    
    private func saveContext() {
        if let project = project, let excistingProject = provider.exisits(project, in: moc) {
            excistingProject.assetId = viewModel.video.asset.localIdentifier
            let arr = NSSet(array: viewModel.captionsConfig.items.map { item in
                let caption = Caption(context: moc)
                caption.captionText = item.captionText
                caption.startPoint = item.startPoint
                caption.endPoint = item.endPoint
                return caption
            })
            let config = viewModel.captionsConfig.captionConfig
            let textConfig = TextConfiguration(context: moc)
            textConfig.alignment = Int32(config.text.alignment.rawValue)
            textConfig.fontName = config.text.font.fontName
            textConfig.fontSize = config.text.fontSize
            textConfig.color = config.text.color.toHexString()
            textConfig.myProject = excistingProject
            let backgroundConfig = BackgroundConfiguration(context: moc)
            backgroundConfig.color = config.background.color.toHexString()
            backgroundConfig.myProject = excistingProject
            let activeWordConfig = ActiveTextConfiguration(context: moc)
            activeWordConfig.color = config.activeWord.color.toHexString()
            activeWordConfig.fontName = config.activeWord.font.fontName
            activeWordConfig.fontSize = config.activeWord.fontSize
            activeWordConfig.myProject = excistingProject
            
            excistingProject.textConfig = textConfig
            excistingProject.backgroundConfig = backgroundConfig
            excistingProject.activeTextConfig = activeWordConfig
            excistingProject.captions = arr
        }
        do {
            try provider.persist(in: moc)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func createNewProject(video: Video) {
        let newProject = MyProject(context: moc)
        newProject.assetId = video.asset.localIdentifier
        newProject.captions = []
        self.project = newProject
    }
}
