//
//  VisionService.swift
//  AI_RPS_Game
//
//  Created by Samuel Folledo on 5/6/21.
//

import Foundation
import UIKit.UIColor
import Vision

protocol VisionServiceInputs {
    func performRequest(for imageRequestHandler: VNImageRequestHandler)
    func updateTrackedItems(trackedItems: [DetectedObjectType])
}

protocol ObjectScannerProtocol {
    func updateDetectedObjects(newDetectedObjects: [DetectedObject])
}

class VisionService: VisionServiceInputs {
    
    //MARK: Enum
    enum Config {
        /// Confidence in % expressed from 0 - 1 which will be used
        /// to draw bounding boxes on the images in the preview
        static let confidence: VNConfidence = 0.2
    }
    
    // MARK: Private
    fileprivate var requests = [VNRequest]()

    /// Preview used to draw bounding boxes with detected items
    fileprivate var previewView: CameraPreview!
    fileprivate var trackedItems: [DetectedObjectType] = []
    fileprivate var delegate: ObjectScannerProtocol? //use delegate protocol in the future
    private var isUvulaAvailable: Bool = false
    private var isPharynxAvailable: Bool = false

    // MARK: Public
    init(with preview: CameraPreview, trackedItems: [DetectedObjectType] = [], delegate: ObjectScannerProtocol) {
        self.previewView = preview
        self.trackedItems = trackedItems
        self.delegate = delegate
        setupVisionModel()
    }

    // MARK: Inputs

    func performRequest(for imageRequestHandler: VNImageRequestHandler) {
        do {
            try imageRequestHandler.perform(requests)
        } catch {
            fatalError("Vision Service: perform request error: \(error.localizedDescription)")
        }
    }

    func updateTrackedItems(trackedItems: [DetectedObjectType]) {
        self.trackedItems = trackedItems
    }
    
    ///returns the bounding boxes
    func capturePhoto() -> UIImage {
        return previewView.toImage()
    }
}

// MARK: - Vision
extension VisionService {

    private func setupVisionModel() {
//        let model = VisionModelLoader.getModel()
        let request = VNCoreMLRequest(model: VisionModel.visionModel, completionHandler: completionRequestHandler)
        request.imageCropAndScaleOption = .scaleFill
        self.requests = [request]
    }

    func completionRequestHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRecognizedObjectObservation],
              !observations.isEmpty
        else { return }
        DispatchQueue.main.async {
            self.drawVisionRequestResults(results: observations)
        }
    }

    func drawVisionRequestResults(results: [VNRecognizedObjectObservation]) {
        // remove all previously added masks
        previewView.removeMasks()
        //filter out objects detected with low confidence
        let highConfidenceObjects = results.filter({ $0.confidence >= Config.confidence })
        // CoreGraphics => transforming origin from top left corner to bottom left corner
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -self.previewView.frame.height)
        let translate = CGAffineTransform.identity.scaledBy(x: self.previewView.frame.width, y: self.previewView.frame.height)
        var detectedObjects: [DetectedObject] = []
        for trackedObject in highConfidenceObjects { //loop through each detected objects
            //get trackedObject's location
            let rectangularLocation = trackedObject.boundingBox.applying(translate).applying(transform)
            //create a detectedObject model from the trackedObject
            guard let newDetectedObject = DetectedObject(trackedObject: trackedObject, location: rectangularLocation) else { continue }
            //loop through each detectedObjects appended already and make sure to remove detectedObjects that has duplicates and lower confidence
            var shouldAppend = true
            for (index, object) in detectedObjects.enumerated() {
                if object.type != newDetectedObject.type { continue }
                if object.location.intersects(newDetectedObject.location) { //if trackedObject intersects with the newDetectedObject in array
                    if object.confidence < newDetectedObject.confidence { //if newDetectedObject has lower confidence... remove detectedObject
                        detectedObjects.remove(at: index)
                    } else {
                        shouldAppend = false
                    }
                    break
                }
            }
            if shouldAppend {
                detectedObjects.append(newDetectedObject)
            }
        }
        print(detectedObjects.map{$0.type})
        //draw the bounding boxes
        for part in detectedObjects {
            previewView.drawLayer(in: part.location, color: part.type.color, with: part.confidenceText)
        }
        delegate?.updateDetectedObjects(newDetectedObjects: detectedObjects)
    }
}

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
