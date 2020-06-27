import Cocoa

private let osFullVersion = ProcessInfo.processInfo.operatingSystemVersion
private let osMajorVersion = osFullVersion.majorVersion
private let osMinorVersion = osFullVersion.minorVersion
private let processInfo = ProcessInfo()

let osAtLeastHighSierra = processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 10, minorVersion: 13, patchVersion: 0))
let osAtLeastMojave = processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 10, minorVersion: 14, patchVersion: 0))
let osAtLeastCatalina = processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 10, minorVersion: 15, patchVersion: 0))
let osAtLeastBigSur = processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 10, minorVersion: 16, patchVersion: 0))

let discouraged_osExactlyHighSierra = osMajorVersion == 10 && osMinorVersion == 13
let discouraged_osExactlyMojave = osMajorVersion == 10 && osMinorVersion == 14
private let osExactlyCatalina = osMajorVersion == 10 && osMinorVersion == 15
private let osExactlyBigSur = (osMajorVersion == 10 && osMinorVersion == 16) || osMajorVersion == 11

extension ProcessInfo {
    static var osVersionNumberString: String {
        let patchVersion = osFullVersion.patchVersion
        var patchString = ""
        if (patchVersion > 0) {
            patchString = ".\(patchVersion)"
        }
        return "\(osMajorVersion).\(osMinorVersion)\(patchString)"
    }

    static var versionString: String {
        return "macOS \(self.osVersionNumberString)"
    }
    
    static var versionName: String {
        if (discouraged_osExactlyHighSierra) {
            return "macOS High Sierra"
        }
        if (discouraged_osExactlyMojave) {
            return "macOS Mojave"
        }
        if (osExactlyCatalina) {
            return "macOS Catalina"
        }
        if (osExactlyBigSur) {
            return "macOS Big Sur"
        }
        return ProcessInfo.versionString
    }
}
