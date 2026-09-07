//
//  TimeKeeperWidgetsBundle.swift
//  TimeKeeperWidgets
//
//  Created by Sandeep Kumar on 07/09/26.
//

import WidgetKit
import SwiftUI

@main
struct TimeKeeperWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TimeKeeperWidgets()
        TimeKeeperWidgetsControl()
        TimeKeeperWidgetsLiveActivity()
    }
}
