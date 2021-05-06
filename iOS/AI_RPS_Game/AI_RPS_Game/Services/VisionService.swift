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
    func updateTrackedItems(trackedItems: [ThroatPartType])
}

protocol ThroatPartScannerProtocol {
    func updateThroatParts(newThroatParts: [ThroatPart])
}

class VisionService: VisionServiceInputs {
    
    //MARK: Enum
    enum Config {
        /// Confidence in % expressed from 0 - 1 which will be used
        /// to draw bounding boxes on the images in the preview
        static let confidence: VNConfidence = 0.4
    }
    
    // MARK: Private
    fileprivate var requests = [VNRequest]()

    /// Preview used to draw bounding boxes with detected items
    fileprivate var previewView: CameraPreview!
    fileprivate var trackedItems: [ThroatPartType] = []
    fileprivate var delegate: ThroatPartScannerProtocol? //use delegate protocol in the future
    private var isUvulaAvailable: Bool = false
    private var isPharynxAvailable: Bool = false

    // MARK: Public
    init(with preview: CameraPreview, trackedItems: [ThroatPartType] = [], delegate: ThroatPartScannerProtocol) {
        self.previewView = preview
        self.trackedItems = trackedItems
        self.delegate = delegate
        setupVision()
    }

    // MARK: Inputs

    func performRequest(for imageRequestHandler: VNImageRequestHandler) {
        do {
            try imageRequestHandler.perform(requests)
        } catch {
            fatalError("Vision Service: perform request error: \(error.localizedDescription)")
        }
    }

    func updateTrackedItems(trackedItems: [ThroatPartType]) {
        self.trackedItems = trackedItems
    }
    
    ///returns the bounding boxes
    func capturePhoto() -> UIImage {
        return previewView.toImage()
    }
}

// MARK: - Vision
extension VisionService {
    
    func setupVision() {
        VisionModelLoader.modelDidUpdate = {[weak self] _ in
            self?.setupVision()
        }
        setupVisionModel()
    }

    private func setupVisionModel() {
        let model = VisionModelLoader.getModel()
        let request = VNCoreMLRequest(model: model, completionHandler: completionRequestHandler)
        request.imageCropAndScaleOption = .scaleFill
        self.requests = [request]
    }

    func completionRequestHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRecognizedObjectObservation], !observations.isEmpty else {
            return
        }
        DispatchQueue.main.async {
            self.drawVisionRequestResults(results: observations)
        }
    }

    func drawVisionRequestResults(results: [VNRecognizedObjectObservation]) {
        // remove all previously added masks
        previewView.removeMasks()
        //filter out objects detected with low confidence
        let detectedObjects = results.filter({ $0.confidence >= Config.confidence })
        // CoreGraphics => transforming origin from top left corner to bottom left corner
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -self.previewView.frame.height)
        let translate = CGAffineTransform.identity.scaledBy(x: self.previewView.frame.width, y: self.previewView.frame.height)
        var throatParts: [ThroatPart] = []
        for trackedObject in detectedObjects { //loop through each detected objects
            //get throat part's location
            let rectangularLocation = trackedObject.boundingBox.applying(translate).applying(transform)
            //create a throat part model from the trackedObject
            guard let newThroatPart = ThroatPart(trackedObject: trackedObject, location: rectangularLocation) else { continue }
            //loop through each throatParts appended already and make sure to remove throat parts that has low confidence
            var shouldAppend = true
            for (index, throatPart) in throatParts.enumerated() {
                if throatPart.type != newThroatPart.type { continue }
                if throatPart.location.intersects(newThroatPart.location) { //if throatPart intersects with the newThroatPart in array
                    if throatPart.confidence < newThroatPart.confidence { //if throatPart has lower confidence... remove throat part
                        throatParts.remove(at: index)
                    } else {
                        shouldAppend = false
                    }
                    break
                }
            }
            if shouldAppend {
                throatParts.append(newThroatPart)
            }
        }
        print(throatParts.map{$0.type})
        //draw the bounding boxes
        for part in throatParts {
            previewView.drawLayer(in: part.location, color: part.type.color, with: part.confidenceText)
        }
        delegate?.updateThroatParts(newThroatParts: throatParts)
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
