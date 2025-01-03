//
//  ContentView.swift
//  Aesthetic Time Keeper
//
//  Created by Sandeep Kumar on 28/12/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        ClockFlipViewUsage(config: .timer(maxCountInSeconds: 300))
    }
}

#Preview {
    ContentView()
}
