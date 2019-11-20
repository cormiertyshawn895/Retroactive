//
//  AppManager.swift
//  Retroactive
//

import Cocoa

enum AppType {
    case aperture
    case iphoto
    case itunes
    case finalCutPro7
    case logicPro9
    case keynote5
    
    case proVideoUpdate
}

enum iTunesVersion {
    case darkMode
    case appStore
    case coverFlow
}

let kCFBundleIdentifier = "CFBundleIdentifier"
let kCFBundleVersion = "CFBundleVersion"
let kCFBundleShortVersionString = "CFBundleShortVersionString"

let placeholderToken = "{name}"
let timeToken = "{timeEstimate}"
let actionDetailToken = "{actionS}"
let mainActionToken = "{actionM}"
let systemNameToken = "{systemName}"
let purposeToken = "{purpose}"
let actionPresentTenseToken = "{actionPR}"

extension Bundle {
    var cfBundleVersionInt: Int? {
        get {
            if let bundleVersion = self.infoDictionary?[kCFBundleVersion] as? String, let intVersion = Int(bundleVersion) {
                return intVersion
            }
            return nil
        }
    }
    
    var cfBundleVersionString: String? {
        get {
            return self.infoDictionary?[kCFBundleShortVersionString] as? String
        }
    }
}

extension NSObject {
    func syncMainQueue(closure: (() -> ())) {
        if !Thread.isMainThread {
            DispatchQueue.main.sync {
                closure()
            }
        } else {
            closure()
        }
    }
}

class AppManager: NSObject {
    
    static let shared = AppManager()
    
    private override init() {
        super.init()
        if let path = Bundle.main.path(forResource: "SupportPath", ofType: "plist"),
            let loaded = NSDictionary(contentsOfFile: path) as? Dictionary<String, Any> {
            self.configurationDictionary = loaded
        }
        
        self.checkForConfigurationUpdates()
    }
    
    func checkForConfigurationUpdates() {
        guard let support = self.supportPath, let configurationPath = URL(string: support) else { return }
        self.downloadAndParsePlist(plistPath: configurationPath) { (newDictionary) in
            self.configurationDictionary = newDictionary
            self.refreshiTunesURL()
        }
    }
    
    func downloadAndParsePlist(plistPath: URL, completed: @escaping ((Dictionary<String, Any>) -> ())) {
        let task = URLSession.shared.dataTask(with: plistPath) { (data, response, error) in
            if error != nil {
                print("Error loading \(plistPath). \(String(describing: error))")
            }
            do {
                let data = try Data(contentsOf:plistPath)
                if let newDictionary = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? Dictionary<String, Any> {
                    print("Downloaded dictionary \(String(describing: self.configurationDictionary))")
                    completed(newDictionary)
                }
            } catch {
                print("Error loading fetched support data. \(error)")
            }
        }
        
        task.resume()
    }
    
    func refreshUpdateBadge() {
        self.syncMainQueue {
            if self.hasNewerVersion {
                print("update available")
                if let rootVC = AppDelegate.rootVC {
                    rootVC.updateButton.isHidden = false
                }
            }
        }
    }
    
    var hasNewerVersion: Bool {
        get {
            if let versionNumber = Bundle.main.cfBundleVersionInt, let remoteVersion = self.latestBuildNumber {
                print("\(versionNumber), \(remoteVersion)")
                if (versionNumber < remoteVersion) {
                    return true
                }
            }
        return false
        }
    }
    private var configurationDictionary: Dictionary<String, Any>? {
        didSet {
            self.refreshUpdateBadge()
        }
    }
    
    func refreshiTunesURL() {
        if let iTunesPath = iTunesCatalogURL, let iTunesURL = URL(string: iTunesPath), let iTunesID = iTunesDownloadIdentifier, let expectedName = self.iTunesExpectedName {
            self.downloadAndParsePlist(plistPath: iTunesURL) { (dictionary) in
                if let products = dictionary["Products"] as? Dictionary<String, Dictionary<String, Any>>,
                    let relevant = products[iTunesID],
                    let packages = relevant["Packages"] as? [Dictionary<String, Any>] {
                    for dictArray in packages {
                        if let urlString = dictArray["URL"] as? String {
                            if (urlString.contains(expectedName)) {
                                self.configurationDictionary?["iTunes129URL"] = urlString
                                print("Found updated iTunes package: \(String(describing: urlString))")
                                return
                            }
                        }
                    }
                }
            }
        }
    }
    
