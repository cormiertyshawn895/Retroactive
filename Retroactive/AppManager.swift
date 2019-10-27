//
//  AppManager.swift
//  Retroactive
//

import Cocoa

enum AppType {
    case aperture
    case iphoto
    case itunes
}

enum iTunesVersion {
    case darkMode
    case appStore
    case coverFlow
}

let placeholderToken = "{name}"
let timeToken = "{timeEstimate}"
let actionDetailToken = "{actionS}"
let mainActionToken = "{actionM}"

class AppManager: NSObject {
    var configurationDictionary: Dictionary<String, Any> {
        get {
            if let path = Bundle.main.path(forResource: "SupportPath", ofType: "plist"),
                let loaded = NSDictionary(contentsOfFile: path) as? Dictionary<String, String> {
               _configurationDictionary = loaded
            }
            return _configurationDictionary!
        }
    }
    
    var releasePage: String {
        return configurationDictionary["ReleasePage"] as? String ?? "https://github.com/cormiertyshawn895/Retroactive/releases"
    }
    
    var sourcePage: String {
        return configurationDictionary["SourcePage"] as? String ?? "https://github.com/cormiertyshawn895/Retroactive"
    }
    
    var issuesPage: String {
        return configurationDictionary["IssuesPage"] as? String ?? "https://github.com/cormiertyshawn895/Retroactive/issues"
    }

    var latestZIP: String {
        return configurationDictionary["LatestZIP"] as? String ?? "https://github.com/cormiertyshawn895/Retroactive/releases/Retroactive1_0.zip"
    }
    
    var latestBuildNumber: Int {
        return configurationDictionary["LatestBuildNumber"] as? Int ?? 1
    }
    
    var catalogURL: String {
        return configurationDictionary["CatalogURL"] as? String ?? "https://swscan.apple.com/content/catalogs/others/index-10.14-10.13-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog.gz"
    }

    var downloadIdentifier: String {
        return configurationDictionary["DownloadIdentifier"] as? String ?? "061-26589"
    }

    private var _configurationDictionary: Dictionary<String, String>?
    
    var chosenApp: AppType? {
        didSet {
            if NSApp.mainWindow?.contentViewController != nil {
                AppDelegate.rootVC?.currentDocumentTitle = AppManager.shared.nameOfChosenApp
            }
            locationOfChosenApp = nil
        }
    }
    var choseniTunesVersion: iTunesVersion?
    
    var locationOfChosenApp: String?
    var nameOfChosenApp: String {
        get {
            switch self.chosenApp {
            case .aperture:
                return "Aperture"
            case .iphoto:
                return "iPhoto"
            case .itunes:
                return "iTunes"
            default:
                return "Untitled"
            }
        }
    }
    
    var binaryNameOfChosenApp: String {
        get {
            return self.nameOfChosenApp
        }
    }
    
    var compatibleVersionOfChosenApp: [String] {
        get {
            switch self.chosenApp {
            case .aperture:
                return ["3.6"]
            case .iphoto:
                return ["9.6.1", "9.6"]
            case .itunes:
                switch choseniTunesVersion {
                case .darkMode:
                    return ["12.9.5"]
                case .appStore:
                    return ["12.6.5"]
                case .coverFlow:
                    return ["10.7"]
                case .none:
                    return []
                }
            default:
                return []
            }
        }
    }

    var existingBundleIDOfChosenApp: String {
        get {
            switch self.chosenApp {
            case .aperture:
                return "com.apple.Aperture"
            case .iphoto:
                return "com.apple.iPhoto"
            case .itunes:
                return "com.apple.iTunes"
            default:
                return ""
            }
        }
    }
    
    var patchedBundleIDOfChosenApp: String {
        get {
            switch self.chosenApp {
            case .aperture:
                return "com.apple.Aperture3"
            case .iphoto:
                return "com.apple.iPhoto9"
            case .itunes:
                switch choseniTunesVersion {
                // These are intentionally left unused
                case .darkMode:
                    return "com.apple.iTunes129"
                case .appStore:
                    return "com.apple.iTunes126"
                case .coverFlow:
                    return "com.apple.iTunes10"
                case .none:
                    return ""
                }
            default:
                return ""
            }
        }
    }
    
    var patchedVersionStringOfChosenApp: String {
        get {
            switch self.chosenApp {
            case .aperture:
                return "99.9"
            case .iphoto:
                return "99.9"
            case .itunes:
                switch choseniTunesVersion {
                case .darkMode:
                    return "13.9.5"
                case .appStore:
                    return "13.6.5"
                case .coverFlow:
                    return "13.7"
                case .none:
                    return ""
                }
            default:
                return ""
            }
        }
    }
    
