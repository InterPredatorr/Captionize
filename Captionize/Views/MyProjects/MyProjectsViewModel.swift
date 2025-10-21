//
//  MyProjectsViewModel.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 09.05.23.
//

import CoreData
import SwiftUI
import Photos

class MyProjectsViewModel: ObservableObject {
    
    @Published var openPickVideoView = false
    @Published var selectedVideo: Video?
    @Published var isMultipleSelection = false
    @Published var myProjects = [MyProject]()
    @Published var provider = MyProjectsProvider.shared
    
    init() {
        fetchProjectsData()
    }
    
    func fetchProjectsData() {
        let projects = NSFetchRequest<MyProject>(entityName: "MyProject")
        do {
            myProjects = try provider.viewContext.fetch(projects)
        } catch {
            print("DEBUG: Some error occured while fetching")
        }
    }
    
    func fetchCaptions(by objectId: NSManagedObjectID) -> [CaptionItem] {
        guard let project = myProjects.first(where: { $0.objectID == objectId }),
              let objects = project.captions?.allObjects as? [Caption] else { return [] }
        return objects.map({ CaptionItem(captionText: $0.captionText ?? "",
                                         startPoint: $0.startPoint,
                                         endPoint: $0.endPoint,
                                         textColorHex: $0.textColor,
                                         backgroundColorHex: $0.backgroundColor,
                                         positionX: ($0.positionX >= 0) ? $0.positionX : nil,
                                         positionY: ($0.positionY >= 0) ? $0.positionY : nil) })
    }
    func fetchVideo(with assetId: String?, completion: @escaping (Video) -> ()) {
        guard let assetId = assetId,
              let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetId],
                                                                     options: nil).firstObject else { return }
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact
        options.deliveryMode = .highQualityFormat
        options.version = .current
        PHImageManager.default().requestImage(for: asset,
                                              targetSize: CGSize(width: 400, height: 400),
                                              contentMode: .aspectFill,
                                              options: options) { (image, _) in
            let video = Video(thumbnail: image,
                               duration: asset.duration.formateInSecondsMinute(),
                               asset: asset)
            completion(video)
        }
    }
    
    func deleteSelectedProjects(from projects: [MyProject], context: NSManagedObjectContext) {
        do {
            try projects.forEach {
                if $0.isSelected {
                    try provider.delete($0, in: context)
                }
            }
            try provider.persist(in: context)
            fetchProjectsData()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func getVideoEditorViewModel(with video: Video, captions: [CaptionItem]) -> VideoEditorViewModel {
        let item = myProjects.first(where: { $0.assetId == video.asset.localIdentifier })
        let textConfig = VideoEditorCaptionTextConfig(font: UIFont(name: item?.textConfig?.fontName ?? "roboto",
                                                                   size: item?.textConfig?.fontSize ?? 10.0) ?? .roboto(size: 10.0),
                                                      fontSize: item?.textConfig?.fontSize ?? 10.0,
                                                      alignment: NSTextAlignment(rawValue: Int(item?.textConfig?.alignment ?? 1)) ?? .center)
        let captionConfig = VideoEditorCaptionConfig(text: textConfig)
        return VideoEditorViewModel(video: video,
                                    captionsConfig: VideoEditorViewModel.CaptionsConfig(items: captions,
                                                                                        captionConfig: captionConfig))
    }
}
