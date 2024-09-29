//
//  CameraView.swift
//  Sandy
//
//  Created by 郭粟閣 on 2024/9/29.
//

import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    @Binding var capturedImage: UIImage?

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let session = AVCaptureSession()
        session.sessionPreset = .photo

        // Use the front camera
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return view
        }

        session.addInput(input)

        // Set up video data output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(context.coordinator, queue: DispatchQueue(label: "videoQueue"))
        session.addOutput(videoOutput)

        // Set up preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill

        view.layer.addSublayer(previewLayer)

        session.startRunning()

        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // Coordinator class to handle camera output
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: CameraView
        var frameCounter = 0

        init(_ parent: CameraView) {
            self.parent = parent
        }

        // Captures output from the camera
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            frameCounter += 1
            if frameCounter % 15 == 0 { // Capture every 15 frames
                frameCounter = 0
                // Convert sample buffer to UIImage
                if let image = self.imageFromSampleBuffer(sampleBuffer) {
                    DispatchQueue.main.async {
                        self.parent.capturedImage = image
                    }
                }
            }
        }

        // Converts CMSampleBuffer to UIImage
        func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }

            let ciImage = CIImage(cvPixelBuffer: imageBuffer)

            // Create a CIContext
            let context = CIContext()

            // Create CGImage from CIImage
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }

            // Adjust image orientation as needed
            let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .rightMirrored)

            return image
        }
    }
}
