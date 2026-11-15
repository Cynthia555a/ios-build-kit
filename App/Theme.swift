//
//  Theme.swift
//  配色与触感反馈
//

import SwiftUI
import UIKit

enum Theme {
    static let background = Color(red: 0.055, green: 0.055, blue: 0.065)
    static let numberKey = Color(red: 0.196, green: 0.196, blue: 0.216)
    static let secondaryKey = Color(red: 0.353, green: 0.353, blue: 0.380)
    static let scientificKey = Color(red: 0.137, green: 0.137, blue: 0.157)
    static let accent = Color(red: 1.0, green: 0.584, blue: 0.0)
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.60, green: 0.60, blue: 0.64)
}

enum Haptics {
    static func tap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
}
