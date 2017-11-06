//
//  ViewController.swift
//  Vision-app-dev
//
//  Created by Jacob Ahlberg on 2017-11-03.
//  Copyright © 2017 Jacob Ahlberg. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

enum FlashState {
    case off
    case on
}

class CameraVC: UIViewController {
    
    var capturedSession: AVCaptureSession!
    var cameraOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var photoData: Data?
    
    var flashControllState: FlashState = .off
    
    var speechSynthesizer = AVSpeechSynthesizer()

    @IBOutlet weak var capturedImageView: RoundedShadowImageView!
    @IBOutlet weak var flashBtn: RoundedShadowButton!
    @IBOutlet weak var identificationLbl: UILabel!
    @IBOutlet weak var confidenceLbl: UILabel!
    @IBOutlet weak var roundedLblView: RoundedShadowView!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.spinner.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer.frame = cameraView.bounds
        speechSynthesizer.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCameraView))
        tap.numberOfTapsRequired = 1
        
        capturedSession = AVCaptureSession()
        capturedSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera!)
            if capturedSession.canAddInput(input) == true {
                capturedSession.addInput(input)
            }
            
            cameraOutput = AVCapturePhotoOutput()
            
            if capturedSession.canAddOutput(cameraOutput) == true {
                capturedSession.addOutput(cameraOutput!)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: capturedSession!)
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                
                cameraView.layer.addSublayer(previewLayer!)
                cameraView.addGestureRecognizer(tap)
                capturedSession.startRunning()
                
            }
            
        } catch {
            debugPrint("Error: \(error.localizedDescription)")
        }
    }
    
    @objc func didTapCameraView() {
        self.cameraView.isUserInteractionEnabled = false
        self.spinner.isHidden = false
        self.spinner.startAnimating()
        
        let settings = AVCapturePhotoSettings()
        
        settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
        
        if flashControllState == .off {
            settings.flashMode = .off
        } else {
            settings.flashMode = .on
        }
        
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func resultsMethod(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation] else { return }
        
        for classification in results {
            if classification.confidence < 0.5 {
                let unkownObjectMessage = "I'm not sure what this is. Please try again"
                self.identificationLbl.text = unkownObjectMessage
                synthesizeSpeech(fromString: unkownObjectMessage)
                self.confidenceLbl.text = ""
                break
            } else {
                let identification = classification.identifier
                let confidence = Int(classification.confidence * 100)
                self.identificationLbl.text = classification.identifier
                self.confidenceLbl.text = "CONFIDENCE: \(confidence)%"
                
                let completeSentence = "This looks like a \(identification). I am \(confidence) percent sure."
                synthesizeSpeech(fromString: completeSentence)
                break
            }
        }
    }
    
    @IBAction func flashBtnWasPressed(_ sender: Any) {
        switch flashControllState {
        case .off:
            flashBtn.setTitle("FLASH ON", for: .normal)
            flashControllState = .on
        case .on:
            flashBtn.setTitle("FLASH OFF", for: .normal)
            flashControllState = .off
        }
    }
    
    func synthesizeSpeech(fromString string: String ) {
        let speechUtterence = AVSpeechUtterance(string: string)
        speechUtterence.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(speechUtterence)
        
    }
    
    
}

extension CameraVC: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            debugPrint(error)
        } else {
            photoData = photo.fileDataRepresentation()
            
            do {
                let model = try VNCoreMLModel(for: SqueezeNet().model)
                let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
                let handler = VNImageRequestHandler(data: photoData!)
                try handler.perform([request])
            } catch {
                debugPrint(error.localizedDescription)
            }
            
            let image = UIImage(data: photoData!)
            self.capturedImageView.image = image
        }
    }
}

extension CameraVC: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.cameraView.isUserInteractionEnabled = true
        self.spinner.isHidden = true
        self.spinner.stopAnimating()
    }
    
}






