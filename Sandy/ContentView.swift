import SwiftUI
import AVFoundation
import WebKit
import Combine
import WhatsNewKit

// 主視圖 ContentView
struct ContentView: View {
    // MARK: - State Variables
    @State private var showSettings = false
    @State private var inputImage: UIImage?
    @State private var outputText: String = "準備中..."
    @State private var isProcessing: Bool = false
    @State private var isAutoProcessingEnabled: Bool = false
    @State private var isPresented: Bool = true
    @State private var predictedLabels: [Int: String]? = nil
    @State private var currentTask: Task?
    @State private var taskIndex: Int = 0
    @State private var countdown: Int = 0 // 倒數計時變數
    @State private var isCountingDown: Bool = false // 控制倒數狀態
    @State private var taskCompleted: Bool = false // 控制任務完成狀態
    @State private var timerCancellable: AnyCancellable?
    @State private var isCooldown: Bool = false // 控制冷卻狀態

    // 定義自動處理的 timer
    let autoProcessTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // 定義任務列表
    @State private var tasks: [Task] = [
        Task(
            name: "頭部向左轉",
            expectedConditions: [1: "left", 4: "turn"],
            duration: 4,
            modelName: "facing-model",
            icon: "arrowshape.left.fill",
            indexToLabelMap: [0: "front", 1: "left", 2: "right", 3: "tilt", 4: "turn"],
            multipliers: ["front": 1.4]
        ),
        Task(
            name: "頭部回正",
            expectedConditions: [0: "front"],
            duration: 4,
            modelName: "facing-model",
            icon: "face.smiling.inverse",
            indexToLabelMap: [0: "front", 1: "left", 2: "right", 3: "tilt", 4: "turn"],
            multipliers: ["front": 1.5]
        ),
        Task(
            name: "頭部向右轉",
            expectedConditions: [2: "right", 4: "turn"],
            duration: 4,
            modelName: "facing-model",
            icon: "arrowshape.right.fill",
            indexToLabelMap: [0: "front", 1: "left", 2: "right", 3: "tilt", 4: "turn"],
            multipliers: ["front": 1.3]
        ),
        Task(
            name: "向上看",
            expectedConditions: [7: "top"], // 修改鍵值為 7
            duration: 4,
            modelName: "facing-model",
            icon: "arrow.up.circle.fill",
            indexToLabelMap: [5: "down", 6: "unknown", 7: "top"], // 確保鍵值正確
            multipliers: ["top": 1.4]
        )
    ]

    @StateObject var webViewModel = WebViewModel()

    // 定義 `WhatsNew` 資料，改為非 Optional
    var whatsNew: WhatsNew = WhatsNew(
        title: "Sandy's New Adventures 🐿️🏄‍♀️",
        features: [
            .init(
                image: .init(systemName: "camera.fill", foregroundColor: .blue),
                title: "實時動作偵測",
                subtitle: "使用相機獲取即時回饋，就像珊迪的高科技套裝一樣！"
            ),
            .init(
                image: .init(systemName: "timer", foregroundColor: .green),
                title: "清脆又大聲的倒數",
                subtitle: "清脆又大聲的倒數讓你沒看著螢幕也知道自己做對了！"
            ),
            .init(
                image: .init(systemName: "list.bullet.rectangle.portrait", foregroundColor: .purple),
                title: "清晰可見的步驟",
                subtitle: "保持你健康的秘訣都清清楚楚的寫在螢幕上"
            ),
            .init(
                image: .init(systemName: "person.2.fill", foregroundColor: .orange),
                title: "大家一起來保持健康",
                subtitle: "和你的家人朋友們一起努力保持健康吧！"
            )
        ],
        primaryAction: WhatsNew.PrimaryAction(
            title: "開始吧！",
            backgroundColor: .accentColor,
            foregroundColor: .white,
            hapticFeedback: .notification(.success),
            onDismiss: {
                print("Sandy's new features have been explored!")
                // 這裡可以觸發其他行為，例如繼續到應用主畫面
            }
        )
    )

    // 控制兩個不同的 sheet
    @State private var isWhatsNewPresented = true // 控制 WhatsNewSheet 的顯示狀態
    @State private var isBottomSheetPresented = false // 控制 BottomSheet 的顯示狀態

