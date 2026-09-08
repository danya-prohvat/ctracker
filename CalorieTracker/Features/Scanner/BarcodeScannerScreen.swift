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
        let coordinator = context.coordinator
        // Size or rotation changes shift the layer↔camera mapping — keep the
        // detection window in sync with every layout pass.
        view.onLayoutChange = { [weak coordinator] in
            coordinator?.updateRectOfInterest()
        }
        // The preview connection only exists once the session is configured,
        // which happens after the first layout pass — re-apply the rotation
        // then, or a scanner opened in landscape would start sideways.
        coordinator.configure(previewLayer: view.previewLayer) { [weak view] in
            view?.applyRotationAngle()
            coordinator.updateRectOfInterest()
        }
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
        /// Main-queue only: layer→camera conversion is garbage before the
        /// session runs, so rect-of-interest updates wait for this flag.
        private var isSessionReady = false
        private weak var previewLayer: AVCaptureVideoPreviewLayer?
        /// Set once during configuration on the session queue; rect-of-interest
        /// writes happen on that same queue.
        private var metadataOutput: AVCaptureMetadataOutput?

        init(onCode: @escaping (String) -> Void) {
            self.onCode = onCode
        }

        func configure(previewLayer: AVCaptureVideoPreviewLayer,
                       onReady: @escaping () -> Void) {
            self.previewLayer = previewLayer
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
                    self.metadataOutput = output
                }

                self.session.commitConfiguration()
                // No camera (simulator / no permission) → leave the clear view.
                let hasCamera = !self.session.inputs.isEmpty
                if hasCamera {
                    self.session.startRunning()
                }
                DispatchQueue.main.async { [weak self] in
                    self?.isSessionReady = hasCamera
                    onReady()
                }
            }
        }

        /// Restricts detection to the visible viewfinder: the preview crops the
        /// camera frame with `resizeAspectFill`, so without a rect of interest
        /// barcodes decode anywhere in the frame — including areas the user
        /// cannot see. Converts the layer's bounds (plus a small margin) into
        /// camera space. Main thread; no-op until the session is running.
        func updateRectOfInterest() {
            guard isSessionReady, let previewLayer else { return }
            let visible = previewLayer.bounds.insetBy(dx: -16, dy: -16)
            let region = previewLayer
                .metadataOutputRectConverted(fromLayerRect: visible)
                .intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
            guard !region.isNull, region.width > 0, region.height > 0 else { return }
            sessionQueue.async { [weak self] in
                self?.metadataOutput?.rectOfInterest = region
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

    /// Fired after each layout pass, once rotation is applied, so the
    /// coordinator can keep the metadata rect of interest in sync.
    var onLayoutChange: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        applyRotationAngle()
        onLayoutChange?()
    }

    /// The preview connection defaults to portrait (90°); iPad allows
    /// landscape, so map the interface orientation explicitly. Rotation is a
    /// main-thread layout concern — the session's queue is not involved.
    func applyRotationAngle() {
        guard let connection = previewLayer.connection,
              let orientation = window?.windowScene?.interfaceOrientation else { return }
        let angle: CGFloat = switch orientation {
        case .landscapeRight: 0
        case .landscapeLeft: 180
        case .portraitUpsideDown: 270
        default: 90
        }
        if connection.isVideoRotationAngleSupported(angle) {
            connection.videoRotationAngle = angle
        }
    }
}
