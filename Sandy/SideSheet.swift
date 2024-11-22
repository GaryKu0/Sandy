import SwiftUI
import WebKit

// MARK: - SideSheet View
struct SideSheet: View {
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

    @Environment(\.colorScheme) var colorScheme
    @State private var isFavorite = false // Used to trigger animation

    var body: some View {
        VStack(spacing: 20) {
            // Embedded YouTube video player
            YouTubePlayerView(videoID: "izCU-ynqi5Q") // Actual YouTube video ID
                .frame(height: 220) // Adjust video height
                .cornerRadius(20)
                .padding(.horizontal, 16)

            // Countdown display
            if UIDevice.current.userInterfaceIdiom == .pad {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? .white : .black)
                        .opacity(0.1)
                        .frame(height: 80)
                    Text(isCountingDown && countdown > 0 ? "\(countdown) 秒" : "")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                .padding(.horizontal, 16)
            }

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
                    text: isAutoProcessingEnabled ? "自動偵測關閉" : "自動偵測開啓",
                    action: {
                        isAutoProcessingEnabled.toggle()
                    },
                    lightBackgroundColor: .black,
                    darkBackgroundColor: .white,
                    foregroundColor: .white,
                    cornerRadius: 50,
                    horizontalPadding: 48,
                    verticalPadding: 16
                )
            }
            .padding(.top, 16)
            .padding(.bottom, 16)
            .padding(.trailing, 24)
            .padding(.leading, 24)
        }
        .padding(.top, 16) // Adjust top padding
        .padding(.bottom, 16) // Adjust bottom padding
        .background(
            RoundedRectangle(cornerRadius: 36)
                .fill(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.8))
        )
        .padding(.horizontal, 16)
        .edgesIgnoringSafeArea(.all)
    }
}
