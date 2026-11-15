//
//  CalcModel.swift
//  计算器状态机：处理每个按键对表达式的影响
//

import Foundation
import Combine

struct CalcRecord: Identifiable {
    let id = UUID()
    let expression: String
    let result: String
}

enum CalcKey {
    case digit(String)
    case op(String)
    case constant(String)
    case function(String)
    case openParen
    case closeParen
    case percent
    case factorial
    case square
    case reciprocal
    case sign
    case clear
    case backspace
    case equals
}

final class CalcModel: ObservableObject {

    @Published var expression: String = ""
    @Published var result: String = "0"
    @Published var isScientific: Bool = false
    @Published var angleMode: AngleMode = .deg
    @Published var records: [CalcRecord] = []
    @Published var justEvaluated: Bool = false

    private var lastResultRaw: String = ""

    // MARK: - 显示文本

    var mainText: String {
        if justEvaluated { return result }
        return expression.isEmpty ? "0" : expression
    }

    var subText: String {
        if justEvaluated { return expression }
        guard let preview = previewText else { return " " }
        return "= " + preview
    }

    private var previewText: String? {
        guard !expression.isEmpty else { return nil }
        guard let value = try? Evaluator.evaluate(expression: expression, angleMode: angleMode) else {
            return nil
        }
        let text = NumberFormat.text(value)
        if text == expression { return nil }
        return text
    }

    // MARK: - 按键

    func tap(_ key: CalcKey) {
        switch key {
        case .digit(let value):
            inputDigit(value)
        case .op(let value):
            inputOperator(value)
        case .constant(let value):
            inputConstant(value)
        case .function(let value):
            inputFunction(value)
        case .openParen:
            inputOpenParen()
        case .closeParen:
            inputCloseParen()
        case .percent:
            inputPostfix("%")
        case .factorial:
            inputPostfix("!")
        case .square:
            inputSuffix("^2")
        case .reciprocal:
            inputSuffix("^(-1)")
        case .sign:
            negateLastOperand()
        case .clear:
            clear()
        case .backspace:
            backspace()
        case .equals:
            evaluateNow()
        }
    }

    // MARK: - 各类输入

    private func isValueEnd(_ character: Character?) -> Bool {
        guard let character = character else { return false }
        if character.isNumber || character == "." { return true }
        if character == "π" || character == "e" { return true }
        if character == ")" || character == "%" || character == "!" { return true }
        return false
    }

    private func trailingNumberRange(in chars: [Character]) -> Range<Int> {
        var start = chars.count
        while start > 0, (chars[start - 1].isNumber || chars[start - 1] == ".") {
            start -= 1
        }
        return start..<chars.count
    }

    private func inputDigit(_ digit: String) {
        if justEvaluated {
            justEvaluated = false
            expression = ""
        }

        var chars = Array(expression)

        if chars.isEmpty {
            expression = (digit == ".") ? "0." : digit
            return
        }

        let last = chars[chars.count - 1]

        if last == ")" || last == "π" || last == "e" || last == "%" || last == "!" {
            chars.append("×")
            chars.append(contentsOf: Array(digit))
            expression = String(chars)
            return
        }

        if digit == "." {
            let range = trailingNumberRange(in: chars)
            if chars[range].contains(".") { return }
            if range.isEmpty { chars.append("0") }
            chars.append(".")
            expression = String(chars)
            return
        }

        let range = trailingNumberRange(in: chars)
        if !range.isEmpty, String(chars[range]) == "0" {
            chars.removeLast()
        }
        chars.append(contentsOf: Array(digit))
        expression = String(chars)
    }

    private func inputOperator(_ newOperator: String) {
        if justEvaluated {
            if result == "错误" { return }
            expression = lastResultRaw
            justEvaluated = false
        }

        var chars = Array(expression)

        if chars.isEmpty {
            if newOperator == "-" {
                expression = "-"
            }
            return
        }

        let last = chars[chars.count - 1]

        if last == "^", newOperator == "-" {
            chars.append("-")
            expression = String(chars)
            return
        }

        if last == "+" || last == "-" || last == "×" || last == "÷" || last == "^" {
            chars.removeLast()
            chars.append(contentsOf: Array(newOperator))
            expression = String(chars)
            return
        }

        if last == "(" {
            if newOperator == "-" {
                chars.append("-")
                expression = String(chars)
            }
            return
        }

        if last == "." {
            chars.append("0")
        }

        chars.append(contentsOf: Array(newOperator))
        expression = String(chars)
    }

