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
//    var coordinator: AppCoordinator!
    private var player: AVAudioPlayer?
//    private var throatScan: ThroatScan!
    private let defaultPhotosToTake: Int = 16
    private var numberOfPhotosToTake: Int = 16
    private let defaults = UserDefaults.standard
    private let cameraShutterSoundID: SystemSoundID = 1108 // use 1157 if 1108 is unsavory
    private var trackedItems: [DetectedObjectType] = DetectedObjectType.allObjectTypes
    private var camera: Camera!
    private var visionService: VisionService!
    private let initialInstruction: String = "Hold the camera in front of your throat"
    private let screenArea: CGFloat = UIScreen.main.bounds.width * UIScreen.main.bounds.height
    private var delayTimer: Timer?
    private var willDelay: Bool = false
//    private var currentThroatPart: ThroatPart?
    //private var notification = NotificationCenter.default
    private var mainQueue = OperationQueue.main
    
    var notification: Void = NotificationCenter.default.addObserver(self,
                                           selector: #selector(ObjectDetectionController.handleModalDismissed),
                                           name: NSNotification.Name(rawValue: "modalIsDimissed"),
                                           object: nil)
    
    
    
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
    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.text = initialInstruction
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
//    private lazy var instructionsButton: UIButton = {
//        let normalImage = UIImage(named: "question-mark")?.withTintColor(.white).withRenderingMode(.alwaysOriginal)
//        let button = AppService.createButton(type: .roundedGrayButton(image: normalImage))
//        button.addTarget(self, action: #selector(instructionButtonTapped), for: .touchUpInside)
//        return button
//    }()
//    private lazy var needHelpButton: UIButton = {
//        let normalImage = UIImage(named: "overlay")?.withTintColor(.white).withRenderingMode(.alwaysOriginal)
//        let button = AppService.createButton(type: .roundedGrayButton(image: normalImage))
//        button.addTarget(self, action: #selector(needHelpButtonTapped), for: .touchUpInside)
//        return button
//    }()
//    private lazy var aiButton: UIButton = {
//        let button = AppService.createButton(type: .grayButton(title: "AI: ON"))
//        button.setTitle("AI: OFF", for: .selected)
//        button.addTarget(self, action: #selector(aiButtonTapped), for: .touchUpInside)
//        return button
//    }()
//    private lazy var mirrorButton: UIButton = {
//        let button = AppService.createButton(type: .grayButton(title: "Mirror"))
//        button.addTarget(self, action: #selector(mirrorButtonTapped), for: .touchUpInside)
//        return button
//    }()
//    private lazy var audioFeedbackButton: UIButton = {
//        let normalImage = UIImage(named: "audioOn")?.withTintColor(.white).withRenderingMode(.alwaysOriginal)
//        let button = AppService.createButton(type: .roundedGrayButton(image: normalImage))
//        let selectedImage = UIImage(named: "audioOff")?.withTintColor(.white).withRenderingMode(.alwaysOriginal)
//        button.setImage(selectedImage, for: .selected)
//        button.addTarget(self, action: #selector(audioFeedbackButtonTapped), for: .touchUpInside)
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
        if !defaults.bool(forKey: "DoNotShowPopupAgain") {
//            showPopupInstructions()
        }
        
        
