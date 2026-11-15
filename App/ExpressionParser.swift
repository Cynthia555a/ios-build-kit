//
//  ExpressionParser.swift
//  表达式分词 + 递归下降求值（支持 + - × ÷ ^ % ! 括号、sin/cos/tan/ln/log/√、π 与 e 常量）
//

import Foundation

enum AngleMode: String {
    case deg = "DEG"
    case rad = "RAD"
}

enum CalcError: Error {
    case syntax
    case math
}

enum Token: Equatable {
    case number(Double)
    case op(Character)
    case percent
    case factorial
    case lparen
    case rparen
    case function(String)
}

enum Evaluator {
    static func evaluate(expression: String, angleMode: AngleMode) throws -> Double {
        let tokens = try tokenize(expression)
        if tokens.isEmpty { throw CalcError.syntax }
        var parser = Parser(tokens: tokens, angleMode: angleMode)
        let value = try parser.parse()
        if value.isNaN || value.isInfinite { throw CalcError.math }
        return value
    }

    private static func tokenize(_ input: String) throws -> [Token] {
        var tokens: [Token] = []
        let chars = Array(input)
        var i = 0

        while i < chars.count {
            let c = chars[i]

            if c == " " {
                i += 1
                continue
            }

            if c.isNumber || c == "." {
                var text = ""
                while i < chars.count, chars[i].isNumber || chars[i] == "." {
                    text.append(chars[i])
                    i += 1
                }
                guard let value = Double(text) else { throw CalcError.syntax }
                tokens.append(.number(value))
                continue
            }

            switch c {
            case "π":
                tokens.append(.number(Double.pi))
                i += 1
            case "e":
                tokens.append(.number(2.718281828459045))
                i += 1
            case "+", "-", "×", "÷", "*", "/":
                if c == "*" {
                    tokens.append(.op("×"))
                } else if c == "/" {
                    tokens.append(.op("÷"))
                } else {
                    tokens.append(.op(c))
                }
                i += 1
            case "^":
                tokens.append(.op("^"))
                i += 1
            case "%":
                tokens.append(.percent)
                i += 1
            case "!":
                tokens.append(.factorial)
                i += 1
            case "(":
                tokens.append(.lparen)
                i += 1
            case ")":
                tokens.append(.rparen)
                i += 1
            case "√":
                tokens.append(.function("√"))
                i += 1
            default:
                var name = ""
                while i < chars.count, chars[i].isLetter {
                    name.append(chars[i])
                    i += 1
                }
                if name.isEmpty { throw CalcError.syntax }
                if ["sin", "cos", "tan", "ln", "log"].contains(name) {
                    tokens.append(.function(name))
                } else {
                    throw CalcError.syntax
                }
            }
        }

        return tokens
    }
}

struct Parser {
    private let tokens: [Token]
    private let angleMode: AngleMode
    private var index: Int = 0

    init(tokens: [Token], angleMode: AngleMode) {
        self.tokens = tokens
        self.angleMode = angleMode
    }

    mutating func parse() throws -> Double {
        let value = try parseExpr()
        if index != tokens.count { throw CalcError.syntax }
        return value
    }

    private func peek() -> Token? {
        index < tokens.count ? tokens[index] : nil
    }

    private func isValueStart(_ token: Token) -> Bool {
        switch token {
        case .number, .lparen, .function:
            return true
        default:
            return false
        }
    }

    private mutating func parseExpr() throws -> Double {
        var value = try parseTerm()
        while let token = peek() {
            guard case .op(let c) = token, c == "+" || c == "-" else { break }
            index += 1
            let rhs = try parseTerm()
            value = (c == "+") ? value + rhs : value - rhs
        }
        return value
    }

    private mutating func parseTerm() throws -> Double {
        var value = try parseUnary()
        while let token = peek() {
            if case .op(let c) = token, c == "×" || c == "÷" {
                index += 1
                let rhs = try parseUnary()
                if c == "÷" {
                    if rhs == 0 { throw CalcError.math }
                    value /= rhs
                } else {
                    value *= rhs
                }
                continue
            }
            if isValueStart(token) {
                let rhs = try parseUnary()
                value *= rhs
                continue
            }
            break
        }
        return value
    }

    private mutating func parseUnary() throws -> Double {
        if let token = peek(), case .op(let c) = token, c == "-" || c == "+" {
            index += 1
            let value = try parseUnary()
            return c == "-" ? -value : value
        }
        return try parsePower()
    }

    private mutating func parsePower() throws -> Double {
        let base = try parsePostfix()
        if let token = peek(), case .op(let c) = token, c == "^" {
            index += 1
            let exponent = try parseUnary()
            return pow(base, exponent)
        }
        return base
    }

    private mutating func parsePostfix() throws -> Double {
        var value = try parsePrimary()
        while let token = peek() {
            if case .percent = token {
                index += 1
                value /= 100
                continue
            }
            if case .factorial = token {
                index += 1
                value = try factorial(value)
                continue
            }
            break
        }
        return value
    }

    private func factorial(_ value: Double) throws -> Double {
        if value < 0 || value != value.rounded() || value > 170 {
            throw CalcError.math
        }
        let n = Int(value)
        var result = 1.0
        var i = 2
        while i <= n {
            result *= Double(i)
            i += 1
        }
        return result
    }

    private mutating func parsePrimary() throws -> Double {
        guard let token = peek() else { throw CalcError.syntax }

        switch token {
        case .number(let value):
            index += 1
            return value

        case .lparen:
            index += 1
            let value = try parseExpr()
            guard let next = peek(), case .rparen = next else { throw CalcError.syntax }
            index += 1
            return value

        case .function(let name):
            index += 1
            if let next = peek(), case .lparen = next {
                index += 1
                let value = try parseExpr()
                guard let close = peek(), case .rparen = close else { throw CalcError.syntax }
                index += 1
                return try apply(name, value)
            }
            let value = try parsePrimary()
            return try apply(name, value)

        case .op(let c) where c == "-":
            index += 1
            let value = try parseUnary()
            return -value

        default:
            throw CalcError.syntax
        }
    }

    private func apply(_ name: String, _ value: Double) throws -> Double {
        switch name {
        case "sin":
            return sin(angleMode == .deg ? value * Double.pi / 180 : value)
        case "cos":
            return cos(angleMode == .deg ? value * Double.pi / 180 : value)
        case "tan":
            return tan(angleMode == .deg ? value * Double.pi / 180 : value)
        case "ln":
            if value <= 0 { throw CalcError.math }
            return log(value)
        case "log":
            if value <= 0 { throw CalcError.math }
            return log10(value)
        case "√":
            if value < 0 { throw CalcError.math }
            return sqrt(value)
        default:
            throw CalcError.syntax
        }
    }
}
