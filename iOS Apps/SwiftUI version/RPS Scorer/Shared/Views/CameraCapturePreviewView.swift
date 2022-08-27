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

class UICameraCapturePreviewView: UIView {
    // AVCaptureVideoDataOutputSampleBufferDelegate
    // when you want to handle the video input every second, you will add the delegate
    var recognitionInterval = 0 //Interval for object recognition
    var captureSession: AVCaptureSession!
    ///the layers that shows the detected object's location
    private var overlayLayers = [CALayer]()
    ///minimum confidence threshold for detected objects
    private let minConfidence: Float = 0.2
    
    var resultLabel: UILabel!
    
    var mlModel: VNCoreMLModel {
        get {
            guard let model = try? VNCoreMLModel(for: my_custom_model(configuration: MLModelConfiguration()).model)
            else { fatalError("Could not load ml model") }
            return model
        }
    }
    
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
        frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = frame
        layer.addSublayer(previewLayer)
        captureSession.startRunning()
    }
}

private extension UICameraCapturePreviewView {
    func handleObservations(results: [VNRecognizedObjectObservation]) {
        // remove all previously added masks
        removeMasks()
        //filter (unwanted duplicates, low confidence) objects
        print("Detected \(results.count) objects")
        let detectedObjects: [DetectedObject] = getDetectedObjects(from: results)
        //draw the bounding boxes
        print("Cleaned and left with \(detectedObjects.count)")
        print("")
        for object in detectedObjects {
            drawLayer(in: object.location, color: object.type.color, with: object.confidenceText)
        }
//        delegate?.updateDetectedObjects(newDetectedObjects: detectedObjects)
    }
    
    ///convert recognizedObject's results to DetectedObject and filter (unwanted duplicates, low confidence) objects
    func getDetectedObjects(from recognizedObjects: [VNRecognizedObjectObservation]) -> [DetectedObject] {
        //filter out objects detected with low confidence
        let highConfidenceObjects = recognizedObjects.filter({ $0.confidence >= minConfidence })
        // CoreGraphics => transforming origin from top left corner to bottom left corner
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -frame.height)
        let translate = CGAffineTransform.identity.scaledBy(x: frame.width, y: frame.height)
        var detectedObjects: [DetectedObject] = []
        for trackedObject in highConfidenceObjects { //loop through each detected objects
            //get trackedObject's location
            let rectangularLocation = trackedObject.boundingBox.applying(translate).applying(transform)
            //create a detectedObject model from the trackedObject
            guard let newDetectedObject = DetectedObject(trackedObject: trackedObject, location: rectangularLocation) else { continue }
            //loop through each detectedObjects appended already and make sure to remove detectedObjects that has duplicates and lower confidence
            var shouldAddObject = true
            for (index, object) in detectedObjects.enumerated() { //loop through each detected objects and make sure there are no duplicates
                if object.type != newDetectedObject.type {
                    print("Skipping because \(object.type.rawValue) != \(newDetectedObject.type.rawValue)")
                    continue
                }
                if object.location.isMidXClose(to: newDetectedObject.location) { //if trackedObject intersects with the newDetectedObject in array
                    if object.confidence < newDetectedObject.confidence { //if newDetectedObject has lower confidence... remove detectedObject
                        detectedObjects.remove(at: index)
                    } else {
                        shouldAddObject = false
                    }
                    break
                } else {
                    print("Not midx close to for \(object.type.rawValue) and \(newDetectedObject.type.rawValue)")
                }
            }
            if shouldAddObject {
                detectedObjects.append(newDetectedObject)
            }
        }
        return detectedObjects
    }
}

extension UICameraCapturePreviewView: AVCaptureVideoDataOutputSampleBufferDelegate {
    // captureOutput will be called for each frame written
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Recognise the object every 5 frames
        if recognitionInterval < 5 {
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
            // Execute it in the main thread
            DispatchQueue.main.async {
                self.handleObservations(results: results)
            }
        }
        request.imageCropAndScaleOption = .scaleFill
        // Execute the request
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}

extension UICameraCapturePreviewView {
    func drawLayer(in rect: CGRect, color: UIColor = .yellow, with label: String) {
        let mask = CAShapeLayer()
        let textLayer = CATextLayer()
        mask.frame = rect
        textLayer.frame = rect
        mask.backgroundColor = color.cgColor
        mask.opacity = 0.2
        mask.borderColor = UIColor.white.cgColor
        mask.borderWidth = 2
        mask.cornerRadius = 12
        textLayer.string = " "+label
        textLayer.foregroundColor = color.cgColor
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.fontSize = 12
        overlayLayers.append(mask)
        overlayLayers.append(textLayer)
        layer.insertSublayer(mask, at: 1)
        layer.addSublayer(textLayer)
    }

    func removeMasks() {
        for layer in overlayLayers {
            layer.removeFromSuperlayer()
        }
        overlayLayers.removeAll()
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
