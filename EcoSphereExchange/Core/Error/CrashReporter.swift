import Foundation

final class CrashReporter {
    static let shared = CrashReporter()
    
    private let queue = DispatchQueue(label: "crash.reporter", qos: .utility)
    private let logger = SecurityLogger.shared
    private let analyticsManager = AnalyticsManager.shared
    
    private var crashLogs: [CrashLog] = []
    private let maxStoredCrashLogs = 100
    
    private init() {
        loadStoredCrashLogs()
        setupCrashHandling()
    }
    
    // MARK: - Public Methods
    
    func report(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Create crash log
            let crashLog = self.createCrashLog(
                error: error,
                file: file,
                function: function,
                line: line
            )
            
            // Store crash log
            self.storeCrashLog(crashLog)
            
            // Log crash
            self.logger.logError(error, file: file, function: function, line: line)
            
            // Track analytics
            self.analyticsManager.trackEvent(.crash(error: error, log: crashLog))
            
            // Submit crash report
            self.submitCrashReport(crashLog)
        }
    }
    
    func getCrashLogs() -> [CrashLog] {
        var logs: [CrashLog] = []
        queue.sync {
            logs = crashLogs
        }
        return logs
    }
    
    func clearCrashLogs() {
        queue.async { [weak self] in
            self?.crashLogs.removeAll()
            self?.saveCrashLogs()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupCrashHandling() {
        // Register signal handler
        signal(SIGSEGV) { signal in
            CrashReporter.shared.handleSignal(signal)
        }
        
        signal(SIGABRT) { signal in
            CrashReporter.shared.handleSignal(signal)
        }
        
        signal(SIGILL) { signal in
            CrashReporter.shared.handleSignal(signal)
        }
        
        signal(SIGTRAP) { signal in
            CrashReporter.shared.handleSignal(signal)
        }
        
        // Set up uncaught exception handler
        NSSetUncaughtExceptionHandler { exception in
            CrashReporter.shared.handleException(exception)
        }
    }
    
    private func handleSignal(_ signal: Int32) {
        let signalName = String(describing: signal)
        let error = CrashError.signal(code: signal)
        
        report(error)
    }
    
    private func handleException(_ exception: NSException) {
        let error = CrashError.exception(
            name: exception.name,
            reason: exception.reason ?? "Unknown reason",
            callStack: exception.callStackSymbols
        )
        
        report(error)
    }
    
    private func createCrashLog(
        error: Error,
        file: String,
        function: String,
        line: Int
    ) -> CrashLog {
        CrashLog(
            timestamp: Date(),
            error: error,
            type: String(describing: type(of: error)),
            message: error.localizedDescription,
            file: file,
            function: function,
            line: line,
            deviceInfo: DeviceInfo.current,
            appInfo: AppInfo.current,
            memoryUsage: PerformanceOptimizer.shared.currentMemoryUsage(),
            cpuUsage: PerformanceOptimizer.shared.currentCPUUsage(),
            diskSpace: ProcessorInformation.availableDiskSpace(),
            networkStatus: NetworkMonitor.shared.isConnected
        )
    }
    
    private func storeCrashLog(_ log: CrashLog) {
        crashLogs.append(log)
        
        // Keep only the most recent logs
        if crashLogs.count > maxStoredCrashLogs {
            crashLogs.removeFirst()
        }
        
        saveCrashLogs()
    }
    
    private func loadStoredCrashLogs() {
        queue.async { [weak self] in
            guard let crashLogsURL = self?.crashLogsURL else { return }
            
            do {
                let data = try Data(contentsOf: crashLogsURL)
                let logs = try JSONDecoder().decode([CrashLog].self, from: data)
                self?.crashLogs = logs
            } catch {
                self?.logger.logError(error)
            }
        }
    }
    
    private func saveCrashLogs() {
        queue.async { [weak self] in
            guard let self = self,
                  let crashLogsURL = self.crashLogsURL else { return }
            
            do {
                let data = try JSONEncoder().encode(self.crashLogs)
                try data.write(to: crashLogsURL)
            } catch {
                self.logger.logError(error)
            }
        }
    }
    
    private func submitCrashReport(_ log: CrashLog) {
        // Submit crash report to backend service
        Task {
            do {
                try await APIService.shared.post(
                    endpoint: .crashReport,
                    body: log
                )
            } catch {
                logger.logError(error)
            }
        }
    }
    
    private var crashLogsURL: URL? {
        try? FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("crash_logs.json")
    }
}

// MARK: - Supporting Types

struct CrashLog: Codable {
    let timestamp: Date
    let error: Error
    let type: String
    let message: String
    let file: String
    let function: String
    let line: Int
    let deviceInfo: DeviceInfo
    let appInfo: AppInfo
    let memoryUsage: Double
    let cpuUsage: Double
    let diskSpace: Int64
    let networkStatus: Bool
    
    private enum CodingKeys: String, CodingKey {
        case timestamp
        case type
        case message
        case file
        case function
        case line
        case deviceInfo
        case appInfo
        case memoryUsage
        case cpuUsage
        case diskSpace
        case networkStatus
    }
    
    init(
        timestamp: Date,
        error: Error,
        type: String,
        message: String,
        file: String,
        function: String,
        line: Int,
        deviceInfo: DeviceInfo,
        appInfo: AppInfo,
        memoryUsage: Double,
        cpuUsage: Double,
        diskSpace: Int64,
        networkStatus: Bool
    ) {
        self.timestamp = timestamp
        self.error = error
        self.type = type
        self.message = message
        self.file = file
        self.function = function
        self.line = line
        self.deviceInfo = deviceInfo
        self.appInfo = appInfo
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
        self.diskSpace = diskSpace
        self.networkStatus = networkStatus
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        error = NSError(domain: "", code: 0, userInfo: nil) // Placeholder as Error can't be decoded
        type = try container.decode(String.self, forKey: .type)
        message = try container.decode(String.self, forKey: .message)
        file = try container.decode(String.self, forKey: .file)
        function = try container.decode(String.self, forKey: .function)
        line = try container.decode(Int.self, forKey: .line)
        deviceInfo = try container.decode(DeviceInfo.self, forKey: .deviceInfo)
        appInfo = try container.decode(AppInfo.self, forKey: .appInfo)
        memoryUsage = try container.decode(Double.self, forKey: .memoryUsage)
        cpuUsage = try container.decode(Double.self, forKey: .cpuUsage)
        diskSpace = try container.decode(Int64.self, forKey: .diskSpace)
        networkStatus = try container.decode(Bool.self, forKey: .networkStatus)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(type, forKey: .type)
        try container.encode(message, forKey: .message)
        try container.encode(file, forKey: .file)
        try container.encode(function, forKey: .function)
        try container.encode(line, forKey: .line)
        try container.encode(deviceInfo, forKey: .deviceInfo)
        try container.encode(appInfo, forKey: .appInfo)
        try container.encode(memoryUsage, forKey: .memoryUsage)
        try container.encode(cpuUsage, forKey: .cpuUsage)
        try container.encode(diskSpace, forKey: .diskSpace)
        try container.encode(networkStatus, forKey: .networkStatus)
    }
}

enum CrashError: Error {
    case signal(code: Int32)
    case exception(name: NSExceptionName, reason: String, callStack: [String])
}