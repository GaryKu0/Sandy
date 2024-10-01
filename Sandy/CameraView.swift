import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    @Binding var capturedImage: UIImage?

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        // 创建 AVCapture 会话
        let session = AVCaptureSession()
        session.sessionPreset = .high // 使用较高的预设，保持流畅性

        // 使用前置摄像头
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return view
        }
        session.addInput(input)

        // 设置预览层
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill  // 保证预览层覆盖整个屏幕
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        // 设置视频输出，用于捕获图片
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true // 忽略处理较慢的帧
        let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInitiated)
        videoOutput.setSampleBufferDelegate(context.coordinator, queue: videoQueue)
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        // 开始会话
        session.startRunning()

        // 在上下文中保存会话和预览图层
        context.coordinator.session = session
        context.coordinator.previewLayer = previewLayer

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // 确保预览层的大小随屏幕调整
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // 协调器类，用于处理视频帧捕获
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: CameraView
        var session: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        var frameCounter = 0

        init(_ parent: CameraView) {
            self.parent = parent
        }

        // 处理每帧的视频数据
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            frameCounter += 1

            // 每隔 15 帧捕获一次图像（可以根据需要调整帧数）
            if frameCounter % 15 == 0 {
                frameCounter = 0

                // 在后台线程处理图像，并在主线程中更新 UI
                if let image = imageFromSampleBuffer(sampleBuffer) {
                    DispatchQueue.main.async {
                        self.parent.capturedImage = image
                    }
                }
            }
        }

        // 将 CMSampleBuffer 转换为 UIImage
        func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }

            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
            let context = CIContext()

            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }

            // 返回转换后的 UIImage，并调整为镜像模式
            let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .rightMirrored)
            return image
        }
    }
}
