//
//  ObjectDetectionController.swift
//  AI_RPS_Game
//
//  Created by Samuel Folledo on 4/28/21.
//

//import SnapKit
import UIKit
import AVFoundation
import Vision

class ObjectDetectionController: UIViewController {
    
    // MARK: Properties
    private var currentP1Move: DetectedObject?
    private var currentP2Move: DetectedObject?
    private let maxScore: Int = 5
    private var currentRound: Int = 0
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
        button.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
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
        slider.addTarget(self, action: #selector(brightnessLevelDidChange(_:)), for: .valueChanged)
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
//    private lazy var instructionsButton: UIButton = {
//        let normalImage = UIImage(named: "question-mark")?.withTintColor(.white).withRenderingMode(.alwaysOriginal)
//        let button = AppService.createButton(type: .roundedGrayButton(image: normalImage))
//        button.addTarget(self, action: #selector(instructionButtonTapped), for: .touchUpInside)
//        return button
//    }()
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
    
    private func constraintCameraPreview() {
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
    
    func configureCamera() {
        camera = Camera(with: self)
        camera.startCameraSession { (error) in
            if let error = error {
                fatalError("Camera start sesssion error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async { [weak self] in
                self?.camera.getPreviewLayer(for: self!.previewView)
                self?.camera.toggleLight(on: true)
            }
        }
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
            print("Wait")
            return
        }
        if newDetectedObjects.count < 2 {
//            print("Theres 0-1 detected results")
        } else if newDetectedObjects.count > 2 {
            print("Theres more than 2 detected results")
        } else { //there's exactly 2 newDetectedObjects
            //add a delay
            let delayLength = 1.8
            willDelay = true
            delayTimer = Timer.scheduledTimer(timeInterval: TimeInterval(delayLength), target: self, selector: #selector(updateDelayTimer), userInfo: nil, repeats: true)
            //assign property for detectedObject.isP1
            let separatedObjects = separateDetectedObjects(newDetectedObjects: newDetectedObjects)
            //get result from p1 and p2 move
            let p1RoundResult = getP1RoundResults(detectedObjects: separatedObjects)
            updateRoundWith(p1RoundResult: p1RoundResult)
            print("round result p1 = \(p1RoundResult)\tScore = \(p1Score):\(p2Score)")
        }
    }
    
    ///updatee Views and play an audio based on round result
    private func updateRoundWith(p1RoundResult: RoundResult) {
        switch p1RoundResult {
        case .draw:
            activateSpeech(type: .tieRound)
            prepareNextRound()
        case .lose: //if p1 loses the round
            p2Score += 1
            if p2Score == maxScore {
                assignP1AsWinner(false)
            } else {
                activateSpeech(type: .p2WonRound)
                prepareNextRound()
            }
        case .win: //if p2 wins the round
            p1Score += 1
            if p1Score == maxScore {
                assignP1AsWinner(true)
            } else {
                activateSpeech(type: .p1WonRound)
                prepareNextRound()
            }
        }
    }
    
    ///call when p1 or p2 wins
    private func assignP1AsWinner(_ didP1Win: Bool) {
        delayTimer?.invalidate()
        willDelay = true
        if didP1Win {
            titleLabel.text = "P1 win!"
            activateSpeech(type: .p1WonGame)
        } else {
            titleLabel.text = "P2 win!"
            activateSpeech(type: .p2WonGame)
        }
    }
    
    ///helper to reset round
    private func prepareNextRound() {
        currentRound += 1
        currentP1Move = nil
        currentP2Move = nil
    }
    
    //MARK: DetectedObjectScanner Helpers
    
    ///updates the camera's focus point at the detectedObject's mid point location
    private func updateCameraFocusPoint(detectedObject: DetectedObject) {
        let midPoint = CGPoint(x: detectedObject.location.midX, y: detectedObject.location.midY)
        camera.updateCameraFocusPoint(midPoint: midPoint)
    }
    
    private func separateDetectedObjects(newDetectedObjects: [DetectedObject]) -> [DetectedObject] {
        var resultDetectedObjects = newDetectedObjects
        //compare locations
        for (index, object) in newDetectedObjects.enumerated() where index != newDetectedObjects.count - 1 { //loop through each object excluding the last element in the array
            for i in index+1 ..< newDetectedObjects.count { //compare once with other objects in the array that is located elsewhere
                let otherObject = newDetectedObjects[i]
                if object.location.minX == newDetectedObjects[i].location.minX { //if located at the same place, move to the next object
                    print("WHUT???? Detected same object???")
                    continue
                } else if object.location.minX > otherObject.location.minX { //if object is on the right side of otherObject
                    currentP1Move = otherObject
                    currentP2Move = object
                    resultDetectedObjects[index].isP1 = false
                    resultDetectedObjects[i].isP1 = true
                } else {
                    currentP1Move = object
                    currentP2Move = otherObject
                    resultDetectedObjects[index].isP1 = true
                    resultDetectedObjects[i].isP1 = false
                }
            }
        }
        return resultDetectedObjects
    }
    
    private func getP1RoundResults(detectedObjects: [DetectedObject]) -> RoundResult {
        if detectedObjects.count != 2 {
            print("WARNING: detectedObjects have a count \(detectedObjects.count), while expecting 2 only")
            return .draw
        }
        let firstMove = detectedObjects[0]
        let secondMove = detectedObjects[1]
        let p1Type: DetectedObjectType
        let p2Type: DetectedObjectType
        if let isFirstPlayer1 = firstMove.isP1, isFirstPlayer1 { //if first move is p1
            p1Type = firstMove.type
            p2Type = secondMove.type
        } else {
            p1Type = secondMove.type
            p2Type = firstMove.type
        }
        if p1Type == p2Type {
            return .draw
        }
        if (p1Type == .paper && p2Type == .scissor) || (p1Type == .rock && p2Type == .paper) || (p1Type == .scissor && p2Type == .rock) {
            return .lose
        } else if (p1Type == .rock && p2Type == .scissor) || (p1Type == .scissor && p2Type == .paper) || (p1Type == .paper && p2Type == .rock) {
            return .win
        }
        return .draw
    }
    
    @objc func updateDelayTimer() {
        //reset round
        print("next round")
        delayTimer?.invalidate()
        willDelay = false
    }
    
    private func activateSpeech(type: AnnouncementType) {
        // Line 1. Create an instance of AVSpeechSynthesizer.
        let speechSynthesizer = AVSpeechSynthesizer()
        // Line 2. Create an instance of AVSpeechUtterance and pass in a String to be spoken.
        let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: type.text)
        //Line 3. Specify the speech utterance rate. 1 = speaking extremely the higher the values the slower speech patterns. The default rate, AVSpeechUtteranceDefaultSpeechRate is 0.5
//        speechUtterance.rate = AVSpeechUtteranceMaximumSpeechRate / 4.0
        // Line 4. Specify the voice. It is explicitly set to English here, but it will use the device default if not specified.
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        // Line 5. Pass in the urrerance to the synthesizer to actually speak.
        speechSynthesizer.speak(speechUtterance)
    }
}

//MARK: - Enums Extension
extension ObjectDetectionController {
    private enum RoundResult {
        case win, lose, draw
    }
    
    private enum AnnouncementType {
        case p1WonGame, p2WonGame, p1WonRound, p2WonRound, tieRound
        var text: String {
            get {
                switch self {
                case .p1WonGame: return "Player 1 won the game"
                case .p2WonGame: return "Player 2 won the game"
                case .p1WonRound: return "Player 1 plus 1"
                case .p2WonRound: return "Player 2 plus 1"
                case .tieRound: return "Tied"
                }
            }
        }
    }
}
