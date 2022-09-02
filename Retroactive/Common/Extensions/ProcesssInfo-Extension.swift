import Cocoa

private let osFullVersion = ProcessInfo.processInfo.operatingSystemVersion
private let osMajorVersion = osFullVersion.majorVersion
private let osMinorVersion = osFullVersion.minorVersion
private let processInfo = ProcessInfo()

let osAtLeastHighSierra = processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 10, minorVersion: 13, patchVersion: 0))
let osAtLeastMojave = processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 10, minorVersion: 14, patchVersion: 0))
let osAtLeastCatalina = processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 10, minorVersion: 15, patchVersion: 0))
let osAtLeastBigSur = processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 10, minorVersion: 16, patchVersion: 0))
let osAtLeastMonterey = processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 12, minorVersion: 0, patchVersion: 0))
let osAtLeastMontereyE = processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 12, minorVersion: 3, patchVersion: 0))
let osAtLeastVentura = processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 13, minorVersion: 0, patchVersion: 0))
let osAtLeast2023 = processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 14, minorVersion: 0, patchVersion: 0))

let discouraged_osExactlyHighSierra = osMajorVersion == 10 && osMinorVersion == 13
let discouraged_osExactlyMojave = osMajorVersion == 10 && osMinorVersion == 14
let discouraged_osExactlyCatalina = osMajorVersion == 10 && osMinorVersion == 15
let discouraged_osExactlyBigSur = (osMajorVersion == 10 && osMinorVersion == 16) || osMajorVersion == 11
let discouraged_osExactlyMonterey = osMajorVersion == 12
let discouraged_osExactlyVentura = osMajorVersion == 13
let discouraged_osHasExperimentalSupport = false

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
        if (discouraged_osExactlyCatalina) {
            return "macOS Catalina"
        }
        if (discouraged_osExactlyBigSur) {
            return "macOS Big Sur"
        }
        if (discouraged_osExactlyMonterey) {
            return "macOS Monterey"
        }
        if (discouraged_osExactlyVentura) {
            return "macOS Ventura"
        }
        return ProcessInfo.versionString
    }
}
