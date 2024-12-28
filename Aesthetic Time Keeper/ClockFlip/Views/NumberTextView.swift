//
//  NumberTextView.swift
//  AnimationsPracticeSwiftUI
//
//  Created by Sandeep Kumar on 28/12/24.
//

import SwiftUI

struct NumberTextView: View {
    let value: Int
    let fontSize: CGFloat
    let foreground: Color
    
    var body: some View {
        ZStack {
            Text("\(value)")
                .font(Font(UIFont.systemFont(ofSize: fontSize, weight: .init(0.5))))
                .foregroundStyle(foreground)
                .lineLimit(1)
                .drawingGroup()
            
            Rectangle()
                .fill(.white)
                .frame(height: 1.5)
                .zIndex(10)
        }
    }
}
