//
//  Camera.swift
//  AI_RPS_Game
//
//  Created by Samuel Folledo on 5/6/21.
//

import Foundation
import UIKit.UIView
import AVFoundation

protocol CameraProtocol {
    func startCameraSession(completion: @escaping ((Camera.Error?) -> Void))
    func getPreviewLayer(for view: UIView)
    func toggleInputs()
}

//protocol CaptureManagerDelegate: class {
//    func processCapturedImage(image: UIImage)
//}
class Camera: NSObject {
    // MARK: Properties
    private let cameraQueue = DispatchQueue(label: "cameraFramework.camera.session.queue")
    private var captureSession: AVCaptureSession?
//    private weak var sampleBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    private weak var delegate: ObjectDetectionController?
//    private weak var captureDelegate: AVCapturePhotoCaptureDelegate?
//    weak var delegate: CaptureManagerDelegate?
    
    // Camera
    private var frontCamera: AVCaptureDevice?
    private var backCamera: AVCaptureDevice?
    private let captureDeviceOutput = AVCapturePhotoOutput()

//    private lazy var sequenceHandler = VNSequenceRequestHandler()
//    private lazy var capturePhotoOutput = AVCapturePhotoOutput()
    private lazy var dataOutputQueue = DispatchQueue(label: "DetectedObjectService", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    private var captureCompletionBlock: ((UIImage) -> Void)?
    private var preparingCompletionHandler: ((Bool) -> Void)?
    private var snapshotImageOrientation = UIImage.Orientation.upMirrored
    var currentCameraSelection: AVCaptureDevice.Position = .back
    private var currentlySelectedCamera: AVCaptureDevice? {
        switch currentCameraSelection {
        case .front: return frontCamera
        case .back: return backCamera
        default: return nil
        }
    }

    public init(with delegate: ObjectDetectionController) {
//        self.sampleBufferDelegate = delegate
        self.delegate = delegate
    }
    
//    func start() { captureSession?.startRunning() }
    func stop() { captureSession?.stopRunning() }
    
    func takePhoto() {
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [
            kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
            kCVPixelBufferWidthKey as String: 160,
            kCVPixelBufferHeightKey as String: 160
        ]
        settings.previewPhotoFormat = previewFormat
        captureDeviceOutput.capturePhoto(with: settings, delegate: delegate!)
    }
    
    func updateCameraFocusPoint(midPoint location: CGPoint) {
        if let device = AVCaptureDevice.default(for: AVMediaType.video) {
            do {
                try device.lockForConfiguration()
                device.focusPointOfInterest = location
                device.unlockForConfiguration()
            } catch {
                print("Error finishing camera setup")
            }
        }
    }
}

// MARK: - Public
extension Camera: CameraProtocol {
    public func startCameraSession(completion: @escaping ((Camera.Error?) -> Void)) {
        cameraQueue.async {[weak self] in
            self?.createCaptureSession()
            do {
                try self?.configureCaptureDevices()
                try self?.configureCaptureDeviceInput()
                try self?.configureCaptureDeviceOutput()
            } catch {
                completion((error as? Camera.Error) ?? Camera.Error.undefined)
                return
            }
            self?.captureSession?.startRunning()
            completion(nil)
        }
    }
    
    public func toggleLight(on: Bool) {
        if let device = AVCaptureDevice.default(for: AVMediaType.video) {
            do {
                try device.lockForConfiguration()
//                device.torchMode = on ? .on : .off
                device.autoFocusRangeRestriction = .none
                device.focusMode = .continuousAutoFocus
                device.unlockForConfiguration()
            } catch {
                print("Error finishing camera setup")
            }
        }
    }

    public func toggleInputs() {
        guard let captureSession = captureSession else {
            return
        }
        currentCameraSelection = currentCameraSelection == .back ? .front : .back
        guard
            let camera = currentlySelectedCamera,
            let captureInput = try? AVCaptureDeviceInput(device: camera) else {
                return
        }
        captureSession.removeInput(captureSession.inputs.first!)
        if captureSession.canAddInput(captureInput) {
            captureSession.addInput(captureInput)
        }
    }

    public func getPreviewLayer(for view: UIView) {
        guard let captureSession = captureSession, captureSession.isRunning else {
            return
        }
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        view.layer.insertSublayer(previewLayer, at: 0)
        previewLayer.frame = view.frame
    }

    func exifOrientationFromDeviceOrientation() -> Int32 {
        enum DeviceOrientation: Int32 {
            case top0ColLeft = 1
            case top0ColRight = 2
            case bottom0ColRight = 3
            case bottom0ColLeft = 4
            case left0ColTop = 5
            case right0ColTop = 6
            case right0ColBottom = 7
            case left0ColBottom = 8
        }
        var exifOrientation: DeviceOrientation

        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            exifOrientation = .left0ColBottom
        case .landscapeLeft:
            exifOrientation = self.currentCameraSelection == .front ? .bottom0ColRight : .top0ColLeft
        case .landscapeRight:
            exifOrientation = self.currentCameraSelection == .front ? .top0ColLeft : .bottom0ColRight
        default:
            exifOrientation = .right0ColTop
        }
        return exifOrientation.rawValue
    }
}

