//
//  ClockFlip.swift
//  AnimationsPracticeSwiftUI
//
//  Created by Sandeep Kumar on 22/12/24.
//

import SwiftUI

struct NumberFlipView: View {
    @Binding var value: Int
    var foreground: Color
    var background: Color
    var size: CGSize
    var fontSize: CGFloat
    var cornerRadius: CGFloat
    var animationDuration: CGFloat
    var halfHeight: CGFloat {
        size.height * 0.5
    }
    
    @State private var nextValue: Int = 1
    @State private var currentValue: Int = 0
    @State private var rotation: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Behind view
            UnevenRoundedRectangle(topLeadingRadius: cornerRadius,
                                   bottomLeadingRadius : 0,
                                   bottomTrailingRadius: 0,
                                   topTrailingRadius: cornerRadius)
            .fill(background)
            .frame (height: halfHeight)
            .overlay(alignment: .top, content: {
                NumberTextView(value: nextValue, fontSize: fontSize, foreground: foreground)
                    .frame(width: size.width, height: size.height)
            })
            .clipped()
            .frame(maxHeight: .infinity, alignment: .top)
            
            // View which you see rotating
            UnevenRoundedRectangle(topLeadingRadius: cornerRadius,
                                   bottomLeadingRadius : 0,
                                   bottomTrailingRadius: 0,
                                   topTrailingRadius: cornerRadius)
            .fill(background.shadow(.inner(radius: 1)))
            .frame (height: halfHeight)
            .modifier(
                RotationModifier(rotation: rotation,
                                 currentValue: currentValue,
                                 nextValue: nextValue,
                                 fontSize: fontSize,
                                 foreground: foreground,
                                 size: size)
            )
            .clipped()
            .rotation3DEffect(.degrees(rotation),
                              axis: (x: 1, y: 0, z: 0),
                              anchor: .bottom,
                              perspective: 0.4)
            .frame (maxHeight: .infinity, alignment: .top)
            .zIndex(10)
            
            // Bottom View
            UnevenRoundedRectangle(topLeadingRadius: 0,
                                   bottomLeadingRadius: cornerRadius,
                                   bottomTrailingRadius: cornerRadius,
                                   topTrailingRadius: 0)
            .fill(background.shadow(.inner(radius: 1)))
            .frame(height: halfHeight)
            .overlay(alignment: .bottom, content: {
                NumberTextView(value: currentValue, fontSize: fontSize, foreground: foreground)
                    .frame(width: size.width, height: size.height)
            })
            .clipped()
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(width: size.width, height: size.height)
        .onChange(of: value, initial: true) { oldValue, newValue in
            updateCurrentValuePostAnimation = true
            currentValue = oldValue
            nextValue = newValue
            
            guard rotation == 0 else {
                updateCurrentValuePostAnimation = false
                currentValue = newValue
                return
            }
            guard oldValue != newValue else { return }
            
            withAnimation(.easeInOut(duration: animationDuration),
                          completionCriteria: .logicallyComplete) {
                rotation = -180
            } completion: {
                rotation = 0
                guard updateCurrentValuePostAnimation else {
                    updateCurrentValuePostAnimation = true
                    return
                }
                
                currentValue = newValue
            }
        }
    }
    
    // This is added because rotation moves back to 0 when update update the count to 0.
    // At this point, I wasn't able to figure out why updating the value is making this mess.
    // Blocking the update once rotation 0 is hit prevents the previous animation that is ongoing to
    // complete and render a hude mess on the board, since we have already decided what the
    // new value is.
    @State var updateCurrentValuePostAnimation = true
}

fileprivate struct RotationModifier: ViewModifier, Animatable {
    var rotation: CGFloat
    var currentValue: Int
    var nextValue: Int
    var fontSize: CGFloat
    var foreground: Color
    var size: CGSize
    
    var animatableData: CGFloat {
        get { rotation }
        set { rotation = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                Group {
                    if -rotation > 90 {
                        NumberTextView(value: nextValue, fontSize: fontSize, foreground: foreground)
                            .scaleEffect(x: 1, y: -1)
                            .transition(.identity)
                    } else {
                        NumberTextView(value: currentValue, fontSize: fontSize, foreground: foreground)
                            .transition(.identity)
                    }
                }
                .frame(width: size.width, height: size.height)
                .drawingGroup()
            }
    }
}

#Preview {
    ClockFlipViewUsage(config: .stopwatch(startTime: 100))
        .preferredColorScheme(.light)
}
