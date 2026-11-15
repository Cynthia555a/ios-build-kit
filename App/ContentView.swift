//
//  ContentView.swift
//  计算器主界面
//

import SwiftUI

struct ContentView: View {

    @StateObject private var model = CalcModel()
    @State private var showHistory = false

    private enum KeyKind {
        case number
        case function
        case accent
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 8) {
                header
                display
                if model.isScientific {
                    scientificPad
                }
                mainPad
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 10)
        }
        .sheet(isPresented: $showHistory) {
            HistoryView(model: model)
        }
    }

    // MARK: - 顶部按钮

    private var header: some View {
        HStack(spacing: 10) {
            Button(action: { showHistory = true }) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Theme.scientificKey)
                    .clipShape(Circle())
            }
            .buttonStyle(KeyPressStyle())

            Spacer()

            if model.isScientific {
                Button(action: {
                    model.angleMode = (model.angleMode == .deg) ? .rad : .deg
                    Haptics.tap()
                }) {
                    Text(model.angleMode.rawValue)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.accent)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(Theme.scientificKey)
                        .clipShape(Capsule())
                }
                .buttonStyle(KeyPressStyle())
            }

            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    model.isScientific.toggle()
                }
                Haptics.tap()
            }) {
                Image(systemName: "function")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(model.isScientific ? Theme.accent : Theme.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Theme.scientificKey)
                    .clipShape(Circle())
            }
            .buttonStyle(KeyPressStyle())
        }
    }

    // MARK: - 显示屏

    private var display: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(model.subText)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text(model.mainText)
                .font(.system(size: 50, weight: .light, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.28)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 6)
    }

    // MARK: - 科学键面板

    private var scientificPad: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                scientificKey("sin", .function("sin("))
                scientificKey("cos", .function("cos("))
                scientificKey("tan", .function("tan("))
                scientificKey("ln", .function("ln("))
                scientificKey("log", .function("log("))
            }
            HStack(spacing: 8) {
                scientificKey("√", .function("√("))
                scientificKey("x^y", .op("^"))
                scientificKey("(", .openParen)
                scientificKey(")", .closeParen)
                scientificKey("π", .constant("π"))
            }
        }
        .transition(.opacity)
    }

    private func scientificKey(_ title: String, _ key: CalcKey) -> some View {
        Button(action: {
            model.tap(key)
            Haptics.tap()
        }) {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(Theme.scientificKey)
                .clipShape(Capsule())
        }
        .buttonStyle(KeyPressStyle())
    }

    // MARK: - 主键盘

    private var mainPad: some View {
        GeometryReader { geometry in
            let gap: CGFloat = 9
            let byWidth = (geometry.size.width - gap * 3) / 4
            let byHeight = (geometry.size.height - gap * 4) / 5
            let diameter = max(20, min(byWidth, byHeight))

            VStack(spacing: gap) {
                HStack(spacing: gap) {
                    keyButton("AC", .clear, kind: .function, size: diameter)
                    keyButton("⌫", .backspace, kind: .function, size: diameter)
                    keyButton("%", .percent, kind: .function, size: diameter)
                    keyButton("÷", .op("÷"), kind: .accent, size: diameter)
                }
                HStack(spacing: gap) {
                    keyButton("7", .digit("7"), kind: .number, size: diameter)
                    keyButton("8", .digit("8"), kind: .number, size: diameter)
                    keyButton("9", .digit("9"), kind: .number, size: diameter)
                    keyButton("×", .op("×"), kind: .accent, size: diameter)
                }
                HStack(spacing: gap) {
                    keyButton("4", .digit("4"), kind: .number, size: diameter)
                    keyButton("5", .digit("5"), kind: .number, size: diameter)
                    keyButton("6", .digit("6"), kind: .number, size: diameter)
                    keyButton("−", .op("-"), kind: .accent, size: diameter)
                }
                HStack(spacing: gap) {
                    keyButton("1", .digit("1"), kind: .number, size: diameter)
                    keyButton("2", .digit("2"), kind: .number, size: diameter)
                    keyButton("3", .digit("3"), kind: .number, size: diameter)
                    keyButton("+", .op("+"), kind: .accent, size: diameter)
                }
                HStack(spacing: gap) {
                    keyButton("±", .sign, kind: .function, size: diameter)
                    keyButton("0", .digit("0"), kind: .number, size: diameter)
                    keyButton(".", .digit("."), kind: .number, size: diameter)
                    keyButton("=", .equals, kind: .accent, size: diameter)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
        }
    }

    private func keyButton(_ title: String, _ key: CalcKey, kind: KeyKind, size: CGFloat) -> some View {
        Button(action: {
            model.tap(key)
            Haptics.tap()
        }) {
            Text(title)
                .font(.system(size: size * 0.38, weight: .medium, design: .rounded))
                .foregroundColor(kind == .function ? Theme.background : Theme.textPrimary)
                .frame(width: size, height: size)
                .background(backgroundColor(for: kind))
                .clipShape(Circle())
        }
        .buttonStyle(KeyPressStyle())
    }

    private func backgroundColor(for kind: KeyKind) -> Color {
        switch kind {
        case .number:
            return Theme.numberKey
        case .function:
            return Theme.secondaryKey
        case .accent:
            return Theme.accent
        }
    }
}

struct KeyPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

struct HistoryView: View {

    @ObservedObject var model: CalcModel
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            List {
                if model.records.isEmpty {
                    Text("还没有计算记录")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.textSecondary)
                }
                ForEach(model.records) { record in
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(record.expression)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(1)
                        Text(record.result)
                            .font(.system(size: 19, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .onDelete { indexSet in
                    model.records.remove(atOffsets: indexSet)
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("历史记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("清空") {
                        model.records.removeAll()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(.dark)
    }
}
