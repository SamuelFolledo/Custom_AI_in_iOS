//
//  ObjectDetectionController.swift
//  AI_RPS_Game
//
//  Created by Samuel Folledo on 4/28/21.
//

import UIKit
import AVFoundation
import Vision

class ObjectDetectionController: UIViewController {
    
    // MARK: Properties
    private var currentP1Move: Move?
    private var currentP2Move: Move?
    private let maxScore: Int = 5
    private var currentRound: Int = 1
    private let defaultPhotosToTake: Int = 16
    private var numberOfPhotosToTake: Int = 16
    private let cameraShutterSoundID: SystemSoundID = 1108 // use 1157 if 1108 is unsavory
    private var trackedItems: [DetectedObjectType] = DetectedObjectType.allObjectTypes
    private var camera: Camera!
    private var visionService: VisionService!
    private var delayTimer: Timer?
    private var willDelay: Bool = false
    private var p1Score: Int = 0 {
        didSet { p1Label.text = "P1: \(p1Score)" }
    }
    private var p2Score: Int = 0 {
        didSet { p2Label.text = "P2: \(p2Score)" }
    }
    
    //MARK: UI Components
    private let captureButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        button.addTarget(ObjectDetectionController.self, action: #selector(captureButtonTapped), for: .touchUpInside)
        button.alpha = 0
        return button
    }()
    private let brightnessSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.1
        slider.maximumValue = 1.0
        slider.isContinuous = true
        slider.tintColor = UIColor.green
        slider.transform = CGAffineTransform(rotationAngle: CGFloat(-(Double.pi) / 2))
        slider.setValue(100, animated: true)
        slider.addTarget(ObjectDetectionController.self, action: #selector(brightnessLevelDidChange(_:)), for: .valueChanged)
        return slider
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "RPS Scorer"
        label.textAlignment = .center
        label.font = .font(size: 32, weight: .bold, design: .default)
        label.numberOfLines = 2
        label.textColor = .white
        label.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        label.layer.cornerRadius = 5
        label.layer.borderWidth = 2
        label.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        return label
    }()
    private lazy var p1Label: UILabel = {
        let label = UILabel()
        label.text = "P1: \(p1Score)"
        label.textAlignment = .center
        label.font = .font(size: 24, weight: .medium, design: .default)
        label.numberOfLines = 1
        label.textColor = .white
        label.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        label.layer.cornerRadius = 5
        label.layer.borderWidth = 2
        label.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        return label
    }()
    private lazy var p2Label: UILabel = {
        let label = UILabel()
        label.text = "P2: \(p2Score)"
        label.textAlignment = .center
        label.font = .font(size: 24, weight: .medium, design: .default)
        label.numberOfLines = 1
        label.textColor = .white
        label.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        label.layer.cornerRadius = 5
        label.layer.borderWidth = 2
        label.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        return label
    }()
    private lazy var previewView: CameraPreview = {
        let view = CameraPreview()
        return view
    }()
    
    //MARK: - App Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        configureVision()
        configureCamera()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        camera.stop()
    }
    
    //MARK: - Override Methods
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        captureButton.removeOuterBorders()
        captureButton.addTightOuterRoundedBorder(borderWidth: 10, borderColor: UIColor.white.withAlphaComponent(0.2))
    }
    
    //MARK: - Private Methods
    fileprivate func setupViews() {
        setupBackground()
        constraintCameraPreview()
        //instruction label
        previewView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            titleLabel.widthAnchor.constraint(equalToConstant: view.frame.width - 16),
            titleLabel.heightAnchor.constraint(equalToConstant: 50),
        ])
        //p1 label
        view.addSubview(p1Label)
        p1Label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            p1Label.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            p1Label.leftAnchor.constraint(equalTo: titleLabel.leftAnchor, constant: 0),
            p1Label.widthAnchor.constraint(equalToConstant: 100),
            p1Label.heightAnchor.constraint(equalToConstant: 40),
        ])
        //p2 label
        view.addSubview(p2Label)
        p2Label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            p2Label.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            p2Label.rightAnchor.constraint(equalTo: titleLabel.rightAnchor, constant: 0),
            p2Label.widthAnchor.constraint(equalToConstant: 100),
            p2Label.heightAnchor.constraint(equalToConstant: 40),
        ])
    }
    
    fileprivate func setupBackground() {
        view.backgroundColor = .systemBackground
    }
    
    private func enableCaptureButton(_ enable: Bool) {
        UIView.animate(withDuration: 0.2) {
            if enable {
                self.captureButton.isEnabled = true
                self.captureButton.alpha = 1
            } else {
                self.captureButton.isEnabled = false
                self.captureButton.alpha = 0
            }
        }
    }
}

