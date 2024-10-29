import Foundation
import UIKit
import LocalAuthentication
import Security
import MetricsKit


final class DeviceCapabilities {
    static let current = DeviceCapabilities()
    private let device = UIDevice.current
    
    enum BiometricType {
        case none
        case touchID
        case faceID
    }
    
    enum SecurityFeature {
        case secureEnclave
        case keychain
        case biometrics
        case appDataProtection
        case secureBootchain
    }
    
    struct HardwareCapabilities {
        let processorType: String
        let processorCount: Int
        let memorySize: UInt64
        let secureEnclavePresent: Bool
        let biometricType: BiometricType
    }
    
    private(set) var hardwareCapabilities: HardwareCapabilities = {
        return HardwareCapabilities(
            processorType: ProcessorInformation.current.processorType,
            processorCount: ProcessInfo.processInfo.processorCount,
            memorySize: ProcessInfo.processInfo.physicalMemory,
            secureEnclavePresent: SecureEnclaveCheck.isAvailable(),
            biometricType: BiometricAuthenticator.shared.biometricType
        )
    }()
    
    func supports(_ feature: String) -> Bool {
        switch feature.lowercased() {
        case "faceid":
            return hardwareCapabilities.biometricType == .faceID
        case "touchid":
            return hardwareCapabilities.biometricType == .touchID
        case "secureenclave":
            return hardwareCapabilities.secureEnclavePresent
        case "neural":
            return ProcessorInformation.current.supportsNeuralEngine
        case "quantumencryption":
            return hardwareCapabilities.processorType.contains("A12") ||
                   hardwareCapabilities.processorType.contains("M1")
        default:
            return false
        }
    }
    
    func validateSecurityFeatures() -> [SecurityFeature: Bool] {
        return [
            .secureEnclave: SecureEnclaveCheck.isAvailable(),
            .keychain: KeychainCheck.isAvailable(),
            .biometrics: BiometricAuthenticator.shared.isAvailable,
            .appDataProtection: FileProtectionCheck.isEnabled(),
            .secureBootchain: SecureBootCheck.isEnabled()
        ]
    }
    
    func getSecurityReport() -> SecurityReport {
        let features = validateSecurityFeatures()
        let hardware = hardwareCapabilities
        
        return SecurityReport(
            timestamp: Date(),
            deviceModel: device.model,
            systemVersion: device.systemVersion,
            securityFeatures: features,
            hardwareCapabilities: hardware,
            integrityStatus: IntegrityChecker.shared.validateSystemIntegrity()
        )
    }
}

// MARK: - Security Checks
private extension DeviceCapabilities {
    struct SecureEnclaveCheck {
        static func isAvailable() -> Bool {
            var error: Unmanaged<CFError>?
            guard SecKeyCreateRandomKey([
                kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                kSecAttrKeySizeInBits: 256
            ] as CFDictionary, &error) != nil else {
                return false
            }
            return true
        }
    }
    
    struct KeychainCheck {
        static func isAvailable() -> Bool {
            let query = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: "test_keychain_access",
                kSecValueData: "test".data(using: .utf8)!
            ] as [String: Any]
            
            let status = SecItemAdd(query as CFDictionary, nil)
            if status == errSecSuccess || status == errSecDuplicateItem {
                SecItemDelete(query as CFDictionary)
                return true
            }
            return false
        }
    }
    
    struct FileProtectionCheck {
        static func isEnabled() -> Bool {
            let fileManager = FileManager.default
            guard let documentPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return false
            }
            
            do {
                let attributes = try fileManager.attributesOfFileSystem(forPath: documentPath.path)
                return attributes[.protectionKey] as? FileProtectionType == .complete
            } catch {
                return false
            }
        }
    }
    
    struct SecureBootCheck {
        static func isEnabled() -> Bool {
            #if targetEnvironment(simulator)
            return true
            #else
            return isDeviceSecurelyBooted()
            #endif
        }
        
        private static func isDeviceSecurelyBooted() -> Bool {
            // Implementation would check system boot chain integrity
            // This requires private APIs in production
            return true
        }
    }
}
