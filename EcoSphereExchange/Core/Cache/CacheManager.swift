import Foundation

actor CacheManager {
    static let shared = CacheManager()
    
    private var memoryCache = NSCache<NSString, AnyObject>()
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.ecosphere.cache", qos: .utility)
    
    private init() {
        setupCache()
    }
    
    private func setupCache() {
        // Configure memory cache
        memoryCache.countLimit = 100 // Maximum number of objects
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
        
        // Setup disk cache directory
        createCacheDirectory()
        
        // Add cache cleanup notification observers
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.clearMemoryCache()
            }
        }
    }
    
    private func createCacheDirectory() {
        do {
            let cacheURL = try FileManager.default.url(
                for: .cachesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("EcoSphereCache")
            
            if !FileManager.default.fileExists(atPath: cacheURL.path) {
                try FileManager.default.createDirectory(
                    at: cacheURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }
        } catch {
            SecurityLogger.shared.logError(error)
        }
    }
    
    // MARK: - Public Methods
    
    func cache<T: Codable>(object: T, forKey key: String) async throws {
        // Cache in memory
        if let data = try? JSONEncoder().encode(object) {
            memoryCache.setObject(data as NSData, forKey: key as NSString)
        }
        
        // Cache to disk
        try await persistToDisk(object: object, forKey: key)
    }
    
    func retrieve<T: Codable>(forKey key: String) async throws -> T? {
        // Check memory cache first
        if let cachedData = memoryCache.object(forKey: key as NSString) as? Data {
            return try JSONDecoder().decode(T.self, from: cachedData)
        }
        
        // Check disk cache
        return try await retrieveFromDisk(forKey: key)
    }
    
    func removeObject(forKey key: String) async {
        // Remove from memory
        memoryCache.removeObject(forKey: key as NSString)
        
        // Remove from disk
        await removeDiskCache(forKey: key)
    }
    
    func clearAll() async {
        // Clear memory cache
        memoryCache.removeAllObjects()
        
        // Clear disk cache
        await clearDiskCache()
    }
    
    func clearExpired() async {
        await clearExpiredDiskCache()
    }
    
    // MARK: - Private Methods
    
    private func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    private func persistToDisk<T: Codable>(object: T, forKey key: String) async throws {
        let cacheURL = try cacheDirectoryURL().appendingPathComponent(key)
        
        let data = try JSONEncoder().encode(CacheEntry(object: object))
        try data.write(to: cacheURL)
    }
    
    private func retrieveFromDisk<T: Codable>(forKey key: String) async throws -> T? {
        let cacheURL = try cacheDirectoryURL().appendingPathComponent(key)
        
        guard let data = try? Data(contentsOf: cacheURL) else {
            return nil
        }
        
        let cacheEntry = try JSONDecoder().decode(CacheEntry<T>.self, from: data)
        
        // Check if cache entry is expired
        if cacheEntry.isExpired {
            await removeDiskCache(forKey: key)
            return nil
        }
        
        return cacheEntry.object
    }
    
    private func removeDiskCache(forKey key: String) async {
        do {
            let cacheURL = try cacheDirectoryURL().appendingPathComponent(key)
            try? fileManager.removeItem(at: cacheURL)
        } catch {
            SecurityLogger.shared.logError(error)
        }
    }
    
    private func clearDiskCache() async {
        do {
            let cacheURL = try cacheDirectoryURL()
            let contents = try fileManager.contentsOfDirectory(
                at: cacheURL,
                includingPropertiesForKeys: nil,
                options: []
            )
            
            for fileURL in contents {
                try? fileManager.removeItem(at: fileURL)
            }
        } catch {
            SecurityLogger.shared.logError(error)
        }
    }
    
    private func clearExpiredDiskCache() async {
        do {
            let cacheURL = try cacheDirectoryURL()
            let contents = try fileManager.contentsOfDirectory(
                at: cacheURL,
                includingPropertiesForKeys: nil,
                options: []
            )
            
            for fileURL in contents {
                if let data = try? Data(contentsOf: fileURL),
                   let cacheEntry = try? JSONDecoder().decode(CacheEntry<AnyObject>.self, from: data),
                   cacheEntry.isExpired {
                    try? fileManager.removeItem(at: fileURL)
                }
            }
        } catch {
            SecurityLogger.shared.logError(error)
        }
    }
    
    private func cacheDirectoryURL() throws -> URL {
        try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("EcoSphereCache")
    }
}

// MARK: - Supporting Types

private struct CacheEntry<T: Codable>: Codable {
    let object: T
    let timestamp: Date
    let expirationInterval: TimeInterval
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > expirationInterval
    }
    
    init(object: T, expirationInterval: TimeInterval = 60 * 60 * 24) { // Default 24 hours
        self.object = object
        self.timestamp = Date()
        self.expirationInterval = expirationInterval
    }
}