    var body: some View {
        NavigationStack {
            ZStack {
                // 相機背景視圖
                CameraView(capturedImage: $inputImage)
                    .edgesIgnoringSafeArea(.all)

                // 倒數計時大字顯示
                if isCountingDown && countdown > 0 {
                    Text("\(countdown)")
                        .font(.system(size: 100, weight: .bold))
                        .foregroundColor(.white)
                        .animation(.easeInOut, value: countdown)
                        .transition(.opacity)
                }

                // 右上角的設定按鈕
                VStack {
                    HStack {
                        Spacer()
                        NavigationLink(destination: SettingsView().environmentObject(webViewModel)) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    Spacer()
                }
            }
            .onAppear {
                // 初始化當前任務
                if tasks.indices.contains(taskIndex) {
                    currentTask = tasks[taskIndex]
                }

                // 註冊通知
                NotificationCenter.default.addObserver(forName: .taskConditionMet, object: nil, queue: .main) { notification in
                    if let taskName = notification.object as? String, taskName == currentTask?.name {
                        handleTaskConditionMet()
                    }
                }

                NotificationCenter.default.addObserver(forName: .taskConditionNotMet, object: nil, queue: .main) { _ in
                    handleTaskConditionNotMet()
                }

                // 設置倒數計時器
                timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
                    .autoconnect()
                    .sink { _ in
                        if isCountingDown {
                            if countdown > 0 {
                                countdown -= 1
                                outputText = "倒數: \(countdown)秒"
                                print("倒數: \(countdown)")
                                playTickSound()
                            }
                            if countdown == 0 && isCountingDown {
                                isCountingDown = false
                                taskCompleted = true
                                outputText = "任務完成！"
                                playSuccessSound()

                                // 開始冷卻期
                                isCooldown = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    isCooldown = false
                                    moveToNextTask()
                                }
                            }
                        }
                    }
            }
            .onReceive(autoProcessTimer) { _ in
                if isAutoProcessingEnabled && !isProcessing && !isCooldown && inputImage != nil {
                    isProcessing = true
                    currentTask = tasks[taskIndex]
                    print("定時器觸發，開始自動處理圖像")
                    // 假設開始處理圖像會觸發 WebViewContainer 的處理
                }
            }
            .onDisappear {
                // 移除通知
                NotificationCenter.default.removeObserver(self)
                // 取消倒數計時器
                timerCancellable?.cancel()
            }
            // 先呈現 WhatsNewSheet
            .sheet(isPresented: $isWhatsNewPresented) {
                WhatsNewView(whatsNew: whatsNew)
                    .onDisappear {
                        // 當 WhatsNewSheet 被關閉時，顯示 BottomSheet
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isBottomSheetPresented = true
                        }
                    }
            }
            // 當 WhatsNewSheet 被關閉後，呈現 BottomSheet
            .sheet(isPresented: $isBottomSheetPresented) {
                BottomSheet(
                    isPresented: $isPresented,
                    outputText: $outputText,
                    isAutoProcessingEnabled: $isAutoProcessingEnabled,
                    isProcessing: $isProcessing,
                    inputImage: $inputImage,
                    tasks: $tasks,
                    currentTask: $currentTask,
                    taskIndex: $taskIndex,
                    predictedLabels: $predictedLabels,
                    taskCompleted: $taskCompleted, // 傳遞任務完成狀態
                    countdown: $countdown, // 傳遞倒數計時
                    isCountingDown: $isCountingDown // 傳遞倒數狀態
                )
                .interactiveDismissDisabled()
                .presentationDetents([.fraction(0.4), .fraction(0.5)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(36)
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.4)))
            }

            // 隱藏的 WebViewContainer
            WebViewContainer(
                inputImage: $inputImage,
                outputText: $outputText,
                isProcessing: $isProcessing,
                predictedLabels: $predictedLabels,
                currentTask: $currentTask,
                tasks: $tasks // 傳遞任務列表
            )
            .frame(width: 0, height: 0)
        }
        .environmentObject(webViewModel)
    }

    // MARK: - Task Handlers
    func handleTaskConditionMet() {
        print("條件達成: \(currentTask?.name ?? "未知任務")")
        if !isCountingDown && !isCooldown {
            startCountdown()
        }
    }

    func handleTaskConditionNotMet() {
        print("條件未達成")
        if isCountingDown {
            pauseCountdown()
        }

        // 簡化 outputText 顯示
        outputText = "條件未達成"
        print("條件未達成")
    }

    func startCountdown() {
        print("開始倒數")
        isCountingDown = true
        countdown = currentTask?.duration ?? 4
        taskCompleted = false
        outputText = "倒數: \(countdown)秒"
    }

    func pauseCountdown() {
        print("暫停倒數")
        isCountingDown = false
    }

    func moveToNextTask() {
        withAnimation(.easeInOut(duration: 0.5)) {
            taskIndex += 1
            if taskIndex >= tasks.count {
                taskIndex = 0
            }

            if tasks.indices.contains(taskIndex) {
                currentTask = tasks[taskIndex]
                taskCompleted = false
                countdown = 0
                isCountingDown = false
                outputText = "準備下一個任務"
                print("移動到下一個任務: \(currentTask?.name ?? "未知任務")")
            }
        }
    }

    func playSuccessSound() {
        AudioServicesPlaySystemSound(1057) // 成功音效
    }

    func playTickSound() {
        AudioServicesPlaySystemSound(1103) // 倒數計時音效
    }
}


