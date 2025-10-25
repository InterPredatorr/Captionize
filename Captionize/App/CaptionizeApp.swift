//
//  CaptionizeApp.swift
//  Captionize
//
//  Created by aziz on 2023-03-24.
//

import SwiftUI
import CoreData

@main
struct CaptionizeApp: App {
    
    @StateObject private var viewModel = MyProjectsViewModel()
    @StateObject private var pickerViewModel = PickVideoViewModel(videoLibrary: DefaultVideoLibrary())
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                
                MyProjectView()
                    .environment(\.locale, .init(identifier: "hy"))
                    .environment(\.managedObjectContext, MyProjectsProvider.shared.viewContext)
                    .environmentObject(viewModel)
                    .environmentObject(pickerViewModel)
                    .preferredColorScheme(.dark)
            }
            .accentColor(.white)
        }
    }
}
