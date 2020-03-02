import Cocoa

extension ProcessInfo {
    static var versionString: String {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let patchVersion = osVersion.patchVersion
        var patchString = ""
        if (patchVersion > 0) {
            patchString = ".\(patchVersion)"
        }
        return "macOS \(osVersion.majorVersion).\(osVersion.minorVersion)\(patchString)"
    }
    
    static var versionName: String {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let minorVersion = osVersion.minorVersion
        if (minorVersion == 13) {
            return "macOS High Sierra"
        }
        if (minorVersion == 14) {
            return "macOS Mojave"
        }
        if (minorVersion == 15) {
            return "macOS Catalina"
        }
        return ProcessInfo.versionString
    }
}
