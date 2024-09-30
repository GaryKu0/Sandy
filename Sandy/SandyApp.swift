//
//  SandyApp.swift
//  Sandy
//
//  Created by 郭粟閣 on 2024/9/27.
//

import SwiftUI
import SwiftData

@main
struct SandyApp: App {
    @StateObject var webViewModel = WebViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(webViewModel)
        }
    }
}