// MARK: - Private
private extension Camera {

    private func createCaptureSession() {
        let captureSession = AVCaptureSession()
        self.captureSession = captureSession
    }

    private func configureCaptureDevices() throws {
        // Find available devices
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                                mediaType: .video,
                                                                position: .unspecified)
        let discoveredDevices = discoverySession.devices
        guard !discoveredDevices.isEmpty else {
            throw(Camera.Error.noCameraDevicesAvailable)
        }
        discoveredDevices.forEach { (camera) in
            switch camera.position {
            case .front:
                self.frontCamera = camera
            case .back:
                self.backCamera = camera
                do {
                    try camera.lockForConfiguration()
                    if camera.isFocusModeSupported(.continuousAutoFocus) {
                        camera.focusMode = .continuousAutoFocus
                    }
                    if camera.isExposureModeSupported(.continuousAutoExposure) {
                        camera.exposureMode = .continuousAutoExposure
                    }
                    camera.unlockForConfiguration()
                } catch {
                    print("Camera was not locked, focus mode not set to .continuousAutoFocus, but stayed in: \(camera.focusMode)")
                }
            case .unspecified:
                print("Unspecified camera: \(camera)")
            default:
                print("Added unhandled camera case: \(camera)")
            }
        }
    }

    private func configureCaptureDeviceInput() throws {
        guard let captureSession = captureSession else {
            throw(Camera.Error.captureSessionUndefined)
        }
        guard let camera = currentlySelectedCamera else {
            throw(Camera.Error.noCameraSelected)
        }

        let cameraInput: AVCaptureDeviceInput
        do {
            cameraInput = try AVCaptureDeviceInput(device: camera)
        } catch {
            throw(Camera.Error.invalidCameraInput)
        }

        if captureSession.canAddInput(cameraInput) {
            captureSession.addInput(cameraInput)
        }
    }

    private func configureCaptureDeviceOutput() throws {
        guard let captureSession = captureSession else {
            throw(Camera.Error.captureSessionUndefined)
        }

        let captureDeviceOutput = AVCaptureVideoDataOutput()
        captureDeviceOutput.videoSettings = [
            ((kCVPixelBufferPixelFormatTypeKey as NSString) as String): NSNumber(value:kCVPixelFormatType_32BGRA)]
        
        captureDeviceOutput.setSampleBufferDelegate(delegate!, queue: cameraQueue)
        captureDeviceOutput.alwaysDiscardsLateVideoFrames = true

        if captureSession.canAddOutput(captureDeviceOutput) {
            captureSession.addOutput(captureDeviceOutput)
        } else {
            throw(Camera.Error.invalidOutput)
        }
        if captureSession.canAddOutput(self.captureDeviceOutput) {
            captureSession.addOutput(self.captureDeviceOutput)
        } else {
            throw(Camera.Error.invalidOutput)
        }
    }
}

//extension Camera: AVCaptureVideoDataOutputSampleBufferDelegate {
//    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        guard   captureCompletionBlock != nil,
//                let outputImage = UIImage(sampleBuffer: sampleBuffer, orientation: snapshotImageOrientation) else { return }
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
//            if let captureCompletionBlock = self.captureCompletionBlock{
//                captureCompletionBlock(outputImage)
//                AudioServicesPlayAlertSound(SystemSoundID(1108))
//            }
//            self.captureCompletionBlock = nil
//        }
//    }
//}
//
//
////MARK: Helper Extensions
//
//extension UIImage {
//    convenience init?(sampleBuffer: CMSampleBuffer, orientation: UIImage.Orientation = .upMirrored) {
//        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
//        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
//        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
//        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
//        let width = CVPixelBufferGetWidth(pixelBuffer)
//        let height = CVPixelBufferGetHeight(pixelBuffer)
//        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
//        let colorSpace = CGColorSpaceCreateDeviceRGB()
//        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
//        guard let context = CGContext(data: baseAddress, width: width, height: height,
//                                      bitsPerComponent: 8, bytesPerRow: bytesPerRow,
//                                      space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else { return nil }
//
//        guard let cgImage = context.makeImage() else { return nil }
//        self.init(cgImage: cgImage, scale: 1, orientation: orientation)
//    }
//}
//
//extension Camera: AVCapturePhotoCaptureDelegate {
//    func capturePhoto(completion: ((UIImage) -> Void)?) {
//        captureCompletionBlock = completion
//    }
//}