    var appPathCString: String? {
        guard var appPath = AppManager.shared.locationOfChosenApp else { return "" }
        let appPathCString = (appPath as NSString).fileSystemRepresentation
        appPath = String(cString: appPathCString)
        return appPath
    }
    
    var airdropImage: NSImage? {
        get {
            switch self.chosenApp {
            case .aperture:
                return NSImage(named: "airdrop_guide_aperture")
            case .iphoto:
                return NSImage(named: "airdrop_guide_iphoto")
            default:
                return nil
            }
        }
    }

    var appStoreImage: NSImage? {
        get {
            switch self.chosenApp {
            case .aperture:
                return NSImage(named: "appstore_guide_aperture")
            case .iphoto:
                return NSImage(named: "appstore_guide_iphoto")
            default:
                return nil
            }
        }
    }
    
    var cartoonIcon: NSImage? {
        get {
            switch self.chosenApp {
            case .aperture:
                return NSImage(named: "aperture_cartoon")
            case .iphoto:
                return NSImage(named: "iphoto_cartoon")
            case .itunes:
                return NSImage(named: "itunes_cartoon")
            default:
                return nil
            }
        }
    }
    
    var behindTheScenesOfChosenApp: String {
        get {
            switch self.chosenApp {
            case .aperture:
                return "https://medium.com/@cormiertyshawn895/how-to-run-aperture-and-iphoto-on-macos-catalina-46a86d028b87"
            case .iphoto:
                return "https://medium.com/@cormiertyshawn895/how-to-run-aperture-and-iphoto-on-macos-catalina-46a86d028b87"
            case .itunes:
                switch choseniTunesVersion {
                case .darkMode:
                    return "https://forums.macrumors.com/threads/itunes-12-6-5-3-on-macos-catalina-10-15.2184518/page-4?post=27843550#post-27843550"
                case .appStore:
                    return "https://forums.macrumors.com/threads/itunes-12-6-5-3-on-macos-catalina-10-15.2184518/page-4?post=27807492#post-27807492"
                case .coverFlow:
                    return "https://forums.macrumors.com/threads/how-to-safely-re-install-itunes-10-7-in-mavericks.1667115/"
                case .none:
                    return ""
                }
            default:
                return ""
            }
        }
    }
    
    var downloadURLOfChosenApp: String? {
        get {
            switch self.chosenApp {
            case .aperture:
                return nil
            case .iphoto:
                return nil
            case .itunes:
                switch choseniTunesVersion {
                case .darkMode:
                    return configurationDictionary["InstallerURL"] as? String
                case .appStore:
                    return configurationDictionary["iTunes126URL"] as? String
                case .coverFlow:
                    return configurationDictionary["iTunes107URL"] as? String
                case .none:
                    return nil
                }
            default:
                return nil
            }
        }
    }
    
    var downloadFileNameOfChosenApp: String {
        get {
            if let downloadURL = self.downloadURLOfChosenApp, let url = URL(string: downloadURL) {
                return url.lastPathComponent
            }
            return "blob"
        }
    }
    
    var mountDirNameOfChosenApp: String {
        get {
            if let downloadURL = self.downloadURLOfChosenApp, let url = URL(string: downloadURL) {
                return "\(url.deletingPathExtension().lastPathComponent)Mount"
            }
            return "blobMount"
        }
    }
    
    var extractDirNameOfChosenApp: String {
        get {
            if let downloadURL = self.downloadURLOfChosenApp, let url = URL(string: downloadURL) {
                return "\(url.deletingPathExtension().lastPathComponent)Extract"
            }
            return "blobExtract"
        }
    }

    var mainActionOfChosenApp: String {
        get {
            switch self.chosenApp {
            case .itunes:
                return "installing"
            default:
                return "modifying"
            }
        }
    }
    
    var detailActionOfChosenApp: String {
        get {
            switch self.chosenApp {
            case .itunes:
                return "downloading and installing"
            default:
                return "installing support files for"
            }
        }
    }

    var timeEstimateStringOfChosenApp: String {
        get {
            switch self.chosenApp {
            case .itunes:
                switch choseniTunesVersion {
                case .darkMode:
                    return "25 minutes"
                case .appStore:
                    return "10 minutes"
                case .coverFlow:
                    return "10 minutes"
                case .none:
                    return "an hour"
                }
            default:
                return "2 minutes"
            }
        }
    }

    static let shared = AppManager()
    
    private override init() {
        
    }
    
    static func replaceTokenFor(_ string: String) -> String {
        return string.replacingOccurrences(of: placeholderToken, with: AppManager.shared.nameOfChosenApp).replacingOccurrences(of: timeToken, with: AppManager.shared.timeEstimateStringOfChosenApp).replacingOccurrences(of: mainActionToken, with: AppManager.shared.mainActionOfChosenApp).replacingOccurrences(of: actionDetailToken, with: AppManager.shared.detailActionOfChosenApp)
    }

}
