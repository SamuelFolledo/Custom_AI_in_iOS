//
//  ThroatPartType.swift
//  AI_RPS_Game
//
//  Created by Samuel Folledo on 5/6/21.
//

import UIKit.UIColor
import Vision.VNObservation

enum DetectedObjectType: String {
    case macMini, clock, pinkStickyNote, yellowStickyNote, scissor, rock, paper, pen, remote, applePencil, unknown
    var color: UIColor {
        switch self {
        case .rock:
            return .yellow
        case .paper:
            return UIColor(r: 203, g: 195, b: 227, a: 1) //light purple
        case .scissor:
            return .cyan
        case .unknown:
            return .red
        default:
            return .white
        }
    }
    
    static var allObjectTypes = [
        DetectedObjectType.macMini,
        DetectedObjectType.clock,
        DetectedObjectType.pinkStickyNote,
        DetectedObjectType.yellowStickyNote,
        DetectedObjectType.scissor,
        DetectedObjectType.rock,
        DetectedObjectType.paper,
        DetectedObjectType.pen,
        DetectedObjectType.remote,
        DetectedObjectType.applePencil,
        DetectedObjectType.unknown,
    ]
    
    init(trackedObject: VNRecognizedObjectObservation) {
        guard let label = trackedObject.labels.first?.identifier, let throatPart = DetectedObjectType(rawValue: label) else {
            assertionFailure("Unable to retrieve identifier for result: \(trackedObject)")
            self = .unknown
            return
        }
        self = throatPart
    }
}

extension DetectedObjectType {
    var supportedValues: [String] {
        switch self {
        case .macMini:
            return ["macMini"]
        case .clock:
            return ["clock"]
        case .pinkStickyNote:
            return ["pinkStickyNote"]
        case .yellowStickyNote:
            return ["yellowStickyNote"]
        case .scissor:
            return ["scissor"]
        case .rock:
            return ["rock"]
        case .paper:
            return ["paper"]
        case .pen:
            return ["pen"]
        case .remote:
            return ["remote"]
        case .applePencil:
            return ["applePencil"]
        case .unknown:
            return ["unknown"]
        }
    }

    static func shouldTrack(items: [DetectedObjectType], for classifier: String) -> Bool {
        return items.first(where: { $0.supportedValues.contains(classifier)} ) != nil
    }
}


//enum ThroatPartType: String {
//    case pharynx, tongue, tonsil, uvula, unknown
//
//    var color: UIColor {
//        switch self {
//        case .pharynx:
//            return .yellow
//        case .tongue:
//            return UIColor(r: 203, g: 195, b: 227, a: 1) //light purple
//        case .tonsil:
//            return .cyan
//        case .uvula:
//            return .green
//        case .unknown:
//            return .clear
//        }
//    }
//
//    init(trackedObject: VNRecognizedObjectObservation) {
//        guard let label = trackedObject.labels.first?.identifier, let throatPart = ThroatPartType(rawValue: label) else {
//            assertionFailure("Unable to retrieve identifier for result: \(trackedObject)")
//            self = .unknown
//            return
//        }
//        self = throatPart
//    }
//}
//
//extension ThroatPartType {
//    var supportedValues: [String] {
//        switch self {
//        case .pharynx:
//            return ["pharynx"]
//        case .tongue:
//            return ["tongue"]
//        case .tonsil:
//            return ["tonsil"]
//        case .uvula:
//            return ["uvula"]
//        case .unknown:
//            return ["unknown"]
//        }
//    }
//
//    static func shouldTrack(items: [ThroatPartType], for classifier: String) -> Bool {
//        return items.first(where: { $0.supportedValues.contains(classifier)} ) != nil
//    }
//}
