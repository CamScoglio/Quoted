//
//  QuotedWidgetBundle.swift
//  QuotedWidget
//
//  Created by Cam Scoglio on 6/25/25.
//

import WidgetKit
import SwiftUI

struct QuotedWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuotedWidget()
        QuotedWidgetControl()
        QuotedWidgetLiveActivity()
    }
}
