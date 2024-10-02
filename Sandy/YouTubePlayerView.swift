//
//  YouTubePlayerView.swift
//  Sandy
//
//  Created by 郭粟閣 on 2024/10/2.
//
import SwiftUI
import WebKit

// MARK: - YouTube 影片播放器視圖
struct YouTubePlayerView: UIViewRepresentable {
    let videoID: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        // 允許自動播放
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let youtubeURL = URL(string: "https://www.youtube.com/embed/\(videoID)?playsinline=1") else {
            return
        }
        let request = URLRequest(url: youtubeURL)
        uiView.load(request)
    }
}
