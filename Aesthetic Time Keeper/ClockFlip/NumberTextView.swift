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
                .font(Font(UIFont.systemFont(ofSize: fontSize, weight: .init(0.9))))
                .foregroundStyle(foreground)
                .shadow(color: .white, radius: 2)
                .lineLimit(1)
                .drawingGroup()
            
            Rectangle()
                .fill(.white)
                .frame(height: 2)
                .zIndex(10)
        }
    }
}
