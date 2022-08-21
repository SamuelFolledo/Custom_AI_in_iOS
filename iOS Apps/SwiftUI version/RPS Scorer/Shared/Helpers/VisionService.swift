//
//  VisionService.swift
//  RPS Scorer (iOS)
//
//  Created by Samuel Folledo on 8/21/22.
//

import UIKit
import Vision

protocol VisionServiceInputs {
    func performRequest(for imageRequestHandler: VNImageRequestHandler)
    func updateTrackedItems(trackedItems: [DetectedObjectType])
}

protocol ObjectScannerProtocol {
    func updateDetectedObjects(newDetectedObjects: [DetectedObject])
}

//class VisionService: VisionServiceInputs {
//    
//    //MARK: Enum
//    enum Config {
//        /// Confidence in % expressed from 0 - 1 which will be used
//        /// to draw bounding boxes on the images in the preview
//        static let confidence: VNConfidence = 0.2
//    }
//    
//    // MARK: Private
//    fileprivate var requests = [VNRequest]()
//
//    /// Preview used to draw bounding boxes with detected items
//    fileprivate var previewView: CameraPreview!
//    fileprivate var trackedItems: [DetectedObjectType] = []
//    fileprivate var delegate: ObjectScannerProtocol? //use delegate protocol in the future
//    private var isUvulaAvailable: Bool = false
//    private var isPharynxAvailable: Bool = false
//
//    // MARK: Public
//    init(with preview: CameraPreview, trackedItems: [DetectedObjectType] = [], delegate: ObjectScannerProtocol) {
//        self.previewView = preview
//        self.trackedItems = trackedItems
//        self.delegate = delegate
//        setupVisionModel()
//    }
//
//    // MARK: Inputs
//
//    func performRequest(for imageRequestHandler: VNImageRequestHandler) {
//        do {
//            try imageRequestHandler.perform(requests)
//        } catch {
//            fatalError("Vision Service: perform request error: \(error.localizedDescription)")
//        }
//    }
//
//    func updateTrackedItems(trackedItems: [DetectedObjectType]) {
//        self.trackedItems = trackedItems
//    }
//    
//    ///returns the bounding boxes
//    func capturePhoto() -> UIImage {
//        return previewView.toImage()
//    }
//}

// MARK: - Vision
//extension VisionService {
//
//    private func setupVisionModel() {
////        let model = VisionModelLoader.getModel()
//        //Perform an image analysis request that using our ml model to process images.
//        let request = VNCoreMLRequest(model: VisionModel.visionModel) { request, error in
//            if let error = error {
//                print("Error setting up vision model \(error.localizedDescription)")
//                return
//            }
//            guard let observations = request.results as? [VNRecognizedObjectObservation],
//                  !observations.isEmpty
//            else { return }
//            DispatchQueue.main.async {
//                self.drawVisionRequestResults(results: observations)
//            }
//        }
//        request.imageCropAndScaleOption = .scaleFill
//        self.requests = [request]
//    }
//
////    func completionRequestHandler(request: VNRequest, error: Error?) {
////        guard let observations = request.results as? [VNRecognizedObjectObservation],
////              !observations.isEmpty
////        else { return }
////        DispatchQueue.main.async {
////            self.drawVisionRequestResults(results: observations)
////        }
////    }
//
//    func drawVisionRequestResults(results: [VNRecognizedObjectObservation]) {
//        // remove all previously added masks
//        previewView.removeMasks()
//        //filter (unwanted duplicates, low confidence) objects
//        print("Detected \(results.count) objects")
//        let detectedObjects: [DetectedObject] = getCleanedDetectedObjects(results)
//        //draw the bounding boxes
//        print("Cleaned and left with \(detectedObjects.count)")
//        print("")
//        for object in detectedObjects {
//            previewView.drawLayer(in: object.location, color: object.type.color, with: object.confidenceText)
//        }
//        delegate?.updateDetectedObjects(newDetectedObjects: detectedObjects)
//    }
//
//    ///filter (unwanted duplicates, low confidence) objects
//    func getCleanedDetectedObjects(_ recognizedObjects: [VNRecognizedObjectObservation]) -> [DetectedObject] {
//        //filter out objects detected with low confidence
//        let highConfidenceObjects = recognizedObjects.filter({ $0.confidence >= Config.confidence })
//        // CoreGraphics => transforming origin from top left corner to bottom left corner
//        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -self.previewView.frame.height)
//        let translate = CGAffineTransform.identity.scaledBy(x: self.previewView.frame.width, y: self.previewView.frame.height)
//        var detectedObjects: [DetectedObject] = []
//        for trackedObject in highConfidenceObjects { //loop through each detected objects
//            //get trackedObject's location
//            let rectangularLocation = trackedObject.boundingBox.applying(translate).applying(transform)
//            //create a detectedObject model from the trackedObject
//            guard let newDetectedObject = DetectedObject(trackedObject: trackedObject, location: rectangularLocation) else { continue }
//            //loop through each detectedObjects appended already and make sure to remove detectedObjects that has duplicates and lower confidence
//            var shouldAddObject = true
//            for (index, object) in detectedObjects.enumerated() { //loop through each detected objects and make sure there are no duplicates
//                if object.type != newDetectedObject.type {
//                    print("Skipping because \(object.type.rawValue) != \(newDetectedObject.type.rawValue)")
//                    continue
//                }
//                if object.location.isMidXClose(to: newDetectedObject.location) { //if trackedObject intersects with the newDetectedObject in array
//                    if object.confidence < newDetectedObject.confidence { //if newDetectedObject has lower confidence... remove detectedObject
//                        detectedObjects.remove(at: index)
//                    } else {
//                        shouldAddObject = false
//                    }
//                    break
//                } else {
//                    print("Not midx close to for \(object.type.rawValue) and \(newDetectedObject.type.rawValue)")
//                }
//            }
//            if shouldAddObject {
//                detectedObjects.append(newDetectedObject)
//            }
//        }
////        print("There are \(detectedObjects.count) objects found out of \(highConfidenceObjects.count) and \(recognizedObjects.count)")
//        return detectedObjects
//    }
//}

extension VNRecognizedObjectObservation {
    var formattedConfidenceLabel: String {
        guard let identifier = self.labels.first?.identifier else { return "" }
        let percentageFormatter = NumberFormatter()
        percentageFormatter.numberStyle = .percent
        guard let value = percentageFormatter.string(from: NSNumber(value: confidence))
        else { return "" }
        return "\(identifier): \(value)"
    }
}

extension UIView {
    public func toImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