//        notification = NotificationCenter.default.addObserver(self,
//                                               selector: #selector(ObjectDetectionController.handleModalDismissed),
//                                               name: NSNotification.Name(rawValue: "modalIsDimissed"),
//                                               object: nil)

    }
    
    @objc func handleModalDismissed() {
        print("Show label")
        instructionLabel.isHidden = false
//        let visualExample = VisualExample()
//        if visualExample.isModalInPresentation == true{
//            instructionLabel.isHidden = false
//        }else{
//            instructionLabel.isHidden = true
//        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
//        resetThroatScanProperties()
        configureVision()
        configureCamera()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        camera.stop()
        //TODO: make notification's observer stop
        notification = NotificationCenter.default.removeObserver(self)
        
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
        view.addSubview(instructionLabel)
//        instructionLabel.snp.makeConstraints {
//            $0.top.equalTo(view.safeAreaLayoutGuide).offset(10)
//            $0.leading.equalToSuperview().offset(10)
//            $0.trailing.equalToSuperview().offset(-10)
//            $0.height.equalToSuperview().multipliedBy(0.15)
//        }
//        let captureButtonHeight: CGFloat = 75
//        let roundedButtonsWidthHeight: CGFloat = 40
//        let stackView = UIStackView(arrangedSubviews: [audioFeedbackButton, mirrorButton], axis: .horizontal, alignment: .center, distribution: .fill, spacing: 10)
//        view.addSubview(stackView)
//        stackView.snp.makeConstraints {
//            $0.height.equalTo(100)
//        }
//        let bottomRightButtonsStackView = UIStackView(arrangedSubviews: [captureButton, stackView], axis: .horizontal, alignment: .center, distribution: .fillProportionally, spacing: 20)
//        view.addSubview(bottomRightButtonsStackView)
//        bottomRightButtonsStackView.snp.makeConstraints {
//            $0.leading.equalTo(view.safeAreaLayoutGuide.snp.centerX).offset(captureButtonHeight / 2 * -1)
//            $0.trailing.equalToSuperview().offset(-10)
//            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
//            $0.height.equalTo(100)
//        }
//        mirrorButton.snp.makeConstraints {
//            $0.height.equalTo(40)
//            $0.width.equalTo(60)
//        }
//        audioFeedbackButton.snp.makeConstraints {
//            $0.width.height.equalTo(roundedButtonsWidthHeight + 10)
//        }
//        audioFeedbackButton.layer.cornerRadius = (roundedButtonsWidthHeight + 10) / 2
//        captureButton.snp.makeConstraints {
//            $0.height.width.equalTo(captureButtonHeight)
//        }
//        captureButton.layer.cornerRadius = captureButtonHeight / 2
//        enableCaptureButton(false)
//        let bottomLeftButtonsStackView = UIStackView(arrangedSubviews: [instructionsButton, needHelpButton, aiButton], axis: .vertical, alignment: .leading, distribution: .equalSpacing, spacing: 24)
//        view.addSubview(bottomLeftButtonsStackView)
//        bottomLeftButtonsStackView.snp.makeConstraints {
//            $0.leading.equalTo(view.safeAreaLayoutGuide).offset(10)
//            $0.bottom.equalTo(mirrorButton.snp.bottom)
//        }
//        instructionsButton.snp.makeConstraints {
//            $0.width.height.equalTo(roundedButtonsWidthHeight)
//        }
//        instructionsButton.layer.cornerRadius = roundedButtonsWidthHeight / 2
//        needHelpButton.snp.makeConstraints{
//            $0.width.height.equalTo(roundedButtonsWidthHeight)
//        }
//        needHelpButton.layer.cornerRadius = roundedButtonsWidthHeight / 2
//        aiButton.snp.makeConstraints {
//            $0.height.equalTo(40)
//            $0.width.equalTo(80)
//        }
    }
    
    fileprivate func setupBackground() {
        view.backgroundColor = .systemBackground
//        coordinator.hideNavigationBar()
    }
    
//    fileprivate func showPopupInstructions() {
//        let popup = InstructionsPopupController()
//        addChild(popup)
//        popup.view.frame = view.frame
//        view.addSubview(popup.view)
//        popup.didMove(toParent: self)
//        if defaults.bool(forKey: "DoNotShowPopupAgain") {
//            popup.checkBoxButton.backgroundColor = .darkGray
//            popup.status = true
//        } else {
//            popup.checkBoxButton.backgroundColor = .clear
//            popup.status = false
//        }
//    }
    
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
    
//    fileprivate func resetThroatScanProperties() {
//        throatScan = ThroatScan()
//        enableCaptureButton(false)
//        instructionLabel.text = initialInstruction
//        numberOfPhotosToTake = defaultPhotosToTake
//        aiButton.isSelected = false
//        visionService = VisionService(with: previewView, trackedItems: trackedItems, delegate: self)
//        //TODO: reinitialize the notification
//        notification = NotificationCenter.default.addObserver(self,
//                                                               selector: #selector(ObjectDetectionController.handleModalDismissed),
//                                                               name: NSNotification.Name(rawValue: "modalIsDimissed"),
//                                                               object: nil)
//    }
    
//    fileprivate func goToNextController() {
//        stopActivityIndicator()
//        coordinator.goToPhotosController(throatScan: throatScan)
//    }
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
//        throatScan.isManuallyCaptured = true
        enableCaptureButton(false)
        numberOfPhotosToTake = 16
        instructionLabel.text = "Hold the phone still"
//        startActivityIndicator(type: .ballGridPulse)
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
    
