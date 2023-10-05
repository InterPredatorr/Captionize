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
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                let viewModel = MyProjectsViewModel()
                MyProjectView(viewModel: viewModel)
                    .environment(\.locale, .init(identifier: "hy"))
                    .environment(\.managedObjectContext, MyProjectsProvider.shared.viewContext)
                    .preferredColorScheme(.dark) // Only supporting dark mode.
            }
            .accentColor(.white)
        }
    }
}
