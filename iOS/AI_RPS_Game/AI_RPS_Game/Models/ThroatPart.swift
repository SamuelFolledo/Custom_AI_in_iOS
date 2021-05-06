//
//  ThroatPart.swift
//  AI_RPS_Game
//
//  Created by Samuel Folledo on 5/6/21.
//

import UIKit.UIImage
import Vision.VNObservation

protocol ThroatImage {
    var type: DetectedObjectType { get }
    var image: UIImage! { get }
    var isSelected: Bool { get set }
}

struct UnknownThroatPart: ThroatImage {
    var image: UIImage!
    var isSelected: Bool = true
    var type: DetectedObjectType = .unknown
    
    init(image: UIImage) {
        self.image = image
    }
}

struct ThroatPart: Identifiable, ThroatImage {
    let id = String.randomString(length: 10)
    private(set) var type: DetectedObjectType
    private(set) var confidence: VNConfidence
    private(set) var confidenceText: String
    private(set) var location: CGRect
    private(set) var image: UIImage!
    var isSelected = true
    
    init?(trackedObject: VNRecognizedObjectObservation, location: CGRect) {
        guard let label = trackedObject.labels.first?.identifier, let throatPart = DetectedObjectType(rawValue: label) else {
//            assertionFailure("Unable to retrieve identifier for result: \(trackedObject)")
            return nil
        }
        self.type = throatPart
        self.confidence = trackedObject.confidence
        self.confidenceText = trackedObject.formattedConfidenceLabel
        self.location = location
    }
    
    mutating func updateImage(image: UIImage) {
        self.image = image
    }
}
