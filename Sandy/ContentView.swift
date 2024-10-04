import SwiftUI
import AVFoundation
import WebKit
import Combine
import WhatsNewKit

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
    @State private var countdown: Int = 0 // Countdown variable
    @State private var isCountingDown: Bool = false // Controls countdown state
    @State private var taskCompleted: Bool = false // Controls task completion state
    @State private var timerCancellable: AnyCancellable?
    @State private var isCooldown: Bool = false // Controls cooldown state

    // Define auto-processing timer
    let autoProcessTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Initialize tasks using Task.defaultTasks
    @State private var tasks: [Task] = Task.defaultTasks

    @StateObject var webViewModel = WebViewModel()

    // 定義 `WhatsNew` 數據
    var whatsNew: WhatsNew = WhatsNew(
        title: "珊迪的新冒險 🐿️🏄‍♀️",
        features: [
            .init(
                image: .init(systemName: "camera.fill", foregroundColor: .blue),
                title: "即時動作偵測",
                subtitle: "使用相機獲取即時回饋，就像珊迪的高科技套裝一樣！"
            ),
            .init(
                image: .init(systemName: "timer", foregroundColor: .green),
                title: "清脆又大聲的倒數",
                subtitle: "清脆又大聲的倒數讓你沒看着屏幕也知道自己做對了！"
            ),
            .init(
                image: .init(systemName: "list.bullet.rectangle.portrait", foregroundColor: .purple),
                title: "清晰可見的步驟",
                subtitle: "保持你健康的秘訣都清清楚楚的寫在屏幕上"
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
                print("探索了珊迪的新功能！")
            }
        )
    )

    // 控制兩個不同的 sheet
    @State private var isWhatsNewPresented = true // 控制 WhatsNewSheet 的顯示狀態
    @State private var isBottomSheetPresented = false // 控制 BottomSheet 的顯示狀態

    // 環境變量，用於檢測設備和尺寸類型
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State private var deviceOrientation = UIDevice.current.orientation

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                if UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass == .regular {
                    // iPad 橫向模式，使用 HStack 佈局
                    ZStack {
                        HStack(spacing: 0) {
                            ZStack {
                                // 相機背景視圖
                                CameraView(capturedImage: $inputImage)
                                    .edgesIgnoringSafeArea(.all)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity) // 確保填滿空間
                                    .onAppear {
                                        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
                                    }
                                    .onDisappear {
                                        UIDevice.current.endGeneratingDeviceOrientationNotifications()
                                    }
                                    .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                                        deviceOrientation = UIDevice.current.orientation
                                    }

                                // 倒數計時大字顯示（始終存在，使用 opacity 控制顯示）
                                Text("\(countdown)")
                                    .font(.system(size: 100, weight: .bold))
                                    .foregroundColor(.white)
                                    .opacity(isCountingDown && countdown > 0 && UIDevice.current.userInterfaceIdiom != .pad ? 1 : 0)
                                    .animation(.easeInOut, value: countdown)
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)

                            Spacer()
                        }

                        // 右側的側邊欄，添加間距和圓角
                        SideSheet(
                            isPresented: $isPresented,
                            outputText: $outputText,
                            isAutoProcessingEnabled: $isAutoProcessingEnabled,
                            isProcessing: $isProcessing,
                            inputImage: $inputImage,
                            tasks: $tasks,
                            currentTask: $currentTask,
                            taskIndex: $taskIndex,
                            predictedLabels: $predictedLabels,
                            taskCompleted: $taskCompleted,
                            countdown: $countdown,
                            isCountingDown: $isCountingDown
                        )
                        .frame(width: geometry.size.width * 0.35)
                        .padding(.trailing, 16)
                        .padding(.leading, geometry.size.width * 0.65 - 16)
                        .padding(.vertical, 16)
                    }
                } else {
                    // iPhone 或直向模式，使用原始佈局
                    ZStack {
                        // 相機背景視圖
                        CameraView(capturedImage: $inputImage)
                            .edgesIgnoringSafeArea(.all)
                            .frame(maxWidth: .infinity, maxHeight: .infinity) // 確保填滿空間

                        // 倒數計時大字顯示（始終存在，使用 opacity 控制顯示）
                        Text("\(countdown)")
                            .font(.system(size: 100, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(isCountingDown && countdown > 0 ? 1 : 0)
                            .animation(.easeInOut, value: countdown)

                        // 右上角的設置按鈕
                        VStack {
                            HStack {
                                Spacer()
                                NavigationLink(destination: SettingsView(), isActive: $showSettings) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding()
                                }
                            }
                            Spacer()
                        }
                    }
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if UIDevice.current.userInterfaceIdiom != .pad {
                                isBottomSheetPresented = true
                            } else {
                                isBottomSheetPresented = false // 確保在 iPad 上不顯示 BottomSheet
                            }
                        }
                    }
            }
            // 當 WhatsNewSheet 被關閉後，呈現 BottomSheet（僅在非 iPad 上）
            .sheet(isPresented: $isBottomSheetPresented) {
                if UIDevice.current.userInterfaceIdiom != .pad {
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
                        taskCompleted: $taskCompleted,
                        countdown: $countdown,
                        isCountingDown: $isCountingDown
                    )
                    .interactiveDismissDisabled()
                    .presentationDetents([.fraction(0.4), .fraction(0.5)])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(36)
                    .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.4)))
                }
            }
            // 隱藏的 WebViewContainer
            WebViewContainer(
                inputImage: $inputImage,
                outputText: $outputText,
                isProcessing: $isProcessing,
                predictedLabels: $predictedLabels,
                currentTask: $currentTask,
                tasks: $tasks
            )
            .hidden()
            .frame(width: 0, height: 0)
        }
        .environmentObject(webViewModel)
        // 監聽 showSettings 的變化來控制 BottomSheet
        .onChange(of: showSettings) { newValue in
            if newValue {
                // SettingsView 被打開，收起 BottomSheet
                isBottomSheetPresented = false
            } else {
                // SettingsView 被關閉，展開 BottomSheet（僅在非 iPad 上）
                if UIDevice.current.userInterfaceIdiom != .pad {
                    isBottomSheetPresented = true
                }
            }
        }
    }

    // MARK: - 任務處理函數
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
        outputText = "條件未達成"
    }

    func startCountdown() {
        isCountingDown = true
        countdown = currentTask?.duration ?? 4
        taskCompleted = false
        outputText = "倒數: \(countdown)秒"
    }

    func pauseCountdown() {
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
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                HStack {
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
}


// MARK: - Preview
#Preview{
    ContentView()
}