//    @objc func mirrorButtonTapped() {
//        instructionLabel.flipX()
//        mirrorButton.flipX()
//        audioFeedbackButton.flipX()
//        aiButton.flipX()
//        previewView.flipX()
//    }
    
//    @objc func instructionButtonTapped() {
//        showPopupInstructions()
//    }
//
//    @objc func needHelpButtonTapped() {
//        let needHelpPopup = VisualExample()
//        let navPopup = UINavigationController(rootViewController: needHelpPopup)
//        present(navPopup, animated: true)
//        instructionLabel.isHidden = true
//    }
//
//    @objc func audioFeedbackButtonTapped() {
//        audioFeedbackButton.isSelected = !audioFeedbackButton.isSelected
//    }
//
//    @objc func aiButtonTapped() {
//        aiButton.isSelected = !aiButton.isSelected
//        if aiButton.isSelected {
//            visionService = nil
//            enableCaptureButton(true)
//        } else {
//            visionService = VisionService(with: previewView, trackedItems: trackedItems, delegate: self)
//            enableCaptureButton(false)
//        }
//    }
}

// MARK: - Camera Setup
private extension ObjectDetectionController {
    func configureVision() {
        //must reinitialize or camera preview will be frozen
        constraintCameraPreview()
        visionService = VisionService(with: previewView, trackedItems: trackedItems, delegate: self)
    }
    
    private func constraintCameraPreview() {
        previewView = CameraPreview()
        previewView.removeMasks()
        view.addSubview(previewView)
        previewView.translatesAutoresizingMaskIntoConstraints = false
        let horizontalConstraint = previewView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        let verticalConstraint = previewView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        let widthConstraint = previewView.widthAnchor.constraint(equalToConstant: view.frame.width)
        let heightConstraint = previewView.heightAnchor.constraint(equalToConstant: view.frame.height)
        NSLayoutConstraint.activate([horizontalConstraint, verticalConstraint, widthConstraint, heightConstraint])
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
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
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
            //if no error, then get the image and append to throatScanImages
            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            let imageOrientation = UIImage.Orientation.up
            let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: imageOrientation)
            print("Got the image output")
//            if throatScan.isManuallyCaptured {
//                let unknownThroatPart = UnknownThroatPart(image: image.withOriginalOrientation())
//                throatScan.unknownThroatParts.append(unknownThroatPart)
//                if throatScan.unknownThroatParts.count == numberOfPhotosToTake {
////                    goToNextController()
//                }
//            } else { //AI captured image
//                appendImageToThroatPart(image: image.withOriginalOrientation())
//                updateInstructionLabel(type: throatScan.searchingType)
//                if throatScan.tonsils.count == throatScan.maxTonsilParts {
////                    goToNextController()
//                }
//            }
        } else {
            presentAlert(title: "Image Error", message: "Failed to get an image")
        }
    }
    
//    private func appendImageToThroatPart(image: UIImage) {
//        guard var throatPart = currentThroatPart else { return }
//        throatPart.updateImage(image: image)
//        throatScan.appendPart(throatPart: throatPart)
//    }
    
//    private func updateInstructionLabel(type: DetectedObjectType) {
//        switch type {
//        case .pharynx:
//            instructionLabel.text = "Looking for your pharynx"
//        case .uvula:
//            instructionLabel.text = "Looking for your uvula"
//        case .tonsil:
//            instructionLabel.text = "Looking for your tonsil"
//        case .tongue:
//            instructionLabel.text = "Looking for your tongue"
//        default: break
//        }
//    }
}