    var isLanguageZhFamily: Bool {
        if let language = NSLocale.preferredLanguages.first?.lowercased() {
            return language.contains("zh-")
        }
        return false
    }
    
    var isLanguageTraditionalZhFamily: Bool {
        if let language = NSLocale.preferredLanguages.first?.lowercased() {
            return language.contains("zh-hant") || language.contains("zh-hk") || language.contains("zh-tw")
        }
        return false
    }
    
    var isLanguageSimplifiedZhFamily: Bool {
        if let language = NSLocale.preferredLanguages.first?.lowercased() {
            return language.contains("zh-hans") || language.contains("zh-cn")
        }
        return false
    }
    
    var newVersionVisibleTitle: String? {
        if isLanguageTraditionalZhFamily {
            return configurationDictionary?["NewVersionVisibleTitlezhHant"] as? String
        } else if isLanguageZhFamily {
            return configurationDictionary?["NewVersionVisibleTitlezhHans"] as? String
        }
        return configurationDictionary?["NewVersionVisibleTitle"] as? String
    }

    var newVersionChangelog: String? {
        if isLanguageTraditionalZhFamily {
            return configurationDictionary?["NewVersionChangelogzhHant"] as? String
        } else if isLanguageZhFamily {
            return configurationDictionary?["NewVersionChangelogzhHans"] as? String
        }
        return configurationDictionary?["NewVersionChangelog"] as? String
    }
    
    var latestZIP: String? {
        return configurationDictionary?["LatestZIP"] as? String
    }
    
    var latestBuildNumber: Int? {
        return configurationDictionary?["LatestBuildNumber"] as? Int
    }
    
    var supportPath: String? {
        return configurationDictionary?["SupportPathURL"] as? String
    }
    
    var releasePage: String? {
        return configurationDictionary?["ReleasePage"] as? String
    }
    
    var sourcePage: String? {
        return configurationDictionary?["SourcePage"] as? String
    }
    
    var newIssuePage: String? {
        return configurationDictionary?["NewIssuePage"] as? String
    }
    
    var issuesPage: String? {
        return configurationDictionary?["IssuesPage"] as? String
    }
    
    var wikiPage: String? {
        return configurationDictionary?["WikiPage"] as? String
    }
    
    var iTunesCatalogURL: String? {
        return configurationDictionary?["iTunes129CatalogURL"] as? String
    }
    
    var iTunesDownloadIdentifier: String? {
        return configurationDictionary?["iTunes129DownloadIdentifier"] as? String
    }
    
    var iTunesExpectedName: String? {
        return configurationDictionary?["iTunes129ExpectedName"] as? String
    }
    
    var apertureDive: String? {
        return configurationDictionary?["ApertureDive"] as? String
    }
    
    var iPhotoDive: String? {
        return configurationDictionary?["iPhotoDive"] as? String
    }
    
    var iTunes129Dive: String? {
        return configurationDictionary?["iTunes129Dive"] as? String
    }
    
    var iTunes126Dive: String? {
        return configurationDictionary?["iTunes126Dive"] as? String
    }

    var iTunes107Dive: String? {
        return configurationDictionary?["iTunes107Dive"] as? String
    }

    var iWork09DVD: String? {
        if isLanguageSimplifiedZhFamily {
            return configurationDictionary?["iWork09DVDCN"] as? String
        }
        return configurationDictionary?["iWork09DVD"] as? String
    }
    
    var iWork09Update: String? {
        return configurationDictionary?["iWork09Update"] as? String
    }

    var logicDVD: String? {
        if isLanguageSimplifiedZhFamily {
            return configurationDictionary?["LogicDVDCN"] as? String
        }
        return configurationDictionary?["LogicDVD"] as? String
    }
    
    var logicUpdate: String? {
        return configurationDictionary?["LogicUpdate"] as? String
    }

    var fcpDVD: String? {
        if isLanguageSimplifiedZhFamily {
            return configurationDictionary?["FCPDVDCN"] as? String
        }
        return configurationDictionary?["FCPDVD"] as? String
    }
    
