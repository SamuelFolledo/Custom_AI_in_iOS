//
//  DetectedObject.swift
//  RPS Scorer (iOS)
//
//  Created by Samuel Folledo on 8/21/22.
//

import UIKit.UIImage
import Vision.VNObservation

protocol DetectedObjectImage {
    var type: DetectedObjectType { get }
    var image: UIImage! { get }
    var isSelected: Bool { get set }
}

struct UnknownDetectedObject: DetectedObjectImage {
    var image: UIImage!
    var isSelected: Bool = true
    var type: DetectedObjectType = .unknown
    
    init(image: UIImage) {
        self.image = image
    }
}

struct DetectedObject: Identifiable, DetectedObjectImage {
    let id = String.randomString(length: 10)
    private(set) var type: DetectedObjectType
    private(set) var confidence: VNConfidence
    private(set) var confidenceText: String
    private(set) var location: CGRect
    private(set) var image: UIImage! //currently unused
    var isSelected = false //currently unused
    
    init?(trackedObject: VNRecognizedObjectObservation, location: CGRect) {
        guard let label = trackedObject.labels.first?.identifier,
              let objectType = DetectedObjectType(name: label) else {
            print("Unable to retrieve identifier for result: \(trackedObject)")
            return nil
        }
        self.type = objectType
        self.confidence = trackedObject.confidence
        self.confidenceText = trackedObject.formattedConfidenceLabel
        self.location = location
    }
    
    mutating func updateImage(image: UIImage) {
        self.image = image
    }
    
    func intersectsWith(anotherObject: DetectedObject) -> Bool {
        if !location.intersects(anotherObject.location) { //if it does not intersects...
            return false
        }
        if abs(location.minX - anotherObject.location.minX) > 100 { //if their location is close, it may be the same object
            return false
        }
        return true
    }
}

extension CGRect {
    func isOnTheLeftScreen() -> Bool {
        return self.midX < UIScreen.main.bounds.width / 2
    }
    
    func isOnTheLeftOf(_ location: CGRect) -> Bool {
        let distance = midX - location.midX
        if distance == 0 {
            print("WARNING: 0 distance between \(midX) and \(location.midX)")
            return false
        } else if distance < 0 {
            return true
        }
        return false
    }
    
    func isMidXClose(to: CGRect) -> Bool {
        return abs(midX - to.midX) < 100
    }
}
