//
//  DragAndDropProvider.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 22.04.23.
//
import SwiftUI

struct DropViewDelegate: DropDelegate {
    let destinationItem: CaptionItem
    @Binding var texts: [CaptionItem]
    @Binding var draggedItem: CaptionItem?
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        if let draggedItem {
            let fromIndex = texts.firstIndex(of: draggedItem)
            if let fromIndex {
                let toIndex = texts.firstIndex(of: destinationItem)
                if let toIndex, fromIndex != toIndex {
                    let tmp = texts[toIndex].captionText
                    texts[toIndex].captionText = texts[fromIndex].captionText
                    texts[fromIndex].captionText = tmp
                }
            }
        }
    }
}
