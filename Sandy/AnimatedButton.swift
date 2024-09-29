//
//  AnimatedButton.swift
//  Sandy
//
//  Created by 郭粟閣 on 2024/9/27.
//

import SwiftUI

struct AnimatedButton: View {
    let text: String
    let action: () -> Void
    var lightBackgroundColor: Color = .black // 浅色模式的背景颜色
    var darkBackgroundColor: Color = .white  // 深色模式的背景颜色
    var foregroundColor: Color = .white      // 文本颜色
    var cornerRadius: CGFloat = 300          // 圆角大小
    var horizontalPadding: CGFloat = 16      // 水平内边距
    var verticalPadding: CGFloat = 12        // 垂直内边距

    @State private var isSelected = false
    @State private var showCheck = false

    // 获取当前的颜色模式 (浅色模式或深色模式)
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isSelected = true
                showCheck = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                action()
                isSelected = false
                showCheck = false
            }
        }) {
            ZStack {
                Text(text)
                    .blur(radius: isSelected ? 3 : 0)
                    .opacity(isSelected ? 0.3 : 1)
                if showCheck {
                    Image(systemName: "checkmark")
                        .foregroundColor(foregroundColor)
                        .font(.system(size: 20, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .foregroundColor(colorScheme == .dark ? lightBackgroundColor : darkBackgroundColor) // 动态文本颜色
        .background(colorScheme == .dark ? darkBackgroundColor : lightBackgroundColor) // 动态背景颜色
        .cornerRadius(cornerRadius)
    }
}
