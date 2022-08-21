//
//  UICameraCapturePreviewView.swift
//  RPS Scorer
//
//  Created by Samuel Folledo on 8/20/22.
//

import SwiftUI
import AVFoundation
import Vision

struct CameraCapturePreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> UICameraCapturePreviewView {
        let view = UICameraCapturePreviewView()
        view.setupSession()
        view.setupPreview()
        return view
    }
    
    func updateUIView(_ uiView: UICameraCapturePreviewView, context: Context) {
    }
}

class UICameraCapturePreviewView: UIView, AVCaptureVideoDataOutputSampleBufferDelegate {
    // AVCaptureVideoDataOutputSampleBufferDelegate
    // when you want to handle the video input every second, you will add the delegate
    var recognitionInterval = 0 //Interval for object recognition
    
    var mlModel: VNCoreMLModel {
        get {
            guard let model = try? VNCoreMLModel(for: my_custom_model(configuration: MLModelConfiguration()).model) else {
                fatalError("Could not load ml model")
            }
            return model
        }
    }
    var captureSession: AVCaptureSession!
    var resultLabel: UILabel!
    
    func setupSession() {
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else { return }
        guard captureSession.canAddInput(videoInput) else { return }
        captureSession.addInput(videoInput)
        
        // Output settings
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoQueue")) // set delegate to receive the data every frame
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        }
        
        captureSession.commitConfiguration()
        
    }
    
    func setupPreview() {
        self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = frame
        layer.addSublayer(previewLayer)
        
        resultLabel = UILabel()
        resultLabel.text = ""
        resultLabel.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - 200, width: UIScreen.main.bounds.width, height: 80)
        resultLabel.textColor = UIColor.black
        resultLabel.textAlignment = NSTextAlignment.center
        resultLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
        resultLabel.backgroundColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.7)
        addSubview(resultLabel)
        
        captureSession.startRunning()
    }
    
    // captureOutput will be called for each frame written
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Recognise the object every 10 frames
        if recognitionInterval < 10 {
            recognitionInterval += 1
            return
        }
        recognitionInterval = 0
        
        // Convert CMSampleBuffer(an object holding media data) to CMSampleBufferGetImageBuffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Create image process request, pass model and result
        let request = VNCoreMLRequest(model: mlModel) { (request: VNRequest, error: Error?) in
            if let error = error {
                print("Error setting up vision model \(error.localizedDescription)")
                return
            }
            guard let results = request.results as? [VNRecognizedObjectObservation],
                  !results.isEmpty
            else { return }
            var displayText = ""
            for result in results.prefix(5) {
                displayText += "\(result.formattedConfidenceLabel)\n"
            }
            print(displayText)
            // Execute it in the main thread
            DispatchQueue.main.async {
                self.resultLabel.text = displayText
            }
        }
        // Execute the request
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}


////MARK: AVCaptureVideoDataOutputSampleBufferDelegate
//extension UICameraCapturePreviewView: AVCaptureVideoDataOutputSampleBufferDelegate {
//    //Delegate method that notifies the delegate that a new video frame was written.
//    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        if visionService == nil {
//            DispatchQueue.main.async {
//                self.previewView.removeMasks()
//            }
//            return
//        }
//        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//        var requestOptions: [VNImageOption: Any] = [:]
//        if let cameraIntrensicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
//            requestOptions = [.cameraIntrinsics: cameraIntrensicData]
//        }
//        let exifOrientation = camera!.exifOrientationFromDeviceOrientation()
//        let orientation = CGImagePropertyOrientation(rawValue: UInt32(exifOrientation))!
//        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: requestOptions)
//        visionService.performRequest(for: imageRequestHandler)
//    }
//}
//
////MARK: - AVCapturePhotoCaptureDelegate
//extension UICameraCapturePreviewView: AVCapturePhotoCaptureDelegate {
//    //Delegate method called when a photo is captured
//    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
//        if let error = error {
//            print("Error processing photo \(error.localizedDescription)")
//        } else if let dataImage = photo.fileDataRepresentation() {
//            //if no error, then get the image and append to detectedObjectImages
//            let dataProvider = CGDataProvider(data: dataImage as CFData)
//            let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
//            let imageOrientation: UIImage.Orientation = .up
//            let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: imageOrientation)
//            print("Got the image output \(image)")
//        } else {
//            presentAlert(title: "Image Error", message: "Failed to get an image")
//        }
//    }
//}
