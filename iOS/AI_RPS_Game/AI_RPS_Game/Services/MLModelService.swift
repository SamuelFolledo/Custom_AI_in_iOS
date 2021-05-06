//
//  MLModelService.swift
//  AI_RPS_Game
//
//  Created by Samuel Folledo on 5/6/21.
//

import Foundation
import CoreML
import Vision

private enum VisionModel {
    static var visionModel: VNCoreMLModel {
        get {
            guard let model = try? VNCoreMLModel(for: my_custom_model(configuration: MLModelConfiguration()).model) else {
                fatalError("Could not load model")
            }
            return model
        }
    }
}

enum VisionModelLoader  {

    // MARK: - Public
    static var currentlySelectedModel: VisionModelLoader.Model = .productionThroatModel
    static var modelDidUpdate: ((VisionModelLoader.Model) -> Void)?

    static func getModel() -> VNCoreMLModel {
        switch currentlySelectedModel {
        case .productionThroatModel:
            return VisionModel.visionModel
        case .testThroatModel:
            return VisionModel.visionModel
        }
    }

    static func switchModel(to model: VisionModelLoader.Model) {
        currentlySelectedModel = model
        modelDidUpdate?(model)
    }
}

//MARK: - Enum extension
extension VisionModelLoader {
    enum Model: Int, CaseIterable {
        case productionThroatModel, testThroatModel

        var modelDescription: String {
            switch self {
            case .productionThroatModel:
                return "Actual Model"
            case .testThroatModel:
                return "Testing Trained Model"
            }
        }

        var title: String {
            switch self {
            case .productionThroatModel:
                return "Throat Model"
            case .testThroatModel:
                return "Testing Throat Model"
            }
        }
    }
}
