import SwiftUI
import WebKit

// MARK: - 側邊欄視圖
struct SideSheet: View {
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
        VStack(spacing: 20) {
            // 嵌入式 YouTube 影片播放器
            YouTubePlayerView(videoID: "izCU-ynqi5Q") // 實際的 YouTube 影片 ID
                .frame(height: 220) // 調整影片高度
                .cornerRadius(20)
                .padding(.horizontal, 16)

            // 倒數計時顯示
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
                    horizontalPadding: 20,
                    verticalPadding: 16
                )
            }
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
        .padding(.top, 16) // 調整頂部間距
        .padding(.bottom, 16) // 調整底部間距
        .background(
            RoundedRectangle(cornerRadius: 36)
                .fill(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.8))
        )
        .padding(.horizontal, 16)
        .edgesIgnoringSafeArea(.all)
    }
}
