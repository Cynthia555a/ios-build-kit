//
//  NumberFormat.swift
//  数字显示格式化（千分位、科学计数法、续算用的纯数字串）
//

import Foundation

enum NumberFormat {
    private static let displayFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        formatter.decimalSeparator = "."
        formatter.maximumFractionDigits = 10
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private static let plainFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.decimalSeparator = "."
        formatter.maximumFractionDigits = 10
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    /// 屏幕上显示用（带千分位）
    static func text(_ value: Double) -> String {
        if value.isNaN || value.isInfinite { return "错误" }
        let magnitude = abs(value)
        if magnitude >= 1e12 || (magnitude > 0 && magnitude < 1e-9) {
            return String(format: "%.6e", value)
        }
        return displayFormatter.string(from: NSNumber(value: value)) ?? "0"
    }

    /// 继续计算用（不带千分位，可被再次解析）
    static func plain(_ value: Double) -> String {
        if value.isNaN || value.isInfinite { return "0" }
        let magnitude = abs(value)
        if magnitude >= 1e15 {
            return String(format: "%.0f", value)
        }
        return plainFormatter.string(from: NSNumber(value: value)) ?? "0"
    }
}
