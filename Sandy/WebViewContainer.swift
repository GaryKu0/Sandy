import SwiftUI
import WebKit
import AVFoundation

// Array 扩展，安全访问元素
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
    @Binding var tasks: [Task] // 传递任务列表

    @EnvironmentObject var webViewModel: WebViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()

        // 注入 JavaScript 代码以拦截 console 日志和处理消息
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

        // 加载本地 HTML 文件（假设有一个 index.html 在项目中）
        if let htmlPath = Bundle.main.path(forResource: "index", ofType: "html") {
            let url = URL(fileURLWithPath: htmlPath)
            let readAccessURL = url.deletingLastPathComponent()
            webView.loadFileURL(url, allowingReadAccessTo: readAccessURL)
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if isProcessing, let image = inputImage, let task = currentTask {
            DispatchQueue.global(qos: .userInitiated).async {
                guard let imageData = image.jpegData(compressionQuality: 1) else {
                    DispatchQueue.main.async {
                        print("无法转换图片为JPEG数据")
                        self.outputText = "错误: 无法处理图片。"
                        self.isProcessing = false
                    }
                    return
                }
                let base64String = imageData.base64EncodedString()
                self.processImageInJavaScript(base64Image: base64String, mediapipeTasks: task.mediapipeTasks, modelName: task.modelName)
            }
        }
    }

    // 新增的函数，用于传递参数给 JavaScript
    func processImageInJavaScript(base64Image: String, mediapipeTasks: [String], modelName: String) {
        let tasksString = mediapipeTasks.joined(separator: ",")
        // 注意在这里传递了 mediapipeTasks 和 modelName
        let jsFunction = "processImageData('\(base64Image)', '\(tasksString)', '\(modelName)')"
        DispatchQueue.main.async {
            webViewModel.webView?.evaluateJavaScript(jsFunction) { (result, error) in
                if let error = error {
                    print("evaluateJavaScript 错误: \(error.localizedDescription)")
                    self.outputText = "错误: \(error.localizedDescription)"
                    self.isProcessing = false
                } else {
                    print("evaluateJavaScript 成功执行")
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
            print("WebView 加载完成")
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "consoleHandler" {
                if let body = message.body as? [String: Any],
                   let level = body["level"] as? String,
                   let msg = body["message"] as? String {
                    print("JavaScript \(level): \(msg)")
                }
            } else if message.name == "callbackHandler", let predictionsString = message.body as? String {
                DispatchQueue.main.async {
                    self.parent.isProcessing = false
                    guard let currentTask = self.parent.currentTask else {
                        print("当前没有任务")
                        return
                    }

                    let predictionsArray = predictionsString.components(separatedBy: ",").compactMap { Double($0) }
                    let sortedKeys = currentTask.indexToLabelMap.keys.sorted()
                    let labels = sortedKeys.map { currentTask.indexToLabelMap[$0] ?? "未知" }

                    print("模型输出值: \(predictionsArray)")
                    print("标签对应: \(labels)")

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

                        print("调整后的预测值: \(adjustedPredictions)")

                        // 检查条件是否达成
                        let expectedConditionsMet = currentTask.expectedConditions.allSatisfy { (key, condition) in
                            if let sortedIndex = sortedKeys.firstIndex(of: key),
                               sortedIndex < adjustedPredictions.count,
                               adjustedPredictions[sortedIndex] >= 0.5 {
                                return labels[sortedIndex] == condition
                            }
                            return false
                        }

                        print("条件达成: \(expectedConditionsMet)")

                        if expectedConditionsMet {
                            // 设置 predictedLabels 为达成的条件
                            let metLabels = currentTask.expectedConditions.compactMap { (key, condition) -> (Int, String)? in
                                if let sortedIndex = sortedKeys.firstIndex(of: key),
                                   sortedIndex < adjustedPredictions.count,
                                   adjustedPredictions[sortedIndex] >= 0.5 {
                                    return (key, labels[sortedIndex])
                                }
                                return nil
                            }
                            self.parent.predictedLabels = Dictionary(uniqueKeysWithValues: metLabels)
                            print("达成的标签: \(self.parent.predictedLabels ?? [:])")
                            // 通知 ContentView 条件达成
                            NotificationCenter.default.post(name: .taskConditionMet, object: currentTask.name)
                        } else {
                            // 设置 predictedLabels 为当前检测到的所有标签
                            let detectedLabels = currentTask.expectedConditions.compactMap { (key, condition) -> (Int, String)? in
                                if let sortedIndex = sortedKeys.firstIndex(of: key),
                                   sortedIndex < adjustedPredictions.count,
                                   adjustedPredictions[sortedIndex] >= 0.5 {
                                    return (key, labels[sortedIndex])
                                }
                                return nil
                            }
                            self.parent.predictedLabels = Dictionary(uniqueKeysWithValues: detectedLabels)
                            print("检测到的标签: \(self.parent.predictedLabels ?? [:])")
                            // 通知 ContentView 条件未达成
                            NotificationCenter.default.post(name: .taskConditionNotMet, object: nil)
                        }
                    } else {
                        print("预测数据不足")
                        self.parent.outputText = "预测数据不足"
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
