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
    @State private var leftButtonGlobalX: CGFloat = 0
    @State private var rightButtonGlobalX: CGFloat = 0
    @State private var isDraggingLeft = false
    @State private var isDraggingRight = false

    var body: some View {
        HStack {
            GeometryReader { geo in
                VStack {
                    Spacer()
                    Button {} label: {
                        Spacer().frame(width: Constants.VECap.buttonPadding)
                        Image(systemName: "chevron.compact.left")
                    }
                    .frame(width: Constants.VECap.buttonWidth)
                    .highPriorityGesture(DragGesture(minimumDistance: 0,
                                                     coordinateSpace: CoordinateSpace.named("captionSpace"))
                        .onChanged({ value in
                            item.side = .left
                            self.viewModel.udpatePoints(for: item, x: value.location.x)

                            // Track global position
                            isDraggingLeft = true
                            leftButtonGlobalX = geo.frame(in: .global).midX
                        })
                            .onEnded({ _ in
                                item.isChanging = false
                                viewModel.checkAvailibility()
                                simpleSuccess(style: .soft)
                                isDraggingLeft = false
                                stopAutoScroll()
                            })
                    )
                    Spacer()
                }
                .onChange(of: leftButtonGlobalX) { newX in
                    if isDraggingLeft {
                        checkEdgePosition(x: newX)
                    }
                }
            }
            .frame(width: Constants.VECap.buttonWidth)
            Spacer()
            Text(item.captionText)
                .multilineTextAlignment(.leading)
                .font(Font.roboto(size: 14))
                .lineLimit(Constants.VECap.textLineLimit)
                .foregroundColor(colorFromHex(item.textColorHex, default: .white))
            Spacer()
            GeometryReader { geo in
                VStack {
                    Spacer()
                    Button {} label: {
                        Image(systemName: "chevron.compact.right")
                        Spacer().frame(width: Constants.VECap.buttonPadding)
                    }
                    .frame(width: Constants.VECap.buttonWidth)
                    .highPriorityGesture(DragGesture(minimumDistance: 0,
                                                     coordinateSpace: CoordinateSpace.named("captionSpace"))
                        .onChanged({ value in
                            item.side = .right
                            self.viewModel.udpatePoints(for: item, x: value.location.x)

                            // Track global position
                            isDraggingRight = true
                            rightButtonGlobalX = geo.frame(in: .global).midX
                        })
                            .onEnded({ _ in
                                item.isChanging = false
                                viewModel.checkAvailibility()
                                simpleSuccess(style: .soft)
                                isDraggingRight = false
                                stopAutoScroll()
                            })
                    )
                    Spacer()
                }
                .onChange(of: rightButtonGlobalX) { newX in
                    if isDraggingRight {
                        checkEdgePosition(x: newX)
                    }
                }
            }
            .frame(width: Constants.VECap.buttonWidth)
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
    
    private func stopAutoScroll() {
        timer?.invalidate()
        timer = nil
        isStartedTimer = false
        viewModel.checkAvailibility()
        viewModel.editorStates.isAutoScrolling = false
    }

    private func simpleSuccess(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    private func checkEdgePosition(x: CGFloat) {
        let leftEdge = UIScreen.screenWidth.percentageWith(percent: 10)
        let rightEdge = UIScreen.screenWidth.percentageWith(percent: 90)

        let isAtLeftEdge = x < leftEdge
        let isAtRightEdge = x > rightEdge

        if isAtLeftEdge || isAtRightEdge {
            if !isStartedTimer {
                // Smoother scrolling: 60 FPS (update every ~0.0167 seconds)
                timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [self] _ in
                    handleAutoScroll(isLeft: isAtLeftEdge)
                }
                viewModel.editorStates.isAutoScrolling = true
                isStartedTimer = true
            }
        } else {
            if isStartedTimer {
                stopAutoScroll()
            }
        }
    }

    private func handleAutoScroll(isLeft: Bool) {
        // Scroll at ~2 seconds per second of video = smoother movement
        let changePerFrame: Double = 2.0 / 60.0
        if isLeft {
            viewModel.playerConfig.currentTime -= changePerFrame
        } else {
            viewModel.playerConfig.currentTime += changePerFrame
        }
    }
    
    private func colorFromHex(_ hex: String?, default defaultColor: Color) -> Color {
        guard let cg = CGColor.fromHexString(hex) else { return defaultColor }
        return Color(UIColor(cgColor: cg))
    }
}

