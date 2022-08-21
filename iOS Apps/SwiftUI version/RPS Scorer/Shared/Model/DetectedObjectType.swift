//
//  DetectedObjectType.swift
//  RPS Scorer (iOS)
//
//  Created by Samuel Folledo on 8/21/22.
//

import UIKit.UIColor
import Vision.VNObservation

enum DetectedObjectType: String {
    case macMini, clock, pinkStickyNote, yellowStickyNote, scissor, rock, paper, pen, remote, applePencil, keyboard, macbook, handSanitizer, sprayBottle, unknown
    
    ///Color for previewView's bounding box
    var color: UIColor {
        switch self {
        case .rock:
            return .yellow
        case .paper:
            return .green
        case .scissor:
            return .cyan
        case .unknown:
            return .red
        default: //the rest of the object type will have a white border
            return .white
        }
    }
    
    static var allObjectTypes: [DetectedObjectType] = [
        .macMini,
        .clock,
        .pinkStickyNote,
        .yellowStickyNote,
        .scissor,
        .rock,
        .paper,
        .pen,
        .remote,
        .applePencil,
        .keyboard,
        .macbook,
        .handSanitizer,
        .sprayBottle,
        .unknown,
    ]
    
    init(trackedObject: VNRecognizedObjectObservation) {
        guard let label = trackedObject.labels.first?.identifier,
              let objectType = DetectedObjectType(name: label) else {
            assertionFailure("Unable to retrieve identifier for result: \(trackedObject)")
            self = .unknown
            return
        }
        self = objectType
    }
    
    init?(name: String) {
        switch name {
        case "scissor", "scissors":
            self = .scissor
        case "rock":
            self = .rock
        case "paper":
            self = .paper
        case "mac  mini":
            self = .macMini
        case "apple  pencil", "applePencil":
            self = .applePencil
        case "pinkStickyNote", "pink  sticky  note":
            self = .pinkStickyNote
        case "yellowStickyNote", "yellow  sticky  note":
            self = .yellowStickyNote
        case "pen":
            self = .pen
        case "remote":
            self = .remote
        case "clock":
            self = .clock
        case "macbook":
            self = .macbook
        case "keyboard":
            self = .keyboard
        case "sprayBottle", "spray  bottle":
            self = .sprayBottle
        case "handSantizer", "hand  sanitizer":
            self = .handSanitizer
        default:
            return nil
        }
    }
}

extension DetectedObjectType {
    var supportedValues: [String] {
        switch self {
        case .scissor:
            return ["scissor", "scissors"]
        case .rock:
            return ["rock"]
        case .paper:
            return ["paper"]
        case .macMini:
            return ["macMini", "mac  mini"]
        case .clock:
            return ["clock"]
        case .pinkStickyNote:
            return ["pinkStickyNote", "pink  sticky  note"]
        case .yellowStickyNote:
            return ["yellowStickyNote", "yellow sticky  note"]
        case .pen:
            return ["pen"]
        case .remote:
            return ["remote"]
        case .applePencil:
            return ["applePencil", "apple  pencil"]
        case .macbook:
            return ["macbook"]
        case .keyboard:
            return ["keyboard"]
        case .sprayBottle:
            return ["sprayBottle", "spray  bottle"]
        case .handSanitizer:
            return ["handSantizer", "hand  sanitizer"]
        case .unknown:
            return ["unknown"]
        }
    }

    ///checks the first item should be tracked or not
    static func shouldTrack(items: [DetectedObjectType], for classifier: String) -> Bool {
        return items.first(where: { $0.supportedValues.contains(classifier)} ) != nil
    }
}
