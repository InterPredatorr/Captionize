//
//  CaptionItemView.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 20.04.23.
//

import SwiftUI
import UIKit

struct CaptionItemView: View {
    @ObservedObject var viewModel: VideoEditorViewModel
    @Binding var item: CaptionItem
    @State private var timer: Timer?
    @State private var isStartedTimer = false
    @State private var isAbleToScroll = false
    
    var body: some View {
        HStack {
            Button {} label: {
                Spacer().frame(width: Constants.VECap.buttonPadding)
                Image(systemName: "chevron.compact.left")
            }
            .frame(width: Constants.VECap.buttonWidth)
            .simultaneousGesture(DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged({ value in
                    checkEdge(with: value)
                    if isAtEdge(value: value.startLocation.x) && !isAtEdge(value: value.location.x) {
                        isAbleToScroll = true
                    }
                })
                    .onEnded({ _ in
                        handleGestureEnd()
                    })
            )
            .simultaneousGesture(DragGesture(minimumDistance: 0,
                                             coordinateSpace: CoordinateSpace.named("captionSpace"))
                .onChanged({ value in
                    item.side = .left
                    self.viewModel.udpatePoints(for: item, x: value.location.x)
                })
                    .onEnded({ _ in
                        item.isChanging = false
                        viewModel.checkAvailibility()
                        simpleSuccess(style: .soft)
                    })
            )
            Spacer()
            Text(item.captionText)
                .multilineTextAlignment(.leading)
                .font(Font.roboto(size: 14))
                .lineLimit(Constants.VECap.textLineLimit)
                .foregroundColor(colorFromHex(item.textColorHex, default: .white))
            Spacer()
            Button {} label: {
                Image(systemName: "chevron.compact.right")
                Spacer().frame(width: Constants.VECap.buttonPadding)
            }
            .frame(width: Constants.VECap.buttonWidth)
            .simultaneousGesture(DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged({ value in
                    checkEdge(with: value)
                    if isAtEdge(value: value.startLocation.x) && !isAtEdge(value: value.location.x) {
                        isAbleToScroll = true
                    }
                })
                    .onEnded({ _ in
                        handleGestureEnd()
                    })
            )
            .simultaneousGesture(DragGesture(minimumDistance: 0,
                                             coordinateSpace: CoordinateSpace.named("captionSpace"))
                .onChanged({ value in
                    item.side = .right
                    self.viewModel.udpatePoints(for: item, x: value.location.x)
                })
                    .onEnded({ _ in
                        item.isChanging = false
                        viewModel.checkAvailibility()
                        simpleSuccess(style: .soft)
                    })
            )
        }
        .frame(width: item.width)
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectedCaptionId = item.id
            viewModel.isShowingCaptionSheet = true
        }
        .overlay(RoundedRectangle(cornerRadius: Constants.VECap.radius)
            .stroke(Colors.appClayBlack, lineWidth: 2))
        .background(colorFromHex(item.backgroundColorHex, default: Colors.appPurple))
        .cornerRadius(Constants.VECap.radius)
        
    }
    
    private func handleGestureEnd() {
        timer?.invalidate()
        isStartedTimer = false
        isAbleToScroll = false
        viewModel.checkAvailibility()
        viewModel.editorStates.isAutoScrolling = false
    }
    
    private func simpleSuccess(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    private func checkEdge(with value: DragGesture.Value) {
        if (isAtEdge(value: value.location.x) && !isAtEdge(value: value.startLocation.x)) || (isAbleToScroll && isAtEdge(value: value.location.x)) {
            if !isStartedTimer {
                timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
                    handleScreenEdgeScrolling(with: value)
                }
                viewModel.editorStates.isAutoScrolling = true
                isStartedTimer = true
            }
        } else {
            timer?.invalidate()
            isStartedTimer = false
        }
    }
    
    private func isAtEdge(value: CGFloat) -> Bool {
        return !(UIScreen.screenWidth.percentageWith(percent: 10)...UIScreen.screenWidth.percentageWith(percent: 90) ~= value)
    }
                          
    private func handleScreenEdgeScrolling(with value: DragGesture.Value) {
        let changePerFrame: Double = 1 / 15
        if isAbleToScroll {
            if value.location.x > UIScreen.screenWidth.percentageWith(percent: 90) {
                viewModel.playerConfig.currentTime += changePerFrame
            } else if value.location.x < UIScreen.screenWidth.percentageWith(percent: 10) {
                viewModel.playerConfig.currentTime -= changePerFrame
            }
            return
        }
        viewModel.playerConfig.currentTime += value.translation.width > 0 ? changePerFrame : -changePerFrame
    }
    
    private func colorFromHex(_ hex: String?, default defaultColor: Color) -> Color {
        guard let cg = CGColor.fromHexString(hex) else { return defaultColor }
        return Color(UIColor(cgColor: cg))
    }
}

