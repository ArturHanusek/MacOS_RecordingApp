//
//  RecordingApp.swift
//  recording-app
//
//  Created by tongqing on 12/26/24.
//

import Foundation
import AVFoundation
import AppKit

class RecordingApp {
    
    private var isRecording = false
    private var recorder: ScreenRecorder?
    
    static let shared = RecordingApp()
    
    func start(rect: CGRect, outputFile: String) throws {
        
        guard !isRecording else {
            alert_warning("Recording is already in progress")
            return
        }
        
        // check Permission
        checkPermissionsGUI { result in
            switch result {
            case .success:
                print("Permission granted")
            case .failure(let error):
                //alert_warning("Permission denied: \(error), please grant permissions for screen capture.")
                // open security setting
                self.openScreenRecordingSettings()
                return
            }
        }
        
        // record
        recorder = try ScreenRecorder(rect: rect, outputURL: URL(fileURLWithPath: outputFile))
        
        // start record
        try recorder?.start()
        isRecording = true
        print("Recording started")
    }
    
    
    func stop() {
        guard isRecording else {
            alert_warning("No active recording")
            return
        }
        
        recorder?.stop()
        isRecording = false
        print("Recording stopped")
    }
    
    
    
    private func checkPermissionsGUI(completion: @escaping (Result<Void, RecordingError>) -> Void) {
        // check screen recording permission
        let screenAuth = CGPreflightScreenCaptureAccess()
        if !screenAuth {
            CGRequestScreenCaptureAccess()
            // add a user interface prompt to inform the user that they need to authorize
            DispatchQueue.main.async {
                // for example: show an alert to request user authorization
                // showAlertForScreenCaptureAccess { granted in
                if !CGPreflightScreenCaptureAccess() {
                     completion(.failure(.screenCapturePermissionDenied))
                }
            }
            return
        }
        
        // audio recording permission
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .notDetermined:
                DispatchQueue.main.async {
                    AVCaptureDevice.requestAccess(for: .audio) { granted in
                        if !granted {
                            completion(.failure(.audioPermissionDenied))
                        } else {
                            completion(.success(()))
                        }
                    }
                }
                    
            case .restricted, .denied:
                completion(.failure(.audioPermissionDenied))
                
            case .authorized:
                completion(.success(()))
                
            @unknown default:
                completion(.failure(.audioPermissionDenied))
        }
    }
    
    private func openScreenRecordingSettings() {
        // open screen recording settings
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenRecording") {
            //NSWorkspace.shared.open(url)
        }
    }
}

enum RecordingError: Error {
    case screenCapturePermissionDenied
    case audioPermissionDenied
    case invalidArguments
    case recordingFailed
}

