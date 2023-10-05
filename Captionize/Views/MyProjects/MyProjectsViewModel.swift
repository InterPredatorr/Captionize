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
        return objects.map({ CaptionItem(captionText: $0.captionText ?? "DEBUG: Some error occured while fetching",
                                         startPoint: $0.startPoint,
                                         endPoint: $0.endPoint) })
    }
    func fetchVideo(with assetId: String?, completion: @escaping (Video) -> ()) {
        guard let assetId = assetId,
              let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetId],
                                                                     options: nil).firstObject else { return }
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.version = .current
        PHImageManager.default().requestImage(for: asset,
                                              targetSize: CGSize(width: 400, height: 400),
                                              contentMode: .aspectFit,
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
                                                      color: CGColor.fromHexString(item?.textConfig?.color) ?? UIColor.white.cgColor,
                                                      alignment: NSTextAlignment(rawValue: Int(item?.textConfig?.alignment ?? 1)) ?? .center)
        let backgroundConfig = VideoEditorCaptionBackgroundConfig(color: CGColor.fromHexString(item?.backgroundConfig?.color) ?? UIColor.black.cgColor)
        let activeTextConfig = VideoEditorCaptionActiveWordConfig(font: UIFont(name: item?.activeTextConfig?.fontName ?? "roboto",
                                                                               size: item?.activeTextConfig?.fontSize ?? 10.0) ?? .roboto(size: 10.0),
                                                                  fontSize: item?.activeTextConfig?.fontSize ?? 10.0,
                                                                  color: CGColor.fromHexString(item?.activeTextConfig?.color) ?? UIColor.red.cgColor)
        let captionConfig = VideoEditorCaptionConfig(text: textConfig,
                                                     background: backgroundConfig,
                                                     activeWord: activeTextConfig)
        return VideoEditorViewModel(video: video,
                                    captionsConfig: VideoEditorViewModel.CaptionsConfig(items: captions,
                                                                                        captionConfig: captionConfig))
    }
}