    private func inputConstant(_ constant: String) {
        if justEvaluated {
            justEvaluated = false
            expression = ""
        }
        var chars = Array(expression)
        if isValueEnd(chars.last) { chars.append("×") }
        chars.append(contentsOf: Array(constant))
        expression = String(chars)
    }

    private func inputFunction(_ function: String) {
        if justEvaluated {
            justEvaluated = false
            expression = ""
        }
        var chars = Array(expression)
        if isValueEnd(chars.last) { chars.append("×") }
        chars.append(contentsOf: Array(function))
        expression = String(chars)
    }

    private func inputOpenParen() {
        if justEvaluated {
            justEvaluated = false
            expression = ""
        }
        var chars = Array(expression)
        if isValueEnd(chars.last) { chars.append("×") }
        chars.append("(")
        expression = String(chars)
    }

    private func inputCloseParen() {
        var depth = 0
        for character in expression {
            if character == "(" { depth += 1 }
            if character == ")" { depth -= 1 }
        }
        guard depth > 0 else { return }
        guard isValueEnd(expression.last) else { return }
        expression.append(contentsOf: ")")
    }

    private func inputPostfix(_ symbol: String) {
        guard isValueEnd(expression.last) else { return }
        if symbol == "%", expression.last == "%" { return }
        expression.append(contentsOf: symbol)
    }

    private func inputSuffix(_ suffix: String) {
        guard isValueEnd(expression.last) else { return }
        expression.append(contentsOf: suffix)
    }

    private func negateLastOperand() {
        if justEvaluated {
            if let raw = Double(lastResultRaw) {
                let negated = -raw
                expression = NumberFormat.plain(negated)
                result = NumberFormat.text(negated)
                lastResultRaw = NumberFormat.plain(negated)
            }
            justEvaluated = false
            return
        }

        var chars = Array(expression)
        guard !chars.isEmpty else { return }

        var end = chars.count
        while end > 0, (chars[end - 1] == "%" || chars[end - 1] == "!") {
            end -= 1
        }

        var start = end
        while start > 0 {
            let character = chars[start - 1]
            if character.isNumber || character == "." || character == "π" || character == "e" {
                start -= 1
            } else {
                break
            }
        }

        guard start < end else { return }

        if start > 0, chars[start - 1] == "-" {
            var isUnary = (start - 1 == 0)
            if start - 1 > 0 {
                let previous = chars[start - 2]
                isUnary = (previous == "+" || previous == "-" || previous == "×" || previous == "÷" || previous == "^" || previous == "(")
            }
            if isUnary {
                chars.remove(at: start - 1)
                expression = String(chars)
                return
            }
        }

        chars.insert("-", at: start)
        expression = String(chars)
    }

    private func clear() {
        expression = ""
        result = "0"
        lastResultRaw = ""
        justEvaluated = false
    }

    private func backspace() {
        if justEvaluated {
            justEvaluated = false
            expression = ""
            result = "0"
            return
        }

        let suffixes = ["sin(", "cos(", "tan(", "ln(", "log(", "√("]
        for suffix in suffixes where expression.hasSuffix(suffix) {
            expression.removeLast(suffix.count)
            return
        }

        if !expression.isEmpty {
            expression.removeLast()
        }
    }

    private func evaluateNow() {
        if justEvaluated { return }
        guard !expression.isEmpty else { return }

        guard let value = try? Evaluator.evaluate(expression: expression, angleMode: angleMode) else {
            result = "错误"
            justEvaluated = true
            return
        }

        let text = NumberFormat.text(value)
        result = text
        lastResultRaw = NumberFormat.plain(value)
        records.insert(CalcRecord(expression: expression, result: text), at: 0)
        if records.count > 100 {
            records.removeLast(records.count - 100)
        }
        justEvaluated = true
    }
}
