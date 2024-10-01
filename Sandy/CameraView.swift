import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    @Binding var capturedImage: UIImage?

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        // 創建 AVCapture 會話
        let session = AVCaptureSession()
        session.sessionPreset = .high // 使用較高的預設，保持流暢性

        // 使用前置攝像頭
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return view
        }
        session.addInput(input)

        // 設置預覽層
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill  // 保證預覽層覆蓋整個屏幕
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        // 設置視頻輸出，用於捕獲圖片
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true // 忽略處理較慢的幀
        let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInitiated)
        videoOutput.setSampleBufferDelegate(context.coordinator, queue: videoQueue)
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        // 開始會話
        session.startRunning()

        // 在上下文中保存會話和預覽圖層
        context.coordinator.session = session
        context.coordinator.previewLayer = previewLayer

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // 確保預覽層的大小隨屏幕調整
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // 協調器類，用於處理視頻幀捕獲
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: CameraView
        var session: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        var frameCounter = 0

        init(_ parent: CameraView) {
            self.parent = parent
        }

        // 處理每幀的視頻數據
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            frameCounter += 1

            // 每隔 15 幀捕獲一次圖像（可以根據需要調整幀數）
            if frameCounter % 15 == 0 {
                frameCounter = 0

                // 在後台線程處理圖像，並在主線程中更新 UI
                if let image = imageFromSampleBuffer(sampleBuffer) {
                    DispatchQueue.main.async {
                        self.parent.capturedImage = image
                    }
                }
            }
        }

        // 將 CMSampleBuffer 轉換為 UIImage
        func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }

            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
            let context = CIContext()

            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }

            // 返回轉換後的 UIImage，並調整為鏡像模式
            let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .rightMirrored)
            return image
        }
    }
}