//MARK: - UI Actions
extension ObjectDetectionController {
    /// change brightness level based on the value of slider
    @objc func brightnessLevelDidChange(_ sender: UISlider!) {
        let step: Float = 100
        let roundedStepValue = (sender.value * step).rounded() / step
        sender.value = roundedStepValue
        if let device = AVCaptureDevice.default(for: AVMediaType.video) {
            do {
                try device.lockForConfiguration()
//                try device.setTorchModeOn(level: roundedStepValue)
                device.unlockForConfiguration()
            } catch {
                print("Error using torch")
            }
        }
    }
    
    @objc func captureButtonTapped() {
        capturePhotos()
    }
    
    func capturePhotos() {
        enableCaptureButton(false)
        numberOfPhotosToTake = 16
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            for i in 0 ..< self.numberOfPhotosToTake {
                print("Taking manual photo #", i+1)
                self.camera.takePhoto()
                if i != 0 && i != 10 && i != self.numberOfPhotosToTake { //&& !self.audioFeedbackButton.isSelected {
                    AudioServicesPlaySystemSound(self.cameraShutterSoundID)
                }
                usleep(500000)
            }
            self.enableCaptureButton(true)
            print("Done manually taking photos")
        }
    }
}

// MARK: - Camera Setup
private extension ObjectDetectionController {
    func configureVision() {
        //must reinitialize or camera preview will be frozen
        visionService = VisionService(with: previewView, trackedItems: trackedItems, delegate: self)
    }
    
    func configureCamera() {
        camera = Camera(with: self)
        camera.startCameraSession { (error) in
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    self?.presentAlert(title: "Camera Start Session Error", message: error.localizedDescription)
                }
            }
            DispatchQueue.main.async { [weak self] in
                self?.camera.getPreviewLayer(for: self!.previewView)
                self?.camera.toggleLight(on: true)
            }
        }
    }
    
    func constraintCameraPreview() {
        previewView = CameraPreview()
        previewView.removeMasks()
        view.addSubview(previewView)
        previewView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            previewView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            previewView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            previewView.widthAnchor.constraint(equalToConstant: view.frame.width),
            previewView.heightAnchor.constraint(equalToConstant: view.frame.height),
        ])
    }
}


//MARK: AVCaptureVideoDataOutputSampleBufferDelegate
extension ObjectDetectionController: AVCaptureVideoDataOutputSampleBufferDelegate {
    //Delegate method that notifies the delegate that a new video frame was written.
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if visionService == nil {
            DispatchQueue.main.async {
                self.previewView.removeMasks()
            }
            return
        }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        var requestOptions: [VNImageOption: Any] = [:]
        if let cameraIntrensicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics: cameraIntrensicData]
        }
        let exifOrientation = camera!.exifOrientationFromDeviceOrientation()
        let orientation = CGImagePropertyOrientation(rawValue: UInt32(exifOrientation))!
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: requestOptions)
        visionService.performRequest(for: imageRequestHandler)
    }
}

//MARK: - AVCapturePhotoCaptureDelegate
extension ObjectDetectionController: AVCapturePhotoCaptureDelegate {
    //Delegate method called when a photo is captured
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error processing photo \(error.localizedDescription)")
        } else if let dataImage = photo.fileDataRepresentation() {
            //if no error, then get the image and append to detectedObjectImages
            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            let imageOrientation: UIImage.Orientation = .up
            let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: imageOrientation)
            print("Got the image output \(image)")
        } else {
            presentAlert(title: "Image Error", message: "Failed to get an image")
        }
    }
}

