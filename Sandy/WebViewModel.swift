//
//  WebViewModel.swift
//  Sandy
//
//  Created by 郭粟閣 on 2024/9/28.
//

import SwiftUI
import Combine
import WebKit

class WebViewModel: ObservableObject {
    @Published var predictedLabels: [Int: String]? = nil // 使用字典來保存多個標籤
    var predictedLabelsPublisher: Published<[Int: String]?>.Publisher { $predictedLabels }

    weak var webView: WKWebView? // 保存 WKWebView 的弱引用
}