//MARK: Pharynx Guide
extension ObjectDetectionController: ThroatPartScannerProtocol {
    func updateThroatParts(newThroatParts: [ThroatPart]) {
        //search for uvula first if we still need more uvula and found uvula
        if willDelay {
            print("Wait")
            return
        }
        willDelay = true
        let scanResult = getScanResult(newThroatParts: newThroatParts)
        switch scanResult {
        case .success(let throatPart):
            print("Successfully found a part \(throatPart)")
//            currentThroatPart = throatPart
            player?.stop()
            updateCameraFocusPoint(throatPart: throatPart)
//            camera.takePhoto()
            delayTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateDelayTimer), userInfo: nil, repeats: true)
        case .error(let message):
            print("Error message \(message)")
            willDelay = false
        case .noTongue(let toungeTooLarge),
             .noTonsil(let toungeTooLarge),
             .noUvula(let toungeTooLarge),
             .noPharynx(let toungeTooLarge),
             .pharynxTooSmall(let toungeTooLarge):
//            if !audioFeedbackButton.isSelected {
//                if toungeTooLarge {
//                    giveCommand(.sayAh)
//                    print("say ah")
//                } else {
//                    giveCommand(.tongueDown)
//                    print("tongue down")
//                }
//            }
            willDelay = false
        }
    }
    
    @objc func updateDelayTimer() {
        print("done waiting")
//        currentThroatPart = nil
        delayTimer?.invalidate()
        willDelay = false
    }
    
    //MARK: ThroatPartScanner Helpers
    
    private func getScanResult(newThroatParts: [ThroatPart]) -> ScanResultType {
        guard let optionalPart: ThroatPart = newThroatParts.first else {
            return .error(message: "no part from new throat parts")
        }
        return .success(throatPart: optionalPart)
//        return .error(message: "Error not implemented yet")
//        //get tounge area
//        var toungeArea: CGFloat = 0
//        if let tounge = newThroatParts.first(where: {$0.type == .tongue}) {
//            toungeArea = tounge.location.width * tounge.location.height
//        }// else { print("No tounge while searching for \(throatParts.searchingType.rawValue)") }
//        let isToungeTooLarge: Bool = toungeArea / screenArea > 0.55
//        //check if throat part we are searching for exist
//        let optionalPart: ThroatPart? = newThroatParts.first { $0.type == throatScan.searchingType }
//        guard let throatPart = optionalPart else {
//            //if throatPart does not exist, return which part we couldn't find and if tounge is too large
//            switch throatScan.searchingType {
//            case .tongue: return .noTongue(tongueTooLarge: isToungeTooLarge)
//            case .tonsil: return .noTonsil(tongueTooLarge: isToungeTooLarge)
//            case .uvula: return .noUvula(tongueTooLarge: isToungeTooLarge)
//            case .pharynx: return .noPharynx(tongueTooLarge: isToungeTooLarge)
//            default: return .error(message: "Part not found and unknown type")
//            }
//        }
//        //check if part we are searching for satisfies our threshold
//        switch throatScan.searchingType {
//        case .tongue:
//            break
//        case .tonsil:
//            break
//        case .uvula:
//            break
//        case .pharynx:
//            let minimumAreaThreshold: CGFloat = 0.12
//            let partArea: CGFloat = throatPart.location.height * throatPart.location.width
//            let isPharynxTooSmall = screenArea / partArea <= minimumAreaThreshold
//            if isPharynxTooSmall {
//                print("Pharynx too small \(partArea) out of \(screenArea)")
//                return .pharynxTooSmall(tongueTooLarge: isToungeTooLarge)
//            } else {
//                print("Success Pharynx is big enough \(partArea) out of \(screenArea)")
//            }
//        default:
//            print("Error! Unsupported part type \(throatPart.type.rawValue)")
//            return .error(message: "Unsupported part")
//        }
//        return .success(throatPart: throatPart)
    }
    
    ///updates the camera's focus point at the throatPart's mid point location
    private func updateCameraFocusPoint(throatPart: ThroatPart) {
        let midPoint = CGPoint(x: throatPart.location.midX, y: throatPart.location.midY)
        camera.updateCameraFocusPoint(midPoint: midPoint)
    }
}

enum ScanResultType {
    case success(throatPart: ThroatPart),
         error(message: String),
         noTongue(tongueTooLarge: Bool),
         noTonsil(tongueTooLarge: Bool),
         noUvula(tongueTooLarge: Bool),
         noPharynx(tongueTooLarge: Bool),
         pharynxTooSmall(tongueTooLarge: Bool)
}

//MARK: Audio Player
extension ObjectDetectionController {
//    func giveCommand(_ command: VoiceCommand) {
//        guard let path = Bundle.main.path(forResource: command.localURL, ofType: "m4a") else {
//            print("no audio file found")
//            return }
//        let url = URL(fileURLWithPath: path)
//        instructionLabel.text = "\(command.rawValue)"
//        if let player = player, player.isPlaying { return }
//        do {
//            player = try AVAudioPlayer(contentsOf: url)
//            player?.play()
//        } catch {
//            print("Error playing audio \(error.localizedDescription)")
//        }
//    }
}

//MARK: AVAudioPlayerDelegate
extension ObjectDetectionController: AVAudioPlayerDelegate {
//    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
//        if flag {
//
//        }
//    }
}
