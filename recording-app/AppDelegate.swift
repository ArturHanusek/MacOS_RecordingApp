//
//  AppDelegate.swift
//  recording-app-ui
//
//  Created by tongqing on 12/27/24.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    //@IBOutlet var window: NSWindow!
    
    var statusItem: NSStatusItem!
    var directoryName: String? {
        didSet {
            directoryInput?.stringValue = directoryName ?? ""
        }
    }
    var directoryInput: NSTextField?
    var commandListener: CommandListener?
    var listenPort: Int = 8080 {
        didSet {
            commandListener?.setPort(port: listenPort)
            commandListener?.reStart()
        }
    }
    
    // add property to store recording area
    private var recordingRect = CGRect(x: 0, y: 0, width: 200, height: 300)
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        loadRecordingSettings()
        loadMenu()
        NSApplication.shared.hide(nil)
        commandListener = CommandListener(port: listenPort)
    }
    
    private func loadMenu() {
        // create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "🎥" // status item text
        }
        
        // create menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Start Recording", action: #selector(startRecording), keyEquivalent: "S"))
        menu.addItem(NSMenuItem(title: "Stop Recording", action: #selector(stopRecording), keyEquivalent: "E"))
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showRecordingSettings), keyEquivalent: "R"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "Q"))
        statusItem.menu = menu
    }
    
    private func loadRecordingSettings() {
        // load recordingRect from UserDefaults
        let defaults = UserDefaults.standard
        if let savedRect = defaults.dictionary(forKey: "recordingRect") as? [String: CGFloat],
           let x = savedRect["x"],
           let y = savedRect["y"],
           let width = savedRect["width"],
           let height = savedRect["height"] {
            recordingRect = CGRect(x: x, y: y, width: width, height: height)
        }
        if let dirName = defaults.string(forKey: "recordingDir") {
            directoryName = dirName
        }
        if let port = defaults.string(forKey: "listenPort") {
            listenPort = Int(port) ?? 8080
        }
    }
    
    @objc func startRecording() {
        
        let rect = recordingRect // area to record
        // call recording logic
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss" 
        let timestamp = dateFormatter.string(from: Date()) 
        let outputFile = "\(directoryName ?? NSHomeDirectory() + "/Desktop")/\(timestamp).mp4" 
        
        // check if file exists
        if FileManager.default.fileExists(atPath: outputFile) {
            print("Error: file already exists")
            return // exit function
        }
        print("outputFile: \(outputFile)")
        
        do {
            try RecordingApp.shared.start(rect: rect, outputFile: outputFile)
        } catch {
            alert_warning("Error: \(error)")
        }
    }
    
    @objc func stopRecording() {
        // call stop recording logic
        RecordingApp.shared.stop()
    }
    
    @objc func showRecordingSettings() {
        
        let alert = NSAlert()
        alert.messageText = "Settings"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        // inputs
        let xLabel = NSTextField(labelWithString: "x:")
        let xInput = NSTextField(frame: NSRect(x: 80, y: 90, width: 200, height: 24))
        
        let yLabel = NSTextField(labelWithString: "y:")
        let yInput = NSTextField(frame: NSRect(x: 80, y: 60, width: 200, height: 24))
        
        let widthLabel = NSTextField(labelWithString: "width:")
        let widthInput = NSTextField(frame: NSRect(x: 80, y: 30, width: 200, height: 24))
        
        let heightLabel = NSTextField(labelWithString: "height:")
        let heightInput = NSTextField(frame: NSRect(x: 80, y: 0, width: 200, height: 24))
        
        directoryInput = NSTextField(frame: NSRect(x: 10, y: 150, width: 200, height: 24))
        directoryInput!.stringValue = directoryName ?? NSHomeDirectory() + "/Desktop"
        directoryInput!.isEditable = false
        
        let portLabel = NSTextField(labelWithString: "listen port:")
        let portInput = NSTextField(frame: NSRect(x: 80, y: 120, width: 200, height: 24))

        let chooseDirectoryButton = NSButton(title: "dir to save", target: self, action: #selector(chooseDirectory))
        chooseDirectoryButton.frame = NSRect(x: 210, y: 150, width: 90, height: 24)
        
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
        contentView.addSubview(chooseDirectoryButton)
        contentView.addSubview(directoryInput!)
        
        let labelsAndInputs = [(xLabel, xInput), (yLabel, yInput), (widthLabel, widthInput), (heightLabel, heightInput),(portLabel,portInput)]
        for (label, input) in labelsAndInputs {
            label.frame = NSRect(x: 10, y: input.frame.origin.y, width: 70, height: 24)
            input.frame.origin.x = label.frame.origin.x + 80
            contentView.addSubview(label)
            contentView.addSubview(input)
        }
        
        alert.accessoryView = contentView
        
        // use default value to initialize input box
        xInput.stringValue = "\(Int(recordingRect.origin.x))"
        yInput.stringValue = "\(Int(recordingRect.origin.y))"
        widthInput.stringValue = "\(Int(recordingRect.width))"
        heightInput.stringValue = "\(Int(recordingRect.height))"
        portInput.stringValue = "\(listenPort)"
        
        // set dialog size
        //alert.window.setContentSize(NSSize(width: 250, height: 350)) // increase height
        
        // show dialog
        let response = alert.runModal()
        print("Response: \(response)")
        if response == .alertFirstButtonReturn {
            // get user input
            if let x = Int(xInput.stringValue), let y = Int(yInput.stringValue),
               let width = Int(widthInput.stringValue), let height = Int(heightInput.stringValue),
               let port = Int(portInput.stringValue) {
                print("settings")
                self.recordingRect = CGRect(x: x, y: y, width: width, height: height) // update recording area
                self.listenPort = port
                // save recordingRect to UserDefaults
                let defaults = UserDefaults.standard
                let rectDict: [String: CGFloat] = ["x": recordingRect.origin.x,
                                                   "y": recordingRect.origin.y,
                                                   "width": recordingRect.width,
                                                   "height": recordingRect.height]
                defaults.set(rectDict, forKey: "recordingRect")
                defaults.set(self.directoryName, forKey: "recordingDir")
                defaults.set("\(self.listenPort)", forKey: "listenPort")
            } else {
                alert_warning("setting error, please check")
            }
        } else {
            print("User cancelled the operation.")
        }
    }
    
    @objc func chooseDirectory() {
        let dialog = NSOpenPanel()
        dialog.title = "Select Directory"
        dialog.canChooseDirectories = true
        dialog.canChooseFiles = false
        dialog.allowsMultipleSelection = false
        
        if dialog.runModal() == .OK {
            if let result = dialog.url {
                directoryName = result.path // input box to show selected directory
            }
        }
    }
}

func alert_warning(_ message: String) {
    let alert = NSAlert()
    alert.messageText = "Warning"
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: "OK")
    alert.runModal()
}


