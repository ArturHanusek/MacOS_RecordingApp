//
//  RecordingApp.swift
//  recording-app
//
//  Created by tongqing on 12/26/24.
//

import Foundation
import AVFoundation
import AppKit

class ScreenRecorder: NSObject {
    private var captureSession: AVCaptureSession?
    private var screenInput: AVCaptureScreenInput?
    private var movieOutput: AVCaptureMovieFileOutput?
    private var rect: CGRect
    private var outputURL: URL
    
    init(rect: CGRect, outputURL: URL) throws {
        self.rect = rect
        self.outputURL = outputURL
    }

    func start() throws {
        captureSession = AVCaptureSession()
        screenInput = AVCaptureScreenInput()
        
        screenInput?.cropRect = rect
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let flippedRect = CGRect(
            x: rect.origin.x,
            y: screenHeight - (rect.origin.y + rect.height),
            width: rect.width,
            height: rect.height
            )
        screenInput?.cropRect = flippedRect
        
        // add screen input to capture session
        if captureSession!.canAddInput(screenInput!) {
            captureSession!.addInput(screenInput!)
        } else {
            alert_warning("failed to add screenInput")
            throw RecordingError.recordingFailed
        }
        
        // add audio input to capture session
        let audioDevice = AVCaptureDevice.default(for: .audio)
        guard let audioInput = try? AVCaptureDeviceInput(device: audioDevice!) else {
            alert_warning("failed to get audio Input")
            throw RecordingError.recordingFailed
        }
        if captureSession!.canAddInput(audioInput) {
            captureSession!.addInput(audioInput)
        } else {
            alert_warning("failed to add audio Input")
            throw RecordingError.recordingFailed
        }
        
        // create and add output
        movieOutput = AVCaptureMovieFileOutput()
        if captureSession!.canAddOutput(movieOutput!) {
            captureSession!.addOutput(movieOutput!)
        } else {
            alert_warning("failed to output to movieput")
            throw RecordingError.recordingFailed
        }
        
        // start capture session
        captureSession!.startRunning()

        // start recording
        movieOutput!.startRecording(to: outputURL, recordingDelegate: self)
    }

    func stop() {
        movieOutput?.stopRecording()
        captureSession?.stopRunning()
    }
}

// implement AVCaptureFileOutputRecordingDelegate
extension ScreenRecorder: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording: \(error)")
        } else {
            print("Recording finished successfully")
        }
    }
}
