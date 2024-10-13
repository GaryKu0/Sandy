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
    @State private var animationAmount: CGFloat = 1.0 // Animation scale
    @State private var detent = PresentationDetent.fraction(0.4)

    // Define auto-processing timer
    let autoProcessTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Initialize tasks using Task.defaultTasks
    @State private var tasks: [Task] = Task.defaultTasks

    @StateObject var webViewModel = WebViewModel()

    // Define `WhatsNew` data
    var whatsNew: WhatsNew = WhatsNew(
        title: "珊迪的新冒險 🐿️🏊‍♀️",
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

    // Control for two different sheets
    @State private var isWhatsNewPresented = true // Control WhatsNewSheet display state
    @State private var isBottomSheetPresented = false // Control BottomSheet display state

    // Environment variables for detecting device and size class
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State private var deviceOrientation = UIDevice.current.orientation

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                if UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass == .regular {
                    // iPad horizontal mode using HStack layout
                    ZStack {
                        HStack(spacing: 0) {
                            ZStack {
                                // Camera background view
                                CameraView(capturedImage: $inputImage)
                                    .edgesIgnoringSafeArea(.all)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .onAppear {
                                        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
                                    }
                                    .onDisappear {
                                        UIDevice.current.endGeneratingDeviceOrientationNotifications()
                                    }
                                    .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                                        deviceOrientation = UIDevice.current.orientation
                                    }

                                // Countdown timer display
                                Text("\(countdown)")
                                    .font(.system(size: 100, weight: .bold))
                                    .foregroundColor(.white)
                                    .scaleEffect(animationAmount)
                                    .opacity(isCountingDown && countdown > 0 ? 1 : 0)
                                    .animation(
                                        .spring(response: 0.2, dampingFraction: 0.5, blendDuration: 0.5)
                                            .repeatForever(autoreverses: true),
                                        value: animationAmount
                                    )
                                    .onAppear {
                                        animationAmount = 1.2
                                    }
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)

                            Spacer()
                        }

                        // Right sidebar with padding and corner radius
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
                    // iPhone or portrait mode using original layout
                    ZStack {
                        // Camera background view
                        CameraView(capturedImage: $inputImage)
                            .edgesIgnoringSafeArea(.all)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        // Countdown timer display
                        Text("\(countdown)")
                            .font(.system(size: 100, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(animationAmount)
                            .opacity(isCountingDown && countdown > 0 ? 1 : 0)
                            .animation(
                                .spring(response: 0.2, dampingFraction: 0.5, blendDuration: 0.5)
                                    .repeatForever(autoreverses: true),
                                value: animationAmount
                            )
                            .onAppear {
                                animationAmount = 1.2
                            }

                        // Settings button in the top right corner
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
                // Initialize the current task
                if tasks.indices.contains(taskIndex) {
                    currentTask = tasks[taskIndex]
                }

                // Register notifications
                NotificationCenter.default.addObserver(forName: .taskConditionMet, object: nil, queue: .main) { notification in
                    if let taskName = notification.object as? String, taskName == currentTask?.name {
                        handleTaskConditionMet()
                    }
                }

                NotificationCenter.default.addObserver(forName: .taskConditionNotMet, object: nil, queue: .main) { _ in
                    handleTaskConditionNotMet()
                }

                // Set up countdown timer
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

                                // Start cooldown period
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
                // Remove notifications
                NotificationCenter.default.removeObserver(self)
                // Cancel countdown timer
                timerCancellable?.cancel()
            }
            // Show WhatsNewSheet first
            .sheet(isPresented: $isWhatsNewPresented) {
                WhatsNewView(whatsNew: whatsNew)
                    .onDisappear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if UIDevice.current.userInterfaceIdiom != .pad {
                                isBottomSheetPresented = true
                            } else {
                                isBottomSheetPresented = false // Ensure BottomSheet is not shown on iPad
                            }
                        }
                    }
            }
            // Show BottomSheet after WhatsNewSheet is dismissed (only on non-iPad)
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
                        isCountingDown: $isCountingDown,
                        detent: $detent // Pass the binding here
                    )
                    .interactiveDismissDisabled()
                    .presentationDetents([.fraction(0.4), .fraction(0.7)], selection: $detent)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(36)
                    .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.4)))
                }
            }
            // Hidden WebViewContainer
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
        // Listen to changes in showSettings to control BottomSheet
        .onChange(of: showSettings) { newValue in
            if newValue {
                // SettingsView opened, dismiss BottomSheet
                isBottomSheetPresented = false
            } else {
                // SettingsView closed, show BottomSheet (only on non-iPad)
                if UIDevice.current.userInterfaceIdiom != .pad {
                    isBottomSheetPresented = true
                }
            }
        }
    }

    // MARK: - Task Handling Functions
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
        AudioServicesPlaySystemSound(1057) // Success sound
    }

    func playTickSound() {
        AudioServicesPlaySystemSound(1103) // Countdown sound
    }
}

// MARK: - BottomSheet View
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
    @Binding var predictedLabels: [Int: String]? // Bind predicted labels
    @Binding var taskCompleted: Bool // Bind task completion status
    @Binding var countdown: Int // Bind countdown
    @Binding var isCountingDown: Bool // Bind countdown state
    @Binding var detent: PresentationDetent // New binding for detent

    @Environment(\.colorScheme) var colorScheme
    @State private var isFavorite = false // Used to trigger animation
    @State private var animationAmount: CGFloat = 1
    @Namespace private var animation

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 36)
                    .fill(colorScheme == .dark ? Color.black.opacity(0.9) : Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                    .ignoresSafeArea()

                // Content
                VStack(spacing: 24) {
                    // Task Icon and Status
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: currentTask?.icon ?? "questionmark")
                                    .font(.system(size: 36, weight: .semibold))
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .rotationEffect(.degrees(isFavorite ? 360 : 0))
                                    .animation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.5), value: isFavorite)
                                    .onTapGesture {
                                        withAnimation {
                                            isFavorite.toggle()
                                        }
                                    }
                            }
                            .matchedGeometryEffect(id: "taskIcon", in: animation)
                            .padding(.leading,24)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(taskCompleted ? "任務完成！" : "進行中")
                                    .font(.headline)
                                    .foregroundColor(taskCompleted ? .green : .primary)
                                
                                Text(outputText)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }

                        // Task Progress
                        HStack {
                            ForEach(taskIndex..<min(taskIndex + 3, tasks.count), id: \.self) { index in
                                TaskProgressView(task: tasks[index], isCompleted: taskCompleted && index == taskIndex)
                            }
                        }
                    }
                    .padding(.top, 48)
                    .padding(.horizontal)

                    // YouTubePlayerView adjustment
                    YouTubePlayerView(videoID: "izCU-ynqi5Q")
                        .frame(height: detent == .fraction(0.7) ? 200 : 0)
                        .opacity(detent == .fraction(0.7) ? 1 : 0)
                        .clipped()
                        .animation(.easeInOut, value: detent)
                        .padding(.horizontal)
                        .cornerRadius(12)

                    // Auto-processing Button
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
                .padding(.bottom, 32)
            }
        }
    }
}

struct TaskProgressView: View {
    let task: Task
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: task.icon)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(isCompleted ? .green : Color.gray.opacity(0.6))
                .frame(width: 24, height: 24)
            
            Text(task.name)
                .font(.caption)
                .foregroundColor(isCompleted ? .green : .primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