    var fCPUpdate: String? {
        return configurationDictionary?["FCPUpdate"] as? String
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
                    return configurationDictionary?["iTunes129URL"] as? String
                case .appStore:
                    return configurationDictionary?["iTunes126URL"] as? String
                case .coverFlow:
                    return configurationDictionary?["iTunes107URL"] as? String
                case .none:
                    return nil
                }
            case .finalCutPro7:
                return nil
            case .logicPro9:
                return nil
            case .keynote5:
                return nil
            case .proVideoUpdate:
                return fCPUpdate
            default:
                return nil
            }
        }
    }
    
    var chosenApp: AppType? {
        didSet {
            if NSApp.mainWindow?.contentViewController != nil {
                AppDelegate.rootVC?.currentDocumentTitle = AppManager.shared.nameOfChosenApp
            }
            locationOfChosenApp = nil
        }
    }
    var choseniTunesVersion: iTunesVersion?
    
    var fixerUpdateAvailable: Bool = false
    
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
            case .finalCutPro7:
                return "Final Cut Pro 7"
            case .logicPro9:
                return "Logic Pro 9"
            case .keynote5:
                return "Keynote ’09"
            case .proVideoUpdate:
                return "Pro Applications Update 2010-02".localized()
            default:
                return "Untitled".localized()
            }
        }
    }
    
    var spaceConstrainedNameOfChosenApp: String {
        get {
            switch self.chosenApp {
            case .proVideoUpdate:
                return "Pro Update".localized()
            default:
                return self.nameOfChosenApp
            }
        }
    }

    
    var binaryNameOfChosenApp: String {
        get {
            switch self.chosenApp {
            case .aperture:
                return self.nameOfChosenApp
            case .iphoto:
                return self.nameOfChosenApp
            case .itunes:
                return self.nameOfChosenApp
            case .finalCutPro7:
                return "Final Cut Pro"
            case .logicPro9:
                return "Logic Pro"
            case .keynote5:
                return "Keynote"
            default:
                return self.nameOfChosenApp
            }
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
            case .finalCutPro7:
                return ["7.0.3", "7.0.2", "7.0.1", "7.0"]
            case .logicPro9:
                return ["1700.67", "9.1.8", "9.1.7", "9.1.6", "9.1.5", "9.1.4", "9.1.3", "9.1.2", "9.1.1", "9.1.0", "9.1", "9.0.2", "9.0.1", "9.0.0", "9.0"]
            case .keynote5:
                return ["1170", "5.3", "5.2", "5.1.1", "5.1", "5.0.5", "5.0.4", "5.0.3", "5.0.2", "5.0.1", "5.0"]
            default:
                return []
            }
        }
    }
    
    var userFacingLatestShortVersionOfChosenApp: String {
        get {
            switch self.chosenApp {
            case .aperture:
                return "3.6"
            case .iphoto:
                return "9.6.1"
            case .itunes:
                switch choseniTunesVersion {
                case .darkMode:
                    return "12.9.5"
                case .appStore:
                    return "12.6.5"
                case .coverFlow:
                    return "10.7"
                case .none:
                    return ""
                }
            case .finalCutPro7:
                return "7.0.3"
            case .logicPro9:
                return "9.1.8"
            case .keynote5:
                return "5.3"
            default:
                return ""
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
            case .finalCutPro7:
                return "com.apple.FinalCutPro"
            case .logicPro9:
                return "com.apple.logic.pro"
            case .keynote5:
                return "com.apple.iWork.Keynote"
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
            // These are intentionally left unused
            case .finalCutPro7:
                return "com.apple.FinalCutPro7"
            case .logicPro9:
                return "com.apple.logic.pro9"
            case .keynote5:
                return "com.apple.iWork.Keynote5"
            default:
                return ""
            }
        }
    }
    
    var fixerScriptName: String {
        get {
            switch self.chosenApp {
            case .aperture:
                fatalError()
            case .iphoto:
                fatalError()
            case .itunes:
                fatalError()
            case .finalCutPro7:
                return "GeneralFixerScript"
            case .logicPro9:
                return "GeneralFixerScript"
            case .keynote5:
                return "KeynoteScript"
            default:
                fatalError()
            }
        }
    }
    
    var fixerFrameworkName: String {
        get {
            switch self.chosenApp {
            case .aperture:
                return "ApertureFixer"
            case .iphoto:
                return "ApertureFixer"
            case .itunes:
                return ""
            case .finalCutPro7:
                return "VideoFixer"
            case .logicPro9:
                return "VideoFixer"
            case .keynote5:
                return "KeynoteFixer"
            default:
                fatalError()
            }
        }
    }

    var fixerFrameworkSubPath: String {
        get {
            return "Contents/Frameworks/\(self.fixerFrameworkName).framework"
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
            case .finalCutPro7:
                return "7.0.4"
            case .logicPro9:
                return "1700.68"
            case .keynote5:
                return "1171"
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
            case .keynote5:
                return NSImage(named: "iwork_stage2")
            case .finalCutPro7:
                return NSImage(named: "iwork_stage2")
            case .logicPro9:
                return NSImage(named: "iwork_stage2")
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
            case .keynote5:
                return NSImage(named: "iwork_stage1")
            case .finalCutPro7:
                return NSImage(named: "fcp7_stage1")
            case .logicPro9:
                return NSImage(named: "fcp7_stage1")
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
            case .finalCutPro7:
                return NSImage(named: "final7_cartoon")
            case .logicPro9:
                return NSImage(named: "logic9_cartoon")
            case .keynote5:
                return NSImage(named: "keynote5_cartoon")
            case .proVideoUpdate:
                return NSImage(named: "fcpstudio_cartoon")
            default:
                return nil
            }
        }
    }
    
    var behindTheScenesOfChosenApp: String? {
        get {
            switch self.chosenApp {
            case .aperture:
                return apertureDive
            case .iphoto:
                return iPhotoDive
            case .itunes:
                switch choseniTunesVersion {
                case .darkMode:
                    return iTunes129Dive
                case .appStore:
                    return iTunes126Dive
                case .coverFlow:
                    return iTunes107Dive
                case .none:
                    return nil
                }
            default:
                return sourcePage
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
    
    var presentTenseActionOfChosenApp: String {
        get {
            switch self.chosenApp {
            case .itunes:
                return "install".localized()
            case .keynote5:
                return "fix".localized()
            case .proVideoUpdate:
                return "install".localized()
            default:
                return "unlock".localized()
            }
        }
    }
    
    var mainActionOfChosenApp: String {
        get {
            return String(format: "%@ing".localized(), presentTenseActionOfChosenApp)
        }
    }

    var detailActionOfChosenApp: String {
        get {
            switch self.chosenApp {
            case .itunes:
                return "downloading and installing".localized()
            default:
                return "installing support files for".localized()
            }
        }
    }
    
    var timeEstimateStringOfChosenApp: String {
        get {
            switch self.chosenApp {
            case .itunes:
                switch choseniTunesVersion {
                case .darkMode:
                    return "25 minutes".localized()
                case .appStore:
                    return "10 minutes".localized()
                case .coverFlow:
                    return "10 minutes".localized()
                case .none:
                    return "an hour".localized()
                }
            case .proVideoUpdate:
                return "10 minutes".localized()
            default:
                return "2 minutes".localized()
            }
        }
    }
    
    var notInstalledText: String {
        get {
            let appStoreTemplate = String(format: "If you have previously downloaded %@ from the Mac App Store, download it again from the Purchased list.".localized(), nameOfChosenApp)
            let dvdTemplate = String(format: "\n\nIf you have a DVD installer for %@, insert the DVD and install it. If you don't have a DVD installer, You may be able to purchase a boxed copy of %@ on eBay. \n\nIf your Mac doesn't have a DVD drive, you can try to create, locate, or download a DMG installer of %@, and install %@ through the DMG installer.".localized(), nameOfChosenApp, nameOfChosenApp, nameOfChosenApp, nameOfChosenApp)

            switch self.chosenApp {
            case .aperture:
                return appStoreTemplate
            case .iphoto:
                return appStoreTemplate
            case .itunes:
                return ""
            case .finalCutPro7:
                return dvdTemplate
            case .logicPro9:
                return "\(dvdTemplate) \n\n\(appStoreTemplate)"
            case .keynote5:
                return "\n\nYou can download and install iWork ’09, which includes Keynote ’09, from The Internet Archive.".localized()
            default:
                return ""
            }
        }
    }
    
    var notInstalledActionText: String {
        get {
            let appStoreTemplate = "Open Mac App Store".localized()
            let dvdTemplate = "Shop DVD on eBay".localized()

            switch self.chosenApp {
            case .aperture:
                return appStoreTemplate
            case .iphoto:
                return appStoreTemplate
            case .itunes:
                return ""
            case .finalCutPro7:
                return dvdTemplate
            case .logicPro9:
                return dvdTemplate
            case .keynote5:
                return "Download iWork ’09".localized()
            default:
                return ""
            }
        }
    }

    var appKnownIssuesText: String? {
        get {
            switch self.chosenApp {
            case .aperture:
                return "If your RAW photos show up as “Unsupported Image Format”, open the “Photos” menu, click on “Reprocess original…”, and reprocess all photos. You may need to reprocess all photos twice.".localized()
            case .iphoto:
                return "All iPhoto features should be available except for playing videos, exporting slideshows, Photo Stream, and iCloud Photo Sharing.".localized()
            case .itunes:
                switch choseniTunesVersion {
                case .darkMode:
                    return nil
                case .appStore:
                    return "Thumbnails of download apps may appear distorted. Use iTunes 12.9.5 or Finder to back up instead.".localized()
                case .coverFlow:
                    return "iTunes may prompt “A required iTunes component is not installed. Please reinstall iTunes (-42401).” There is no need to reinstall iTunes.".localized()
                case .none:
                    return nil
                }
            case .finalCutPro7:
                return "Some serial numbers for Final Cut Pro 7.0 do not work with Final Cut Pro 7.0.3. If you are asked to register again, you need to find and enter a serial number compatible with Final Cut Pro 7.0.3.".localized()
            case .logicPro9:
                return nil
            case .keynote5:
                return nil
            default:
                return nil
            }
        }
    }

    func acquireSelectedApp() {
        switch self.chosenApp {
        case .aperture:
            openMacAppStore()
        case .iphoto:
            openMacAppStore()
        case .itunes:
            return
        case .finalCutPro7:
            AppDelegate.current.safelyOpenURL(AppManager.shared.fcpDVD)
        case .logicPro9:
            AppDelegate.current.safelyOpenURL(AppManager.shared.logicDVD)
        case .keynote5:
            AppDelegate.current.safelyOpenURL(AppManager.shared.iWork09DVD)
        default:
            openMacAppStore()
        }
    }
    
    func updateSelectedApp() {
        switch self.chosenApp {
        case .aperture:
            AppDelegate.openKBArticle("203106")
        case .iphoto:
            AppDelegate.openKBArticle("203106")
        case .itunes:
            return
        case .finalCutPro7:
            if (AppManager.shared.locationOfChosenApp != nil) {
                // Save the location and don't let the setter reset it
                let cachedLocation = AppManager.shared.locationOfChosenApp
                AppManager.shared.chosenApp = .proVideoUpdate
                AppManager.shared.locationOfChosenApp = cachedLocation

                AppDelegate.rootVC?.navigationController.pushViewController(AuthenticateViewController.instantiate(), animated: true)
            } else {
                AppDelegate.showTextSheet(title: "You need to install Final Cut Pro 7 first.".localized(), text: String(format: "After you have already installed Final Cut Pro 7 from a DVD installer or DMG image, Retroactive can download and update Final Cut Pro 7 from version 7.0 to 7.0.3, and unlock it to be compatible with %@.".localized(), ProcessInfo.versionName))
            }
        case .logicPro9:
            AppDelegate.current.safelyOpenURL(AppManager.shared.logicUpdate)
        case .keynote5:
            AppDelegate.current.safelyOpenURL(AppManager.shared.iWork09Update)
        default:
            return
        }
    }
    
    func openMacAppStore() {
        if #available(OSX 10.15, *) {
            NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/System/Applications/App Store.app"), configuration: .init(), completionHandler: nil)
        } else {
            NSWorkspace.shared.launchApplication("App Store")
        }
    }
    
    var purposeString: String {
        get {
            if chosenApp == .proVideoUpdate {
                return ""
            }
            return " to run on {systemName}".localized()
        }
    }

    static func replaceTokenFor(_ string: String) -> String {
        return string.replacingOccurrences(of: purposeToken, with: AppManager.shared.purposeString)
            .replacingOccurrences(of: placeholderToken, with: AppManager.shared.nameOfChosenApp)
            .replacingOccurrences(of: timeToken, with: AppManager.shared.timeEstimateStringOfChosenApp)
            .replacingOccurrences(of: mainActionToken, with: AppManager.shared.mainActionOfChosenApp)
            .replacingOccurrences(of: actionPresentTenseToken, with: AppManager.shared.presentTenseActionOfChosenApp)
            .replacingOccurrences(of: actionDetailToken, with: AppManager.shared.detailActionOfChosenApp)
            .replacingOccurrences(of: systemNameToken, with: ProcessInfo.versionName)
    }
    
}