// MARK: - BottomSheet View
struct BottomSheet: View {
    @Binding var isPresented: Bool
    @Binding var outputText: String
    @Binding var isAutoProcessingEnabled: Bool
    @Binding var isProcessing: Bool
    @Binding var inputImage: UIImage?
    @Binding var tasks: [Task]
    @Binding var currentTask: Task?
    @Binding var taskIndex: Int
    @Binding var predictedLabels: [Int: String]? // 綁定預測標籤
    @Binding var taskCompleted: Bool // 綁定任務完成狀態
    @Binding var countdown: Int // 綁定倒數計時
    @Binding var isCountingDown: Bool // 綁定倒數狀態

    @Environment(\.colorScheme) var colorScheme
    @State private var isFavorite = false // 用來觸發動畫效果

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(colorScheme == .dark ? .white : .black)
                            .opacity(0.1)
                        Button {
                            withAnimation {
                                isFavorite.toggle()
                            }
                        } label: {
                            Image(systemName: currentTask?.icon ?? "questionmark")
                                .font(.system(size: 48))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .padding()
                        }
                        .contentTransition(.symbolEffect(.replace))
                    }
                    .padding(.trailing, 6)
                    .padding(.leading, 24)

                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(colorScheme == .dark ? .white : .black)
                            .opacity(0.1)

                        Text(taskCompleted ? "任務完成！" : outputText)
                            .font(.system(size: 24))
                            .fontWeight(.heavy)
                            .foregroundColor(taskCompleted ? .green : (colorScheme == .dark ? .white : .black))
                    }
                    .padding(.leading, 6)
                    .padding(.trailing, 24)
                }

                HStack {
                    // 顯示兩個任務
                    ForEach(taskIndex..<min(taskIndex + 2, tasks.count), id: \.self) { index in
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(taskCompleted && index == taskIndex ? .green : (colorScheme == .dark ? .white : .black))
                                .opacity(0.1)
                                .frame(height: 50)
                            Text(tasks[index].name)
                                .font(.system(size: 18))
                                .fontWeight(.medium)
                                .foregroundColor(taskCompleted && index == taskIndex ? .green : (colorScheme == .dark ? .white : .black))
                        }
                        .padding(.horizontal, 4) // 增加一點間距
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                HStack {
                    // 自動偵測切換按鈕
                    AnimatedButton(
                        text: isAutoProcessingEnabled ? "自動偵測關閉" : "自動偵測開啟",
                        action: {
                            isAutoProcessingEnabled.toggle()
                        },
                        lightBackgroundColor: .black,
                        darkBackgroundColor: .white,
                        foregroundColor: .white,
                        cornerRadius: 50,
                        horizontalPadding: 20,
                        verticalPadding: 16
                    )
                }
                .padding(.top, 16)
                .padding(.bottom, 16)
            }
            .padding(.top, 24)
            .background(
                RoundedRectangle(cornerRadius: 36)
                    .fill(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white)
                    .shadow(radius: 10)
            )
            .ignoresSafeArea()
        }
    }

    private func playSuccessSound() {
        AudioServicesPlaySystemSound(1057) // 成功音效
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @State private var modelUrl = ""
    @State private var modelName = ""

    @EnvironmentObject var webViewModel: WebViewModel // 引入 WebViewModel

    var body: some View {
        Form {
            // 新增模型的區域
            Section(header: Text("新增模型")) {
                TextField("模型 JSON URL", text: $modelUrl)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                TextField("模型名稱", text: $modelName)

                // 儲存模型按鈕
                Button(action: {
                    // 準備要發送給 JavaScript 的資料
                    let data: [String: Any] = ["action": "saveModel", "url": modelUrl, "modelName": modelName]
                    if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        let jsCode = "window.webkit.messageHandlers.indexedDBHandler.postMessage(\(jsonString));"
                        print("發送給 WebView 的 JS: \(jsCode)")
                        // 使用 webViewModel 中的 webView 執行 JS 代碼
                        if let webView = webViewModel.webView {
                            webView.evaluateJavaScript(jsCode, completionHandler: nil)
                        } else {
                            print("WebView 未初始化")
                        }
                    }
                }) {
                    Text("儲存模型")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }

            // 刪除模型的區域
            Section(header: Text("刪除模型")) {
                TextField("模型名稱", text: $modelName)

                // 刪除模型按鈕
                Button(action: {
                    let data: [String: Any] = ["action": "deleteModel", "modelName": modelName]
                    if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        let jsCode = "window.webkit.messageHandlers.indexedDBHandler.postMessage(\(jsonString));"
                        print("發送給 WebView 的 JS: \(jsCode)")
                        // 使用 webViewModel 中的 webView 執行 JS 代碼
                        if let webView = webViewModel.webView {
                            webView.evaluateJavaScript(jsCode, completionHandler: nil)
                        } else {
                            print("WebView 未初始化")
                        }
                    }
                }) {
                    Text("刪除模型")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationBarTitle("設置", displayMode: .inline)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
