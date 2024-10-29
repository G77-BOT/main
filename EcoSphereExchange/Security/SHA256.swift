import Foundation
import CommonCrypto

final class SHA256 {
    enum HashError: Error {
        case inputDataEmpty
        case hashingFailed
        case invalidHexString
        case invalidBufferSize
    }
    
    static func hash(data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(data.count), &hash)
        }
        
        return Data(hash)
    }
    
    static func hash(string: String) throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw HashError.inputDataEmpty
        }
        return hash(data: data)
    }
    
    static func hashWithSalt(data: Data, salt: Data) -> Data {
        let saltedData = data + salt
        return hash(data: saltedData)
    }
    
    static func verify(data: Data, against hash: Data) -> Bool {
        let computedHash = self.hash(data: data)
        return computedHash == hash
    }
    
    static func hexString(from hash: Data) -> String {
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    static func data(fromHexString string: String) throws -> Data {
        let length = string.count
        guard length % 2 == 0 else {
            throw HashError.invalidHexString
        }
        
        var data = Data(capacity: length/2)
        var index = string.startIndex
        
        while index < string.endIndex {
            let nextIndex = string.index(index, offsetBy: 2)
            let bytesString = string[index..<nextIndex]
            
            guard let byte = UInt8(bytesString, radix: 16) else {
                throw HashError.invalidHexString
            }
            
            data.append(byte)
            index = nextIndex
        }
        
        return data
    }
    
    static func iterativeHash(data: Data, iterations: Int) throws -> Data {
        guard iterations > 0 else {
            throw HashError.invalidBufferSize
        }
        
        var result = data
        for _ in 0..<iterations {
            result = hash(data: result)
        }
        
        return result
    }
    
    static func hmac(data: Data, key: Data) -> Data {
        let hashLength = Int(CC_SHA256_DIGEST_LENGTH)
        var macData = [UInt8](repeating: 0, count: hashLength)
        
        data.withUnsafeBytes { dataBuffer in
            key.withUnsafeBytes { keyBuffer in
                CCHmac(
                    CCHmacAlgorithm(kCCHmacAlgSHA256),
                    keyBuffer.baseAddress,
                    key.count,
                    dataBuffer.baseAddress,
                    data.count,
                    &macData
                )
            }
        }
        
        return Data(macData)
    }
}