//MARK: Pharynx Guide
extension ObjectDetectionController: ObjectScannerProtocol {
    func updateDetectedObjects(newDetectedObjects: [DetectedObject]) {
        //get first object and focus
//        guard let firstObject = newDetectedObjects.first else { return }
//        updateCameraFocusPoint(detectedObject: firstObject)
//        camera.takePhoto()
        //get the objects and assign p1 or p2
        if willDelay {
            print("Waiting...")
            return
        }
        startDelayTimer()
        setPlayerMoves(from: newDetectedObjects)
        if let p1Move = currentP1Move, let p2Move = currentP2Move { //if p1Move and p2Move is populated
            print("Now has 2 moves set")
            //add a delay
            let roundResult = getCurrentRoundResult(p1Move: p1Move.type, p2Move: p2Move.type)
            activateSpeech(result: roundResult)
            switch roundResult {
            case .tieRound:
                startNextRound()
            case .p1WonRound:
                p1Score += 1
                startNextRound()
            case .p2WonRound:
                p2Score += 1
                startNextRound()
            case .p1WonGame, .p2WonGame:
                gameOver(result: roundResult)
            }
        } else {
            if currentP1Move == nil {
                print("p1 move is not set yet")
            } else if currentP2Move == nil {
                print("p2 move is not set yet")
            }
        }
        print("--------------------------------------------")
    }
    
    private func startDelayTimer() {
        let delayLength: CGFloat = 2
        willDelay = true
        delayTimer = Timer.scheduledTimer(timeInterval: TimeInterval(delayLength), target: self, selector: #selector(updateDelayTimer), userInfo: nil, repeats: true)
    }
    
    /**
     Sets player 1 and player 2's moves
     - Parameter - an array of detected objects, must have at least 2 elements
     */
    private func setPlayerMoves(from newDetectedObjects: [DetectedObject]) {
        if newDetectedObjects.isEmpty {
            print("WARNING: Failed to set mvoes because newDetectedObjects is empty")
        } else if newDetectedObjects.count == 1 {
            let move = Move(detectedObject: newDetectedObjects[0])
            if move.isP1 && (currentP1Move == nil || currentP1Move?.type == move.type) {
                print("1 object found for p1 \(move.type)")
                currentP1Move = move
            } else if !move.isP1 && (currentP2Move == nil || currentP2Move?.type == move.type) {
                print("1 object found for p2 \(move.type)")
                currentP2Move = move
            } else {
                print("WARNING: Unhandled current move case")
            }
        } else if newDetectedObjects.count > 1 {
            //compare locations
            for (index, object) in newDetectedObjects.enumerated() where index != newDetectedObjects.count - 1 { //loop through each object excluding the last element in the array
                for nextIndex in index+1 ..< newDetectedObjects.count { //compare once with other objects in the array that is located elsewhere
                    let move = Move(detectedObject: object)
                    let nextMove = Move(detectedObject: newDetectedObjects[nextIndex])
                    if move.isP1 && nextMove.isP1 {
                        print("Both moves are from p1")
                        continue
                    }
                    if move.location.isMidXClose(to: nextMove.location) {
                        print("WARNING: Unhandled move 1 and move 2 midX is close and might the same object")
                    } else {
                        if move.location.isOnTheLeftOf(nextMove.location) {
                            currentP1Move = move
                            currentP2Move = nextMove
                        } else {
                            currentP1Move = nextMove
                            currentP2Move = move
                        }
                        print("Updated player moves with p1 \((currentP1Move != nil) ? currentP1Move!.type.rawValue : "") and p2 \((currentP2Move != nil) ? currentP2Move!.type.rawValue : "")")
                    }
                }
            }
        } else {
            print("WARNING: Unhandled newDetectedObjects < 0")
        }
    }
    
    ///return current round's result
    private func getCurrentRoundResult(p1Move: DetectedObjectType, p2Move: DetectedObjectType) -> RoundResult {
        var roundResult: RoundResult = .tieRound
        if p1Move == p2Move {
            roundResult = .tieRound
        }
        if (p1Move == .paper && p2Move == .scissor) || (p1Move == .rock && p2Move == .paper) || (p1Move == .scissor && p2Move == .rock) {
            roundResult = .p2WonRound
        } else if (p1Move == .rock && p2Move == .scissor) || (p1Move == .scissor && p2Move == .paper) || (p1Move == .paper && p2Move == .rock) {
            roundResult = .p1WonRound
        }
        if(roundResult == .p1WonRound && p1Score + 1 >= maxScore) {
            roundResult = .p1WonGame
        } else if(roundResult == .p2WonRound && p2Score + 1 >= maxScore) {
            roundResult = .p2WonGame
        }
        return roundResult
    }
    
    //MARK: DetectedObjectScanner Helpers
    
    ///have Siri read from a text
    private func activateSpeech(result: RoundResult) {
        // Line 1. Create an instance of AVSpeechSynthesizer.
        let speechSynthesizer = AVSpeechSynthesizer()
        // Line 2. Create an instance of AVSpeechUtterance and pass in a String to be spoken.
        let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: result.announcement)
        //Line 3. Specify the speech utterance rate. 1 = speaking extremely the higher the values the slower speech patterns. The default rate, AVSpeechUtteranceDefaultSpeechRate is 0.5
//        speechUtterance.rate = AVSpeechUtteranceMaximumSpeechRate / 4.0
        // Line 4. Specify the voice. It is explicitly set to English here, but it will use the device default if not specified.
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        // Line 5. Pass in the urrerance to the synthesizer to actually speak.
        speechSynthesizer.speak(speechUtterance)
    }
    
