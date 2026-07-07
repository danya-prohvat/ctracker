import SwiftUI
import AVFoundation

/// Live camera barcode scanner (spec §7). Renders just the camera preview,
/// sized to fill its container — the scan-flow viewfinder clips it into the
/// rounded 240×240 window. With no camera (simulator / no permission) it
/// stays transparent so the viewfinder placeholder shows through.
///
/// Each barcode is reported exactly once: the capture session stops after the
/// first hit. To scan again, recreate the view (e.g. with `.id(_)`).
struct BarcodeScannerScreen: View {
    var onCode: (String) -> Void

    var body: some View {
        ScannerCameraView(onCode: onCode)
            .accessibilityLabel(Text("Camera viewfinder"))
    }
}

/// UIKit-hosted AVFoundation capture pipeline. The session is configured and
/// started/stopped on a private background queue; barcode delegate callbacks
/// arrive on the main queue.
private struct ScannerCameraView: UIViewRepresentable {
    var onCode: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCode: onCode)
    }

    func makeUIView(context: Context) -> ScannerPreviewUIView {
        let view = ScannerPreviewUIView()
        view.backgroundColor = .clear
        context.coordinator.configure(previewLayer: view.previewLayer)
        return view
    }

    func updateUIView(_ uiView: ScannerPreviewUIView, context: Context) {}

    static func dismantleUIView(_ uiView: ScannerPreviewUIView, coordinator: Coordinator) {
        coordinator.stop()
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        private let onCode: (String) -> Void
        private let session = AVCaptureSession()
        private let sessionQueue = DispatchQueue(label: "ScannerCameraView.session")
        /// Main-queue only (delegate callbacks are delivered on main).
        private var hasReported = false

        init(onCode: @escaping (String) -> Void) {
            self.onCode = onCode
        }

        func configure(previewLayer: AVCaptureVideoPreviewLayer) {
            previewLayer.session = session
            previewLayer.videoGravity = .resizeAspectFill

            sessionQueue.async { [weak self] in
                guard let self else { return }
                self.session.beginConfiguration()

                if let device = AVCaptureDevice.default(for: .video),
                   let input = try? AVCaptureDeviceInput(device: device),
                   self.session.canAddInput(input) {
                    self.session.addInput(input)
                }

                let output = AVCaptureMetadataOutput()
                if self.session.canAddOutput(output) {
                    self.session.addOutput(output)
                    output.setMetadataObjectsDelegate(self, queue: .main)
                    let wanted: [AVMetadataObject.ObjectType] = [.ean8, .ean13, .upce, .code128]
                    output.metadataObjectTypes = wanted.filter {
                        output.availableMetadataObjectTypes.contains($0)
                    }
                }

                self.session.commitConfiguration()
                // No camera (simulator / no permission) → leave the clear view.
                if !self.session.inputs.isEmpty {
                    self.session.startRunning()
                }
            }
        }

        func stop() {
            sessionQueue.async { [session] in
                if session.isRunning { session.stopRunning() }
            }
        }

        // MARK: AVCaptureMetadataOutputObjectsDelegate (main queue)

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard !hasReported,
                  let code = metadataObjects
                      .compactMap({ ($0 as? AVMetadataMachineReadableCodeObject)?.stringValue })
                      .first(where: { !$0.isEmpty })
            else { return }
            hasReported = true
            stop()
            onCode(code)
        }
    }
}

/// UIView whose backing layer is the capture preview layer, so the preview
/// always fills and resizes with the view.
private final class ScannerPreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer {
        // The backing layer class is AVCaptureVideoPreviewLayer (see above),
        // so this cast can never fail at runtime.
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Backing layer is not AVCaptureVideoPreviewLayer")
        }
        return layer
    }
}
