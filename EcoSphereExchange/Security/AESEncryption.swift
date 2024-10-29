import Foundation
import CommonCrypto

final class AESEncryption {
    enum AESError: Error {
        case keyGeneration
        case encryption
        case decryption
        case invalidKeySize
        case invalidInputData
        case invalidInitializationVector
    }
    
    static let keySizes: [Int] = [128, 192, 256]
    private static let ivSize = kCCBlockSizeAES128
    
    struct EncryptedData {
        let ciphertext: Data
        let iv: Data
        let tag: Data?
        let keySize: Int
    }
    
    static func encrypt(data: Data, keySize: Int = 256) throws -> EncryptedData {
        guard keySizes.contains(keySize) else {
            throw AESError.invalidKeySize
        }
        
        let key = try generateSecureKey(size: keySize)
        let iv = try generateIV()
        
        let bufferSize = data.count + kCCBlockSizeAES128
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var numBytesEncrypted = 0
        
        let status = data.withUnsafeBytes { dataBytes in
            key.withUnsafeBytes { keyBytes in
                iv.withUnsafeBytes { ivBytes in
                    CCCrypt(
                        CCOperation(kCCEncrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress,
                        key.count,
                        ivBytes.baseAddress,
                        dataBytes.baseAddress,
                        data.count,
                        &buffer,
                        bufferSize,
                        &numBytesEncrypted
                    )
                }
            }
        }
        
        guard status == kCCSuccess else {
            throw AESError.encryption
        }
        
        let encryptedData = Data(buffer.prefix(numBytesEncrypted))
        let tag = try calculateHMAC(for: encryptedData, using: key)
        
        return EncryptedData(
            ciphertext: encryptedData,
            iv: iv,
            tag: tag,
            keySize: keySize
        )
    }
    
    static func decrypt(encryptedData: EncryptedData, with key: Data) throws -> Data {
        guard encryptedData.keySize == key.count * 8 else {
            throw AESError.invalidKeySize
        }
        
        if let tag = encryptedData.tag {
            let calculatedTag = try calculateHMAC(for: encryptedData.ciphertext, using: key)
            guard tag == calculatedTag else {
                throw AESError.invalidInputData
            }
        }
        
        let bufferSize = encryptedData.ciphertext.count + kCCBlockSizeAES128
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var numBytesDecrypted = 0
        
        let status = encryptedData.ciphertext.withUnsafeBytes { dataBytes in
            key.withUnsafeBytes { keyBytes in
                encryptedData.iv.withUnsafeBytes { ivBytes in
                    CCCrypt(
                        CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress,
                        key.count,
                        ivBytes.baseAddress,
                        dataBytes.baseAddress,
                        encryptedData.ciphertext.count,
                        &buffer,
                        bufferSize,
                        &numBytesDecrypted
                    )
                }
            }
        }
        
        guard status == kCCSuccess else {
            throw AESError.decryption
        }
        
        return Data(buffer.prefix(numBytesDecrypted))
    }
    
    private static func generateSecureKey(size: Int) throws -> Data {
        let keyLength = size / 8
        var keyData = Data(count: keyLength)
        
        let result = keyData.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, keyLength, bytes.baseAddress!)
        }
        
        guard result == errSecSuccess else {
            throw AESError.keyGeneration
        }
        
        return keyData
    }
    
    private static func generateIV() throws -> Data {
        var ivData = Data(count: ivSize)
        
        let result = ivData.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, ivSize, bytes.baseAddress!)
        }
        
        guard result == errSecSuccess else {
            throw AESError.invalidInitializationVector
        }
        
        return ivData
    }
    
    private static func calculateHMAC(for data: Data, using key: Data) throws -> Data {
        var hmac = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        
        data.withUnsafeBytes { dataBytes in
            key.withUnsafeBytes { keyBytes in
                CCHmac(
                    CCHmacAlgorithm(kCCHmacAlgSHA256),
                    keyBytes.baseAddress,
                    key.count,
                    dataBytes.baseAddress,
                    data.count,
                    &hmac
                )
            }
        }
        
        return Data(hmac)
    }
}
