//
//  ContentView.swift
//  Aesthetic Time Keeper
//
//  Created by Sandeep Kumar on 28/12/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ClockFlipViewUsage(modelContext: modelContext)
    }
}

#Preview {
    ContentView()
}
