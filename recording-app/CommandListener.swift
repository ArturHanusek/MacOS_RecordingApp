import Foundation
import Network

class CommandListener {
    private var listener: NWListener?
    private var port = 8080
    
    init(port: Int) {
        self.port = port
        startServer()
    }
    
    func setPort(port: Int) {
        self.port = port
    }
    
    func reStart() {
        listener?.cancel()
        startServer()
    }

    private func startServer() {
        do {
            listener = try NWListener(using: .tcp, on: NWEndpoint.Port("\(port)") ?? 8080)
            listener?.newConnectionHandler = { connection in
                connection.start(queue: .main)
                self.receive(on: connection)
            }
            listener?.start(queue: .main)
            print("server started, listening on port \(port)")
        } catch {
            alert_warning("startServer error: \(error)")
        }
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { (data, context, isComplete, error) in
            if let data = data, let command = String(data: data, encoding: .utf8) {
                self.handleCommand(command.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            if isComplete {
                connection.cancel()
            } else {
                self.receive(on: connection) 
            }
        }
    }

    private func handleCommand(_ command: String) {
        let components = command.split(separator: " ")
        guard let action = components.first else { return }
        
        switch action {
        case "start":
            
            var rect: CGRect?
            var outputFile: String?
    
            for i in 2..<components.count {
                let arg = components[i]
                if arg.hasPrefix("-rect=") {
                    let rectString = String(arg.dropFirst(6))
                    rect = parseRect(rectString)
                } else if arg.hasPrefix("-file=") {
                    outputFile = String(arg.dropFirst(6))
                }
            }
    
            guard let rect = rect, let outputFile = outputFile else {
                alert_warning("Invalid command from network: \(command)")
                return
            }
    
            do {
                try RecordingApp.shared.start(rect: rect, outputFile: outputFile)
            } catch {
                alert_warning("Error starting recording: \(error)")
            }
        case "stop":
            // stop recording
            RecordingApp.shared.stop()
        default:
            alert_warning("unknown command: \(command)")
        }
    }

    // get rect params from command inpupt
    func parseRect(_ rectString: String) -> CGRect? {
        let components = rectString.split(separator: ":", maxSplits: 4, omittingEmptySubsequences: true)
        guard components.count == 4,
            let x = Double(components[0]),
            let y = Double(components[1]),
            let width = Double(components[2]),
              let height = Double(components[3]) else {
            return nil
        }
        return CGRect(x: x, y: y, width: width, height: height)
    }
} 
