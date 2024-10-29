import Foundation
import Logging

struct FeatureRequirements {
    let minimumOSVersion: String
    let hardwareRequired: [String]?
    let processorRequired: [String]?
    let memoryRequired: Int64?
    let networkRequired: Bool?
    let securityPatchRequired: Bool?
    let backgroundProcessingRequired: Bool?
    let permissions: [String]?
    
    init(
        minimumOSVersion: String,
        hardwareRequired: [String]? = nil,
        processorRequired: [String]? = nil,
        memoryRequired: Int64? = nil,
        networkRequired: Bool? = nil,
        securityPatchRequired: Bool? = nil,
        backgroundProcessingRequired: Bool? = nil,
        permissions: [String]? = nil
    ) {
        self.minimumOSVersion = minimumOSVersion
        self.hardwareRequired = hardwareRequired
        self.processorRequired = processorRequired
        self.memoryRequired = memoryRequired
        self.networkRequired = networkRequired
        self.securityPatchRequired = securityPatchRequired
        self.backgroundProcessingRequired = backgroundProcessingRequired
        self.permissions = permissions
    }
    
    func validate() -> ValidationResult {
        var failures: [ValidationFailure] = []
        
        if !validateOSVersion() {
            failures.append(.osVersionNotMet(required: minimumOSVersion))
        }
        
        if let hardware = hardwareRequired, !validateHardware(hardware) {
            failures.append(.hardwareNotMet(required: hardware))
        }
        
        if let processors = processorRequired, !validateProcessor(processors) {
            failures.append(.processorNotMet(required: processors))
        }
        
        if let memory = memoryRequired, !validateMemory(memory) {
            failures.append(.memoryNotMet(required: memory))
        }
        
        if let network = networkRequired, !validateNetwork(network) {
            failures.append(.networkNotAvailable)
        }
        
        if let security = securityPatchRequired, !validateSecurityPatch(security) {
            failures.append(.securityPatchMissing)
        }
        
        if let background = backgroundProcessingRequired, !validateBackgroundProcessing(background) {
            failures.append(.backgroundProcessingNotAvailable)
        }
        
        if let requiredPermissions = permissions, !validatePermissions(requiredPermissions) {
            failures.append(.permissionsNotGranted(missing: requiredPermissions))
        }
        
        return ValidationResult(failures: failures)
    }
    
    private func validateOSVersion() -> Bool {
        guard let systemVersion = VersionNumber(UIDevice.current.systemVersion),
              let requiredVersion = VersionNumber(minimumOSVersion) else {
            return false
        }
        return systemVersion >= requiredVersion
    }
    
    private func validateHardware(_ required: [String]) -> Bool {
        let deviceCapabilities = DeviceCapabilities.current
        return required.allSatisfy { deviceCapabilities.supports($0) }
    }
    
    private func validateProcessor(_ required: [String]) -> Bool {
        let processorInfo = ProcessorInformation.current
        return required.contains(processorInfo.processorType)
    }
    
    private func validateMemory(_ required: Int64) -> Bool {
        return ProcessInfo.processInfo.physicalMemory >= UInt64(required)
    }
    
    private func validateNetwork(_ required: Bool) -> Bool {
        return !required || NetworkMonitor.shared.currentStatus != .offline
    }
    
    private func validateSecurityPatch(_ required: Bool) -> Bool {
        return !required || SecurityProvider.shared.isSecurityPatchInstalled
    }
    
    private func validateBackgroundProcessing(_ required: Bool) -> Bool {
        return !required || BackgroundTaskManager.shared.isBackgroundProcessingAvailable
    }
    
    private func validatePermissions(_ required: [String]) -> Bool {
        return PermissionValidator.shared.validatePermissions(required)
    }
}
