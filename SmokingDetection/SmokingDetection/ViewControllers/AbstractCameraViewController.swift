//
//  AbstractCameraViewController.swift
//  SmokingDetection
//
//  Created by Dmitriy Permyakov on 20.05.2024.
//  Copyright 2024 © https://github.com/mightyK1ngRichard. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class AbstractCameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    // MARK: Public Properties

    var bufferSize: CGSize = .zero
    var rootLayer: CALayer! = nil

    // MARK: Private Properties

    private var previewView = UIView()
    private var previewLayer: AVCaptureVideoPreviewLayer! = nil
    private let session = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(
        label: "com.bmstu.VideoDataOutput",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem
    )

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    // MARK: Public Methods

    func setupAVCapture() {
        let deviceInput: AVCaptureDeviceInput

        // Select a video device, make an input
        let videoDevice = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        ).devices.first
        do {
            deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        } catch {
            Logger.log(.error, message: error.localizedDescription)
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .vga640x480

        // Add a video input
        guard session.canAddInput(deviceInput) else {
            Logger.log(.error, message: "Could not add video device input to the session")
            session.commitConfiguration()
            return
        }
        session.addInput(deviceInput)

        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            // Add a video data output
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            Logger.log(.error, message: "Could not add video data output to the session")
            session.commitConfiguration()
            return
        }
        let captureConnection = videoDataOutput.connection(with: .video)
        // Always process the frames
        captureConnection?.isEnabled = true
        do {
            try videoDevice!.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            videoDevice!.unlockForConfiguration()
        } catch {
            print(error)
        }
        session.commitConfiguration()
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        rootLayer = previewView.layer
        previewLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(previewLayer)
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Код должен быть переопределён...
    }
}

// MARK: - Setup

extension AbstractCameraViewController {

    func setup() {
        setupLayer()
        setupAVCapture()
    }

    func setupLayer() {
        view.addSubview(previewView)
        previewView.frame = view.bounds
    }

    func startCaptureSession() {
        session.startRunning()
    }

    // Clean up capture setup
    func teardownAVCapture() {
        previewLayer.removeFromSuperlayer()
        previewLayer = nil
    }

    func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation

        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:
            exifOrientation = .down
        case UIDeviceOrientation.portrait:
            exifOrientation = .up
        default:
            exifOrientation = .up
        }

        return exifOrientation
    }
}
