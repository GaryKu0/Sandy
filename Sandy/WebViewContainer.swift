import SwiftUI
import WebKit
import AVFoundation

// Array extension for safe access
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
    @Binding var tasks: [Task]

    @EnvironmentObject var webViewModel: WebViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()

        // If you need to inject JavaScript code
        // let jsCode = """
        //     // Your JavaScript code
        //     """
        // let userScript = WKUserScript(source: jsCode, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        // userContentController.addUserScript(userScript)
        userContentController.add(context.coordinator, name: "consoleHandler")
        userContentController.add(context.coordinator, name: "callbackHandler")

        config.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isHidden = true
        webView.navigationDelegate = context.coordinator
        webViewModel.webView = webView
        context.coordinator.webView = webView

        // Load local HTML file (assuming you have an index.html in your project)
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
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    DispatchQueue.main.async {
                        print("Unable to convert image to JPEG data")
                        self.outputText = "Error: Unable to process image."
                        self.isProcessing = false
                    }
                    return
                }
                let base64String = imageData.base64EncodedString()
                // Escape base64 string to prevent issues in JavaScript
                let escapedBase64String = base64String.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
                self.processImageInJavaScript(base64Image: escapedBase64String, mediapipeTasks: task.mediapipeTasks, modelName: task.modelName)
            }
        }
    }

    func processImageInJavaScript(base64Image: String, mediapipeTasks: [String], modelName: String) {
        let tasksString = mediapipeTasks.joined(separator: ",")
        let jsFunction = "processImageData('\(base64Image)', '\(tasksString)', '\(modelName)')"
        DispatchQueue.main.async {
            webViewModel.webView?.evaluateJavaScript(jsFunction) { (result, error) in
                if let error = error {
                    print("JavaScript evaluation error: \(error)")
                    self.outputText = "Error: \(error.localizedDescription)"
                    self.isProcessing = false
                } else {
                    print("JavaScript function executed successfully")
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
            print("WebView finished loading")
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "callbackHandler", let predictionsString = message.body as? String {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.parent.isProcessing = false
                    guard let currentTask = self.parent.currentTask else {
                        print("No current task")
                        return
                    }

                    let predictionsArray = predictionsString.components(separatedBy: ",").compactMap { Double($0) }
                    let sortedKeys = currentTask.indexToLabelMap.keys.sorted()
                    let labels = sortedKeys.map { currentTask.indexToLabelMap[$0] ?? "Unknown" }

                    print("Model output values: \(predictionsArray)")
                    print("Label mapping: \(labels)")

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

                        print("Adjusted predictions: \(adjustedPredictions)")

                        // Check if conditions are met
                        let expectedConditionsMet = currentTask.expectedConditions.allSatisfy { (key, condition) in
                            if let sortedIndex = sortedKeys.firstIndex(of: key),
                               sortedIndex < adjustedPredictions.count,
                               adjustedPredictions[sortedIndex] >= 0.5 {
                                return labels[sortedIndex] == condition
                            }
                            return false
                        }

                        print("Conditions met: \(expectedConditionsMet)")

                        DispatchQueue.main.async {
                            if expectedConditionsMet {
                                // Set predictedLabels to the met conditions
                                let metLabels = currentTask.expectedConditions.compactMap { (key, condition) -> (Int, String)? in
                                    if let sortedIndex = sortedKeys.firstIndex(of: key),
                                       sortedIndex < adjustedPredictions.count,
                                       adjustedPredictions[sortedIndex] >= 0.5 {
                                        return (key, labels[sortedIndex])
                                    }
                                    return nil
                                }
                                self.parent.predictedLabels = Dictionary(uniqueKeysWithValues: metLabels)
                                print("Met labels: \(self.parent.predictedLabels ?? [:])")
                                // Notify ContentView that conditions are met
                                NotificationCenter.default.post(name: .taskConditionMet, object: currentTask.name)
                            } else {
                                // Set predictedLabels to currently detected labels
                                let detectedLabels = currentTask.expectedConditions.compactMap { (key, condition) -> (Int, String)? in
                                    if let sortedIndex = sortedKeys.firstIndex(of: key),
                                       sortedIndex < adjustedPredictions.count,
                                       adjustedPredictions[sortedIndex] >= 0.5 {
                                        return (key, labels[sortedIndex])
                                    }
                                    return nil
                                }
                                self.parent.predictedLabels = Dictionary(uniqueKeysWithValues: detectedLabels)
                                print("Detected labels: \(self.parent.predictedLabels ?? [:])")
                                // Notify ContentView that conditions are not met
                                NotificationCenter.default.post(name: .taskConditionNotMet, object: nil)
                            }
                        }
                    } else {
                        print("Insufficient prediction data")
                        DispatchQueue.main.async {
                            self.parent.outputText = "Insufficient prediction data"
                        }
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