    ///helper to reset round
    private func startNextRound() {
        currentRound += 1
        currentP1Move = nil
        currentP2Move = nil
        print("")
        print("==================================")
        print("Starting round \(currentRound)")
    }
    
    private func gameOver(result: RoundResult) {
        delayTimer?.invalidate()
        willDelay = true
        switch result {
        case .tieRound, .p1WonRound, .p2WonRound:
            break
        case .p1WonGame, .p2WonGame:
            titleLabel.text = result.rawValue
        }
    }
    
    ///updates the camera's focus point at the detectedObject's mid point location
    private func updateCameraFocusPoint(detectedObject: DetectedObject) {
        let midPoint = CGPoint(x: detectedObject.location.midX, y: detectedObject.location.midY)
        camera.updateCameraFocusPoint(midPoint: midPoint)
    }
    
    @objc func updateDelayTimer() {
        delayTimer?.invalidate()
        willDelay = false
    }
}

//MARK: - Enums/Structs
private extension ObjectDetectionController {
    enum RoundResult: String {
        case tieRound, p1WonRound, p2WonRound, p1WonGame, p2WonGame
        
        var description: String {
            return self.rawValue
        }
        
        var announcement: String {
            get {
                switch self {
                case .tieRound: return "Tied"
                case .p1WonRound: return "Player 1 plus 1"
                case .p2WonRound: return "Player 2 plus 1"
                case .p1WonGame: return "Player 1 wins"
                case .p2WonGame: return "Player 2 wins"
                }
            }
        }
    }
    
    struct Move {
        private var object: DetectedObject
        
        var isP1: Bool
        var type: DetectedObjectType
        var location: CGRect
        
        init(detectedObject: DetectedObject) {
            self.object = detectedObject
            self.type = detectedObject.type
            self.location = detectedObject.location
            if detectedObject.location.isOnTheLeftScreen() {
                //if object's midX is on the left half of the screen, assume it is p1's move
                print("move created for p1 = \(detectedObject.type)")
                isP1 = true
            } else {
                print("move created for p2 = \(detectedObject.type)")
                isP1 = false
            }
        }
        
        func isOnTheLeftSideOfScreen() -> Bool {
            return location.isOnTheLeftScreen()
        }
    }
}
