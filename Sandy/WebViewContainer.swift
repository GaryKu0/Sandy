import SwiftUI
import WebKit
import AVFoundation

// Array 擴展，安全訪問元素
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct WebViewContainer: UIViewRepresentable {
    @Binding var inputImage: UIImage?
    @Binding var outputText: String
    @Binding var isProcessing: Bool
    @Binding var predictedLabels: [Int: String]?
    @Binding var currentTask: Task?
    @Binding var tasks: [Task] // 傳遞任務列表

    @EnvironmentObject var webViewModel: WebViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()

        // 注入 JavaScript 代碼以攔截 console 日誌和處理消息
        let jsCode = """
            (function() {
                var console = window.console;
                if (!console) {
                    console = {};
                    window.console = console;
                }
                function sendMessageToNative(level, args) {
                    window.webkit.messageHandlers.consoleHandler.postMessage({ level: level, message: Array.from(args).join(' ') });
                }
                var levels = ['log', 'debug', 'info', 'warn', 'error'];
                for (var i = 0; i < levels.length; i++) {
                    (function(level) {
                        var original = console[level];
                        console[level] = function() {
                            sendMessageToNative(level, arguments);
                            if (original) {
                                original.apply(console, arguments);
                            }
                        };
                    })(levels[i]);
                }
            })();
            """
        let userScript = WKUserScript(source: jsCode, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(userScript)
        userContentController.add(context.coordinator, name: "consoleHandler")
        userContentController.add(context.coordinator, name: "callbackHandler")

        config.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webViewModel.webView = webView
        context.coordinator.webView = webView

        // 加載本地 HTML 文件（假設有一個 index.html 在項目中）
        if let htmlPath = Bundle.main.path(forResource: "index", ofType: "html") {
            let url = URL(fileURLWithPath: htmlPath)
            let readAccessURL = url.deletingLastPathComponent()
            webView.loadFileURL(url, allowingReadAccessTo: readAccessURL)
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if isProcessing, let image = inputImage, let task = currentTask {
            guard let imageData = image.jpegData(compressionQuality: 1) else {
                print("無法轉換圖片為JPEG數據")
                self.outputText = "錯誤: 無法處理圖片。"
                self.isProcessing = false
                return
            }
            let base64String = imageData.base64EncodedString()

            let js = "processImageData('\(base64String)')"
            uiView.evaluateJavaScript(js) { _, error in
                if let error = error {
                    print("evaluateJavaScript 錯誤: \(error.localizedDescription)")
                    self.outputText = "錯誤: \(error.localizedDescription)"
                    self.isProcessing = false
                } else {
                    print("evaluateJavaScript 成功執行")
                }
            }
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebViewContainer
        weak var webView: WKWebView?

        init(_ parent: WebViewContainer) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("WebView 加載完成")
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "callbackHandler", let predictionsString = message.body as? String {
                DispatchQueue.main.async {
                    self.parent.isProcessing = false
                    guard let currentTask = self.parent.currentTask else {
                        print("當前沒有任務")
                        return
                    }

                    let predictionsArray = predictionsString.components(separatedBy: ",").compactMap { Double($0) }
                    let sortedKeys = currentTask.indexToLabelMap.keys.sorted()
                    let labels = sortedKeys.map { currentTask.indexToLabelMap[$0] ?? "未知" }

                    print("模型輸出值: \(predictionsArray)")
                    print("標籤對應: \(labels)")

                    if predictionsArray.count >= sortedKeys.count {
                        var adjustedPredictions = [Double]()
                        for key in sortedKeys {
                            if let label = currentTask.indexToLabelMap[key],
                               let multiplier = currentTask.multipliers[label] {
                                if key < predictionsArray.count {
                                    adjustedPredictions.append(predictionsArray[key] * multiplier)
                                } else {
                                    adjustedPredictions.append(0.0)
                                }
                            } else {
                                if key < predictionsArray.count {
                                    adjustedPredictions.append(predictionsArray[key])
                                } else {
                                    adjustedPredictions.append(0.0)
                                }
                            }
                        }

                        print("調整後的預測值: \(adjustedPredictions)")

                        // 檢查條件是否達成
                        let expectedConditionsMet = currentTask.expectedConditions.allSatisfy { (key, condition) in
                            if let sortedIndex = sortedKeys.firstIndex(of: key),
                               sortedIndex < adjustedPredictions.count,
                               adjustedPredictions[sortedIndex] >= 0.5 {
                                return labels[sortedIndex] == condition
                            }
                            return false
                        }

                        print("條件達成: \(expectedConditionsMet)")

                        if expectedConditionsMet {
                            // 設置 predictedLabels 為達成的條件
                            let metLabels = currentTask.expectedConditions.compactMap { (key, condition) -> (Int, String)? in
                                if let sortedIndex = sortedKeys.firstIndex(of: key),
                                   sortedIndex < adjustedPredictions.count,
                                   adjustedPredictions[sortedIndex] >= 0.5 {
                                    return (key, labels[sortedIndex])
                                }
                                return nil
                            }
                            self.parent.predictedLabels = Dictionary(uniqueKeysWithValues: metLabels)
                            print("達成的標籤: \(self.parent.predictedLabels ?? [:])")
                            // 通知 ContentView 條件達成
                            NotificationCenter.default.post(name: .taskConditionMet, object: currentTask.name)
                        } else {
                            // 設置 predictedLabels 為當前偵測到的所有標籤
                            let detectedLabels = currentTask.expectedConditions.compactMap { (key, condition) -> (Int, String)? in
                                if let sortedIndex = sortedKeys.firstIndex(of: key),
                                   sortedIndex < adjustedPredictions.count,
                                   adjustedPredictions[sortedIndex] >= 0.5 {
                                    return (key, labels[sortedIndex])
                                }
                                return nil
                            }
                            self.parent.predictedLabels = Dictionary(uniqueKeysWithValues: detectedLabels)
                            print("偵測到的標籤: \(self.parent.predictedLabels ?? [:])")
                            // 通知 ContentView 條件未達成
                            NotificationCenter.default.post(name: .taskConditionNotMet, object: nil)
                        }
                    } else {
                        print("預測數據不足")
                        self.parent.outputText = "預測數據不足"
                    }
                }
            }
        }
    }
}

extension Notification.Name {
    static let taskConditionMet = Notification.Name("taskConditionMet")
    static let taskConditionNotMet = Notification.Name("taskConditionNotMet")
}
