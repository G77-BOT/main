import Foundation

struct VersionNumber: Comparable, Codable {
    let major: Int
    let minor: Int
    let patch: Int
    let build: Int?
    
    init?(_ versionString: String) {
        let components = versionString.split(separator: ".")
        guard components.count >= 2 else { return nil }
        
        guard let majorVersion = Int(components[0]),
              let minorVersion = Int(components[1]) else {
            return nil
        }
        
        self.major = majorVersion
        self.minor = minorVersion
        
        if components.count > 2,
           let patchVersion = Int(components[2].split(separator: "-")[0]) {
            self.patch = patchVersion
        } else {
            self.patch = 0
        }
        
        if components.count > 3,
           let buildNumber = Int(components[3]) {
            self.build = buildNumber
        } else {
            self.build = nil
        }
    }
    
    var stringValue: String {
        var version = "\(major).\(minor).\(patch)"
        if let build = build {
            version += ".\(build)"
        }
        return version
    }
    
    static func < (lhs: VersionNumber, rhs: VersionNumber) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        if lhs.patch != rhs.patch {
            return lhs.patch < rhs.patch
        }
        if let lhsBuild = lhs.build, let rhsBuild = rhs.build {
            return lhsBuild < rhsBuild
        }
        return false
    }
    
    static func == (lhs: VersionNumber, rhs: VersionNumber) -> Bool {
        return lhs.major == rhs.major &&
               lhs.minor == rhs.minor &&
               lhs.patch == rhs.patch &&
               lhs.build == rhs.build
    }
    
    func isCompatible(with minimumVersion: VersionNumber) -> Bool {
        return self >= minimumVersion
    }
    
    func requiresUpdate(toVersion newVersion: VersionNumber) -> Bool {
        return self < newVersion
    }
}
