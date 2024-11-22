import SwiftUI
import AVFoundation
import WebKit
import Combine
import WhatsNewKit

struct ContentView: View {
    // Add a new binding variable for preview mode
    @Binding var isPreviewMode: Bool
    // If isPreviewMode is not passed, default to false
    init(isPreviewMode: Binding<Bool> = .constant(false)) {
        _isPreviewMode = isPreviewMode
    }
    
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
    @State private var successTimeCounter: Int = 0 // Track time conditions were met
    
    // New properties for routine and movement tracking
    @State private var routineStartTime: Date?
    @State private var movementStartTime: Date?
    @State private var completedMovements: [MovementHistory] = []
    @State private var routineHistories: [RoutineHistory] = []
    
    let autoProcessTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State private var tasks: [Task] = Task.defaultTasks

    @StateObject var webViewModel = WebViewModel()

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

    @State private var isWhatsNewPresented = true
    @State private var isBottomSheetPresented = false

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State private var deviceOrientation = UIDevice.current.orientation

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                if UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass == .regular {
                    ZStack {
                        HStack(spacing: 0) {
                            ZStack {
                                // Conditionally load CameraView only if it's not preview mode
                                if !isPreviewMode {
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
                                }
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
                    ZStack {
                        if !isPreviewMode {
                            CameraView(capturedImage: $inputImage)
                                .edgesIgnoringSafeArea(.all)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
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

                        VStack {
                            HStack {
                                Spacer()
                                NavigationLink(destination: SettingsView(routineHistories: $routineHistories), isActive: $showSettings) {
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
                if tasks.indices.contains(taskIndex) {
                    currentTask = tasks[taskIndex]
                    movementStartTime = Date() // Start tracking time for the current movement
                    if routineStartTime == nil {
                        routineStartTime = Date() // Start timing the routine
                        completedMovements = []
                    }
                    isCountingDown = false // Ensure countdown is not active yet
                }
                NotificationCenter.default.addObserver(forName: .taskConditionMet, object: nil, queue: .main) { notification in
                    if let taskName = notification.object as? String, taskName == currentTask?.name {
                        handleTaskConditionMet()
                    }
                }

                NotificationCenter.default.addObserver(forName: .taskConditionNotMet, object: nil, queue: .main) { _ in
                    handleTaskConditionNotMet()
                }

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
                            if countdown == 0 {
                                // Movement time is up
                                isCountingDown = false
                                taskCompleted = true
                                outputText = "任務完成！"
                                playSuccessSound()

                                // Record movement data
                                let movementEndTime = Date()
                                let duration = Int(movementEndTime.timeIntervalSince(movementStartTime ?? movementEndTime))
                                if let task = currentTask {
                                    let movementHistory = MovementHistory(
                                        movementName: task.name,
                                        icon: task.icon,
                                        duration: duration,
                                        startTime: movementStartTime ?? movementEndTime,
                                        endTime: movementEndTime,
                                        wasSuccessful: true // Movement completed successfully
                                    )
                                    completedMovements.append(movementHistory)
                                }
                                movementStartTime = nil

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
                NotificationCenter.default.removeObserver(self)
                timerCancellable?.cancel()
            }
            .sheet(isPresented: $isWhatsNewPresented) {
                WhatsNewView(whatsNew: whatsNew)
                    .onDisappear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if UIDevice.current.userInterfaceIdiom != .pad {
                                isBottomSheetPresented = true
                            } else {
                                isBottomSheetPresented = false
                            }
                        }
                    }
            }
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
                        detent: $detent
                    )
                    .interactiveDismissDisabled()
                    .presentationDetents([.fraction(0.4), .fraction(0.7)], selection: $detent)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(36)
                    .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.4)))
                }
            }
            // Conditionally load WebViewContainer if not preview mode
            if !isPreviewMode {
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
        }
        .environmentObject(webViewModel)
        .onChange(of: showSettings) { newValue in
            if newValue {
                isBottomSheetPresented = false
            } else {
                if UIDevice.current.userInterfaceIdiom != .pad {
                    isBottomSheetPresented = true
                }
            }
        }
    }

    // Task Handling Functions

    func handleTaskConditionMet() {
        withAnimation {
            successTimeCounter += 1
        }
        print("條件達成: \(currentTask?.name ?? "未知任務")")
        if !isCountingDown && !isCooldown {
            startCountdown()
        }
    }

    func handleTaskConditionNotMet() {
        print("條件未達成")
        outputText = "條件未達成"
        if isCountingDown {
            pauseCountdown()
        }
    }

    func startCountdown() {
        isCountingDown = true
        countdown = currentTask?.duration ?? 4
        taskCompleted = false
        outputText = "倒數: \(countdown)秒"
        successTimeCounter = 0 // Reset success counter for the new task
    }

    func pauseCountdown() {
        isCountingDown = false
    }

    func moveToNextTask() {
        withAnimation(.easeInOut(duration: 0.5)) {
            taskIndex += 1
            if taskIndex >= tasks.count {
                // Routine is completed
                let routineEndTime = Date()
                let totalDuration = Int(routineEndTime.timeIntervalSince(routineStartTime ?? routineEndTime))
                let routineHistory = RoutineHistory(
                    routineName: "預設任務序列",
                    movements: completedMovements,
                    totalDuration: totalDuration,
                    completionDate: routineEndTime,
                    wasSuccessful: true // Or determine based on criteria
                )
                // Add to history
                routineHistories.insert(routineHistory, at: 0)
                // Reset routine timing
                routineStartTime = nil
                completedMovements = []
                taskIndex = 0 // Reset task index to start over
            }

            if tasks.indices.contains(taskIndex) {
                currentTask = tasks[taskIndex]
                taskCompleted = false
                movementStartTime = Date() // Start timing the movement
                isCountingDown = false // Not counting down yet
                successTimeCounter = 0 // Reset success counter
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
                        .cornerRadius(24)
                        .opacity(detent == .fraction(0.7) ? 1 : 0)
                        .clipped()
                        .animation(.easeInOut, value: detent)
                        .padding(.horizontal)

                    // Auto-processing Button with Safe Area Inset
                }
                .frame(maxHeight: .infinity, alignment: .top) // Align content to the top
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Spacer()
                    // Bottom inset for button to avoid it being cut off
                    AnimatedButton(
                        text: isAutoProcessingEnabled ? "自動偵測關閉" : "自動偵測開啟",
                        action: {
                            isAutoProcessingEnabled.toggle()
                        },
                        cornerRadius: 48,
                        verticalPadding: 20
                    )
                    .padding(.leading,16)
                    .padding(.trailing,16)
                    Spacer()
                }
                .padding(.vertical, 16) // Padding to ensure proper spacing from the screen edge
                .background(colorScheme == .dark ? Color.black.opacity(0.9) : Color.white.opacity(0.4)) // Match the background of the bottom inset
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
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(isPreviewMode: .constant(true)) // Pass true for preview mode
    }
}
