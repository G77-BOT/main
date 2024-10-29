import Foundation
import OSLog

final class SecurityLogger {
    static let shared = SecurityLogger()
    
    private let logger: Logger
    private let queue = DispatchQueue(label: "security.logger", qos: .utility)
    private let fileManager = FileManager.default
    private let dateFormatter = ISO8601DateFormatter()
    
    private var logFile: URL? {
        try? FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("security_logs")
         .appendingPathComponent("log_\(currentLogDate()).txt")
    }
    
    private init() {
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.ecosphere", category: "security")
        setupLogDirectory()
    }
    
    // MARK: - Public Methods
    
    func logError(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        let message = """
        Error: \(error.localizedDescription)
        File: \(file)
        Function: \(function)
        Line: \(line)
        """
        
        log(.error, message: message)
    }
    
    func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let formattedMessage = """
        Warning: \(message)
        File: \(file)
        Function: \(function)
        Line: \(line)
        """
        
        log(.warning, message: formattedMessage)
    }
    
    func logInfo(_ message: String) {
        log(.info, message: message)
    }
    
    func logDebug(_ message: String) {
        #if DEBUG
        log(.debug, message: message)
        #endif
    }
    
    func exportLogs() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: LoggerError.instanceDeallocated)
                    return
                }
                
                do {
                    let exportURL = try self.createExportFile()
                    continuation.resume(returning: exportURL)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func clearOldLogs() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let calendar = Calendar.current
            guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) else { return }
            
            do {
                let logsDirectory = try self.logsDirectoryURL()
                let contents = try self.fileManager.contentsOfDirectory(
                    at: logsDirectory,
                    includingPropertiesForKeys: [.creationDateKey],
                    options: []
                )
                
                for url in contents {
                    guard let attributes = try? self.fileManager.attributesOfItem(atPath: url.path),
                          let creationDate = attributes[.creationDate] as? Date,
                          creationDate < thirtyDaysAgo else {
                        continue
                    }
                    
                    try? self.fileManager.removeItem(at: url)
                }
            } catch {
                self.logError(error)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func log(_ level: OSLogType, message: String) {
        queue.async { [weak self] in
            let timestamp = self?.dateFormatter.string(from: Date()) ?? ""
            let logMessage = "[\(timestamp)] \(message)"
            
            // Log to system
            self?.logger.log(level: level, "\(logMessage)")
            
            // Log to file
            self?.writeToFile(logMessage)
            
            // If error, also log to crash reporter
            if level == .error {
                CrashReporter.shared.record(error: message)
            }
        }
    }
    
    private func writeToFile(_ message: String) {
        guard let logFile = logFile else { return }
        
        do {
            if !fileManager.fileExists(atPath: logFile.path) {
                try createLogFile(at: logFile)
            }
            
            let formattedMessage = message + "\n"
            if let data = formattedMessage.data(using: .utf8) {
                let fileHandle = try FileHandle(forWritingTo: logFile)
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } catch {
            logger.error("Failed to write to log file: \(error.localizedDescription)")
        }
    }
    
    private func setupLogDirectory() {
        do {
            let logsDirectory = try logsDirectoryURL()
            if !fileManager.fileExists(atPath: logsDirectory.path) {
                try fileManager.createDirectory(
                    at: logsDirectory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }
        } catch {
            logger.error("Failed to create logs directory: \(error.localizedDescription)")
        }
    }
    
    private func createLogFile(at url: URL) throws {
        let header = "=== Security Log File ===\nCreated: \(dateFormatter.string(from: Date()))\n\n"
        try header.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func currentLogDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func logsDirectoryURL() throws -> URL {
        try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("security_logs")
    }
    
    private func createExportFile() throws -> URL {
        let exportURL = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("security_logs_export_\(dateFormatter.string(from: Date())).txt")
        
        let logsDirectory = try logsDirectoryURL()
        let logFiles = try fileManager.contentsOfDirectory(
            at: logsDirectory,
            includingPropertiesForKeys: nil
        )
        
        var combinedLogs = ""
        for logFile in logFiles {
            if let contents = try? String(contentsOf: logFile, encoding: .utf8) {
                combinedLogs += "=== \(logFile.lastPathComponent) ===\n\n"
                combinedLogs += contents
                combinedLogs += "\n\n"
            }
        }
        
        try combinedLogs.write(to: exportURL, atomically: true, encoding: .utf8)
        return exportURL
    }
}

// MARK: - Supporting Types

enum LoggerError: LocalizedError {
    case instanceDeallocated
    case exportFailed
    
    var errorDescription: String? {
        switch self {
        case .instanceDeallocated:
            return "Logger instance was deallocated"
        case .exportFailed:
            return "Failed to export logs"
        }
    }
}