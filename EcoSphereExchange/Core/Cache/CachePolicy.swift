import Foundation
struct CachePolicy {
    let ttl: TimeInterval
    let priority: CachePriority
    let persistenceType: PersistenceType
    let compressionLevel: CompressionLevel
    
    enum CachePriority {
        case high, medium, low
        
        var memoryLimit: Int {
            switch self {
            case .high: return 100 * 1024 * 1024  // 100MB
            case .medium: return 50 * 1024 * 1024 // 50MB
            case .low: return 10 * 1024 * 1024    // 10MB
            }
        }
    }
    
    enum PersistenceType {
        case memory
        case disk
        case hybrid(ratio: Float)
    }
    
    static func optimizedPolicy(for contentType: ContentType) -> CachePolicy {
        switch contentType {
        case .image:
            return CachePolicy(ttl: 3600, priority: .medium, persistenceType: .hybrid(ratio: 0.7), compressionLevel: .medium)
        case .userProfile:
            return CachePolicy(ttl: 86400, priority: .high, persistenceType: .disk, compressionLevel: .none)
        case .temporaryData:
            return CachePolicy(ttl: 300, priority: .low, persistenceType: .memory, compressionLevel: .high)
        }
    }
}
