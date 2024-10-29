import Foundation

struct ResourceRequirements: Codable {
    let computational: ComputationalResources
    let memory: MemoryResources
    let storage: StorageResources
    let network: NetworkResources
    
    struct ComputationalResources: Codable {
        let cpuCores: Int
        let gpuCores: Int?
        let quantumUnits: Int?
        let processingPower: Double // FLOPS
        let utilizationTarget: Double
        
        var isQuantumEnabled: Bool {
            return quantumUnits != nil && quantumUnits! > 0
        }
    }
    
    struct MemoryResources: Codable {
        let ramRequired: Double // In bytes
        let bufferSize: Double
        let cacheSize: Double
        let swapSpace: Double
        let priorityLevel: Priority
        
        enum Priority: Int, Codable {
            case realtime = 0
            case high = 1
            case normal = 2
            case background = 3
        }
    }
    
    struct StorageResources: Codable {
        let persistentStorage: Double
        let temporaryStorage: Double
        let backupStorage: Double
        let encryptionOverhead: Double
        let redundancyFactor: Double
    }
    
    struct NetworkResources: Codable {
        let bandwidth: Double
        let latencyRequirement: TimeInterval
        let concurrentConnections: Int
        let encryptedChannels: Int
        let redundantPaths: Int
    }
    
    func validate() -> ValidationResult {
        let validator = ResourceValidator(requirements: self)
        return validator.validate()
    }
    
    func optimize() -> ResourceRequirements {
        let optimizer = ResourceOptimizer(requirements: self)
        return optimizer.optimize()
    }
    
    func allocate() async throws -> ResourceAllocation {
        let allocator = ResourceAllocator(requirements: self)
        return try await allocator.allocate()
    }
    
    func calculateCost() -> ResourceCost {
        return ResourceCost(
            computationalCost: calculateComputationalCost(),
            memoryCost: calculateMemoryCost(),
            storageCost: calculateStorageCost(),
            networkCost: calculateNetworkCost()
        )
    }
    
    func scaleFor(load: Double) -> ResourceRequirements {
        let scaler = ResourceScaler(requirements: self)
        return scaler.scale(factor: load)
    }
    
    func monitor() -> ResourceMonitor {
        return ResourceMonitor(
            requirements: self,
            updateInterval: 1.0,
            alertThreshold: 0.85
        )
    }
    
    private func calculateComputationalCost() -> Double {
        return computational.cpuCores * 100 +
               (computational.gpuCores ?? 0) * 200 +
               (computational.quantumUnits ?? 0) * 1000
    }
    
    private func calculateMemoryCost() -> Double {
        return memory.ramRequired * 0.01 +
               memory.bufferSize * 0.005 +
               memory.cacheSize * 0.003
    }
    
    private func calculateStorageCost() -> Double {
        return storage.persistentStorage * 0.02 +
               storage.backupStorage * 0.01 +
               storage.temporaryStorage * 0.005
    }
    
    private func calculateNetworkCost() -> Double {
        return network.bandwidth * 0.1 +
               Double(network.concurrentConnections) * 0.5 +
               Double(network.encryptedChannels) * 1.0
    }
    
    func generateReport() -> ResourceReport {
        return ResourceReport(
            requirements: self,
            cost: calculateCost(),
            utilization: calculateUtilization(),
            recommendations: generateRecommendations()
        )
    }
}
