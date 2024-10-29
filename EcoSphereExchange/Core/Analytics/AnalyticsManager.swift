import Foundation

final class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private let eventQueue = DispatchQueue(label: "analytics.queue", qos: .utility)
    private let persistentCache = PersistentCache.shared
    private let networkMonitor = NetworkMonitor.shared
    private let maxBatchSize = 100
    private let batchUploadInterval: TimeInterval = 60 // 1 minute
    
    private var events: [AnalyticsEvent] = []
    private var batchUploadTimer: Timer?
    
    private init() {
        setupBatchUpload()
        loadCachedEvents()
    }
    
    func trackEvent(_ event: AnalyticsEvent) {
        eventQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Add event to queue
            self.events.append(event)
            
            // Save to persistent cache
            self.saveEventsToPersistentCache()
            
            // If we've reached max batch size, trigger upload
            if self.events.count >= self.maxBatchSize {
                self.uploadEvents()
            }
        }
    }
    
    func trackScreenView(_ screenName: String, parameters: [String: Any]? = nil) {
        let event = AnalyticsEvent.screenView(
            screenName: screenName,
            timestamp: Date(),
            parameters: parameters
        )
        trackEvent(event)
    }
    
    func trackUserAction(_ action: String, parameters: [String: Any]? = nil) {
        let event = AnalyticsEvent.userAction(
            action: action,
            timestamp: Date(),
            parameters: parameters
        )
        trackEvent(event)
    }
    
    func trackError(_ error: Error, parameters: [String: Any]? = nil) {
        let event = AnalyticsEvent.error(
            error: error,
            timestamp: Date(),
            parameters: parameters
        )
        trackEvent(event)
    }
    
    // MARK: - Private Methods
    
    private func setupBatchUpload() {
        batchUploadTimer = Timer.scheduledTimer(
            withTimeInterval: batchUploadInterval,
            repeats: true
        ) { [weak self] _ in
            self?.uploadEvents()
        }
    }
    
    private func uploadEvents() {
        guard !events.isEmpty else { return }
        
        eventQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Check network connectivity
            guard self.networkMonitor.isConnected else {
                // Keep events in cache if offline
                self.saveEventsToPersistentCache()
                return
            }
            
            // Prepare batch for upload
            let eventsToUpload = self.events
            self.events.removeAll()
            
            // Upload to analytics service
            Task {
                do {
                    let request = AnalyticsRequest(events: eventsToUpload)
                    try await APIService.shared.post(endpoint: .analytics, body: request)
                    
                    // Clear uploaded events from persistent cache
                    self.saveEventsToPersistentCache()
                } catch {
                    // If upload fails, add events back to queue
                    self.events.append(contentsOf: eventsToUpload)
                    self.saveEventsToPersistentCache()
                    SecurityLogger.shared.logError(error)
                }
            }
        }
    }
    
    private func saveEventsToPersistentCache() {
        do {
            try persistentCache.set(events, forKey: "analytics_events")
        } catch {
            SecurityLogger.shared.logError(error)
        }
    }
    
    private func loadCachedEvents() {
        eventQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                if let cachedEvents: [AnalyticsEvent] = try persistentCache.get(forKey: "analytics_events") {
                    self.events = cachedEvents
                }
            } catch {
                SecurityLogger.shared.logError(error)
            }
        }
    }
}

// MARK: - Supporting Types

struct AnalyticsRequest: Codable {
    let events: [AnalyticsEvent]
    let deviceInfo: DeviceInfo
    let appInfo: AppInfo
    
    init(events: [AnalyticsEvent]) {
        self.events = events
        self.deviceInfo = DeviceInfo()
        self.appInfo = AppInfo()
    }
}

struct DeviceInfo: Codable {
    let model: String
    let systemName: String
    let systemVersion: String
    let identifierForVendor: String?
    
    init() {
        let device = UIDevice.current
        self.model = device.model
        self.systemName = device.systemName
        self.systemVersion = device.systemVersion
        self.identifierForVendor = device.identifierForVendor?.uuidString
    }
}

struct AppInfo: Codable {
    let version: String
    let build: String
    
    init() {
        let bundle = Bundle.main
        self.version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        self.build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    }
}
