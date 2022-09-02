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
    case pages4
    case numbers2
    case xcode
    
    case proVideoUpdate
}

enum iTunesVersion {
    case darkMode
    case appStore
    case configurator
    case classicTheme
    case coverFlow
}

enum VirtualMachine {
    case parallels
    case vmware
    case generic
}

let kCFBundleIdentifier = "CFBundleIdentifier"
let kCFBundleVersion = "CFBundleVersion"
let kCFBundleShortVersionString = "CFBundleShortVersionString"
let kLSMinimumSystemVersion = "LSMinimumSystemVersion"

let placeholderToken = "{name}"
let timeToken = "{timeEstimate}"
let actionDetailToken = "{actionS}"
let mainActionToken = "{actionM}"
let systemNameToken = "{systemName}"
let purposeToken = "{purpose}"
let actionPresentTenseToken = "{actionPR}"

let kCustomSettingsPath = "/Library/Application Support/Final Cut Pro System Support/Custom Settings"
let kFCP7EasySetupPath = "/Applications/Final Cut Pro Additional Easy Setups"
let kFCP7EasySetupPathLocalizedPath = "/Applications/Final Cut Pro Additional Easy Setups.localized"
let kXcodeGlobalPreferencePath = "/Library/Preferences/com.apple.dt.Xcode.plist"
let kXcodeIDELastGMLicenseAgreedToKey = "IDELastGMLicenseAgreedTo"
let kXcodeIDELastBetaLicenseAgreedTo = "IDELastBetaLicenseAgreedTo"
let kXcodeIDEXcodeVersionForAgreedToGMLicense = "IDEXcodeVersionForAgreedToGMLicense"
let kXcodeIDEXcodeVersionForAgreedToBetaLicense = "IDEXcodeVersionForAgreedToBetaLicense"
let kXcodeMaxEAString = "EA9999"
let kXcodeMaxVersionString = "99.9"

let lastHWForMojave = ["iMac19,2", "iMacPro1,1", "MacBook10,1", "MacBookAir8,2", "MacBookPro15,4", "Macmini8,1", "MacPro6,1"]

let tempDir = "/tmp"

let iTunesBundleID = "com.apple.iTunes"

let oneNewLine = "\n"
let twoNewLines = "\n\n"

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

extension String {
    var machineType: String? {
        return self.components(separatedBy: .decimalDigits).first
    }

    var machineFullNumber: String? {
        if let modelType = self.machineType {
            return self.replacingOccurrences(of: modelType, with: "")
        }
        return nil
    }

    var machineGenerationNumber: Int? {
        if let fullNumber = self.machineFullNumber {
            let seperated = fullNumber.components(separatedBy: ",")
            if seperated.count > 1 {
                if let intGen = Int(seperated[0]) {
                    return intGen
                }
            }
        }
        return nil
    }

    var machineSubmodelNumber: Int? {
        if let fullNumber = self.machineFullNumber {
            let seperated = fullNumber.components(separatedBy: ",")
            if seperated.count > 1 {
                if let intSub = Int(seperated[1]) {
                    return intSub
                }
            }
        }
        return nil
    }
    
    func isNewerThan(otherMachine: String) -> Bool {
        if (self.machineType == otherMachine.machineType) {
            if let thisGen = self.machineGenerationNumber, let thisSub = self.machineSubmodelNumber, let otherGen = otherMachine.machineGenerationNumber, let otherSub = otherMachine.machineSubmodelNumber {
                if thisGen > otherGen {
                    return true
                }
                if thisGen == otherGen && thisSub > otherSub {
                    return true
                }
            }
        }
        return false
    }
    
    var normalizediTunesVersionString: String {
        let separated = self.components(separatedBy: ".")
        var normalized = self
        if separated.count > 3 {
            normalized = separated.prefix(3).joined(separator: ".")
        }
        // Without stripping trailing Null characters, "11.4\0\0\0\0" will be considered "newer" than "11.4".
        normalized = normalized.replacingOccurrences(of: "\0", with: "")
        return normalized
    }
    
    func iTunesIsNewerThan(otheriTunes: String) -> Bool {
        return self.normalizediTunesVersionString.compare(otheriTunes, options: .numeric) == .orderedDescending
    }
    
    func osIsAtLeast(otherOS: String) -> Bool {
        return self.compare(otherOS, options: .numeric) != .orderedAscending
    }
}

class AppManager: NSObject {
    
    static let shared = AppManager()
    
    var willRelaunchSoon = false
    
    var allowPatchingAgain = false

    private(set) public var isSIPEnabled: Bool = true

    private override init() {
        super.init()
        if let path = Bundle.main.path(forResource: "SupportPath", ofType: "plist"),
            let loaded = NSDictionary(contentsOfFile: path) as? Dictionary<String, Any> {
            self.configurationDictionary = loaded
        }
        
        self.checkForConfigurationUpdates()

        let sipStatus = Process.runNonAdminTaskWithOutput(toolPath: "/usr/bin/csrutil", arguments: ["status"])
        isSIPEnabled = !sipStatus.lowercased().contains("disabled")
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
    
    var isCurrentTimeZoneInternetConstrained: Bool {
        let localTimeZoneAbbreviation = TimeZone.current.identifier
        let constrained = localTimeZoneAbbreviation == "Asia/Shanghai" || localTimeZoneAbbreviation == "Asia/Chongqing"
        print("Timezone is \(localTimeZoneAbbreviation), constrained: \(constrained)")
        return constrained
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

    var iTunes114Dive: String? {
        return configurationDictionary?["iTunes114Dive"] as? String
    }

    var iTunes107Dive: String? {
        return configurationDictionary?["iTunes107Dive"] as? String
    }

    var iWork09DVD: String? {
        if isCurrentTimeZoneInternetConstrained {
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
    
    var xcode11URL: String? {
        // Intentionally Kept the Xcode114URL key for backwards compatibility
        return configurationDictionary?["Xcode114URL"] as? String
    }

    var configuratorURL: String? {
        return configurationDictionary?["ConfiguratorURL"] as? String
    }
    
    var marginBetweenApps: CGFloat {
        if osAtLeastCatalina {
            return 54
        }
        return 43;
    }

    var supportedApps: [AppType] {
        if osAtLeastCatalina {
            return [.aperture, .iphoto, .itunes]
        }
        if osAtLeastMojave {
            return [.finalCutPro7, .logicPro9, .xcode, .keynote5, .pages4, .numbers2]
        }
        if osAtLeastHighSierra {
            return [.finalCutPro7, .logicPro9, .keynote5, .pages4, .numbers2]
        }
        return []
    }
    
    var getStartedSubTitle: String {
        if osAtLeastCatalina {
            return "Unlock Aperture and iPhoto, or install iTunes.".localized()
        }
        if osAtLeastMojave {
            return "Unlock Final Cut Pro 7, Logic Pro 9, Xcode 11.7, and fix iWork ’09.".localized()
        }
        if osAtLeastHighSierra {
            return "Unlock Final Cut Pro 7 and Logic Pro 9, or fix iWork ’09.".localized()
        }

        return ""
    }
    
    var otherOSSubtitle: String {
        if osAtLeastCatalina {
            var otherOSHint = "Retroactive can also unlock Final Cut Pro 7, Logic Pro 9, and fix iWork ’09 on macOS Mojave or macOS High Sierra. ".localized()
            otherOSHint += AppManager.shared.platformShippedAfterMojave ? "To get started, find an older Mac released before Late 2019, and install macOS Mojave on that Mac.".localized() : "To get started, install macOS Mojave on a separate volume.".localized()
            return otherOSHint
        }
        if osAtLeastHighSierra {
            return "If you upgrade to macOS Catalina or macOS Big Sur, Final Cut Pro 7, Logic Pro 9, and iWork ’09 will be locked again, and can’t be unlocked. However, Retroactive can still unlock Aperture and iPhoto, or install iTunes on macOS Catalina or macOS Big Sur.".localized()
        }
        return ""
    }
    
    var otherOSImage: NSImage? {
        if osAtLeastCatalina {
            return NSImage(named:"mojave-banner")
        }
        if osAtLeastHighSierra {
            return NSImage(named:"catalina-banner")
        }
        return nil
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
                case .configurator:
                    return self.configuratorURL
                case .classicTheme:
                    return configurationDictionary?["iTunes114URL"] as? String
                case .coverFlow:
                    return configurationDictionary?["iTunes107URL"] as? String
                case .none:
                    return nil
                }
            case .finalCutPro7:
                return nil
            case .logicPro9:
                return nil
            case .keynote5, .pages4, .numbers2:
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
    
    var hasChoseniWork: Bool {
        let chosen = self.chosenApp
        return chosen == .keynote5 || chosen == .pages4 || chosen == .numbers2
    }
    
    var choseniTunesVersion: iTunesVersion?
    
    func removeFCP7PresetsIfNeeded() {
        if chosenApp != .finalCutPro7 {
            return
        }
        do {
            let exists = FileManager.default.fileExists(atPath: kCustomSettingsPath)
            if (!exists) {
                return
            }
            let contents = try FileManager.default.contentsOfDirectory(atPath: kCustomSettingsPath)
            let presets = contents.filter { $0.lowercased().hasSuffix(".fcpre") }
            if (presets.count == 0) {
                print("No presets are left at the custom settings path.")
            }
            if (FileManager.default.fileExists(atPath: kFCP7EasySetupPath)) {
                try FileManager.default.removeItem(atPath: kFCP7EasySetupPath)
            }
            if (FileManager.default.fileExists(atPath: kFCP7EasySetupPathLocalizedPath)) {
                try FileManager.default.removeItem(atPath: kFCP7EasySetupPathLocalizedPath)
            }
        } catch {
            print("Can't determine if custom settings exist \(error)")
        }
    }
    
    func compatibleListContains(shortVersionNumber: String) -> Bool {
        return self._compatibleShortVersionOfChosenApp.contains { (iterateVersionNumber) -> Bool in
            return (iterateVersionNumber == shortVersionNumber)
        }
    }
    
    func hasAlreadyPatchedIDOrVersionNumber(bundleID: String, fullVersionNumber: String, shortVersionNumber: String) -> Bool {
        return bundleID == self.patchedBundleIDOfChosenApp
            || fullVersionNumber == self.patchedVersionStringOfChosenApp
            || (self.patchedBundleIDOfChosenApp == nil && self.patchedVersionStringOfChosenApp == nil && compatibleListContains(shortVersionNumber: shortVersionNumber))
    }
    
    enum UnderscoreState {
        case notNeeded
        case neededButNotFound
        case smallUnderscoreNextToBinary // ['AppName_' is a script, 'AppName' is the binary]
        case largeUnderscoreNextToBinary // ['AppName_' is a newer binary, 'AppName is an older binary']
    }
    
    func underscoreState(foundAppPath: String) -> UnderscoreState {
        let appMacOSPath = "\(foundAppPath)/Contents/MacOS"
        let appBinaryPath = "\(appMacOSPath)/\(AppManager.shared.binaryNameOfChosenApp)"
        let macAppBinaryPathUnderscore = "\(appBinaryPath)_"

        switch chosenApp {
        case .finalCutPro7, .logicPro9, .pages4, .numbers2, .keynote5:
            let exists = FileManager.default.fileExists(atPath: macAppBinaryPathUnderscore)
            if (exists) {
                do {
                    if let fileSize = try FileManager.default.attributesOfItem(atPath: appBinaryPath)[.size] as? UInt64 {
                        print("file size of non underscore is \(fileSize) bytes")
                        if (fileSize < 1000) {
                            print("The non underscored file is a fixer, no mach-o binary is smaller than 1000 bytes.")
                            return .smallUnderscoreNextToBinary
                        } else {
                            print("The non underscored file probably isn't a fixer because it exceeds 1000 bytes, it probably got there with an app update.")
                            return .largeUnderscoreNextToBinary
                        }
                    }
                } catch {
                    print("Can't determine file size, \(error)")
                }
            }
            return hasChoseniWork ? .notNeeded : .neededButNotFound
        default:
            return .notNeeded
        }
    }
    
    func needsProResCodecRepair() -> Bool {
        return AppManager.shared.chosenApp == .finalCutPro7 && !FileManager.default.fileExists(atPath: "/Library/QuickTime/AppleProResCodec.component/Contents/MacOS/AppleProResCodec")
    }
    
    func hasAlreadyAppliedOrDoesNotRequireFixer(foundAppPath: String) -> Bool {
        switch chosenApp {
        case .aperture, .iphoto, .finalCutPro7, .logicPro9, .pages4, .numbers2, .keynote5:
            if (chosenApp == .aperture || chosenApp == .iphoto) && osAtLeastBigSur && !FileManager.default.fileExists(atPath: "\(foundAppPath)/Contents/Frameworks/AppKit.framework") {
                return false
            }
            if (chosenApp == .iphoto && osAtLeastMontereyE && !FileManager.default.fileExists(atPath: "\(foundAppPath)/Contents/Frameworks/Python.framework")) {
                return false
            }
            if underscoreState(foundAppPath: foundAppPath) == .neededButNotFound {
                return false
            }
            if needsProResCodecRepair() {
                return false
            }
            if chosenApp == .logicPro9 && FileManager.default.fileExists(atPath: "\(foundAppPath)/Contents/Frameworks/MobileDevice.framework") == false {
                return false
            }
            let existingFixerPath = "\(foundAppPath)/\(AppManager.shared.fixerFrameworkSubPath)"
            if let existingFixerBundle = Bundle.init(path: existingFixerPath),
                let existingFixerVersion = existingFixerBundle.cfBundleVersionInt,
                let resourcePath = Bundle.main.resourcePath {
                let fixerResourcePath = "\(resourcePath)/\(AppManager.shared.fixerFrameworkName)/Resources/Info.plist"
                if let loadedFixerInfoPlist = NSDictionary(contentsOfFile: fixerResourcePath) as? Dictionary<String, Any>,
                    let bundledFixerVersionString = loadedFixerInfoPlist[kCFBundleVersion] as? String, let bundledFixerVersion = Int(bundledFixerVersionString) {
                    if (existingFixerVersion >= bundledFixerVersion) {
                        return true
                    }
                }
            }
            return false
        case .xcode:
            let appBundle = Bundle(path: foundAppPath)
            if let minSysVersionString = appBundle?.object(forInfoDictionaryKey: kLSMinimumSystemVersion) as? String {
                print("Xcode min OS version: \(minSysVersionString), current OS version: \(ProcessInfo.osVersionNumberString)")
                if (ProcessInfo.osVersionNumberString.osIsAtLeast(otherOS: minSysVersionString)) {
                    print("Current OS is at least Xcode min OS")
                    if let xcodeGlobalPrefInfoPlist = NSDictionary(contentsOfFile: kXcodeGlobalPreferencePath) as? Dictionary<String, Any>,
                        let gmLicense = xcodeGlobalPrefInfoPlist[kXcodeIDELastGMLicenseAgreedToKey] as? String,
                        let betaLicense = xcodeGlobalPrefInfoPlist[kXcodeIDELastBetaLicenseAgreedTo] as? String,
                        let gmVersion = xcodeGlobalPrefInfoPlist[kXcodeIDEXcodeVersionForAgreedToGMLicense] as? String,
                        let betaVersion = xcodeGlobalPrefInfoPlist[kXcodeIDEXcodeVersionForAgreedToBetaLicense] as? String {
                        if (gmLicense == kXcodeMaxEAString && betaLicense == kXcodeMaxEAString && gmVersion == kXcodeMaxVersionString && betaVersion == kXcodeMaxVersionString) {
                            return true
                        }
                    }
                }
            }
            return false
        default:
            print("\(String(describing: chosenApp)) doesn't need a fixer, so hasUpToDateFixer always returns true")
            return true
        }
    }
    
    var locationOfChosenApp: String?
    var nameOfChosenApp: String {
        return nameForAppType(chosenApp)
    }
    
    func nameForAppType(_ appType: AppType?) -> String {
        switch appType {
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
        case .xcode:
            return "Xcode 11.7".localized()
        case .keynote5:
            return "Keynote ’09"
        case .pages4:
            return "Pages ’09"
        case .numbers2:
            return "Numbers ’09"
        case .proVideoUpdate:
            return "Pro Applications Update 2010-02".localized()
        default:
            return "Untitled".localized()
        }
    }
    
    var spaceConstrainedNameOfChosenApp: String {
        get {
            switch self.chosenApp {
            case .finalCutPro7:
                return "Final Cut Pro"
            case .logicPro9:
                return "Logic Pro"
            case .xcode:
                return "Xcode"
            case .proVideoUpdate:
                return "Pro Update".localized()
            case .keynote5:
                return "Keynote"
            case .pages4:
                return "Pages"
            case .numbers2:
                return "Numbers"
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
            case .xcode:
                return "Xcode"
            case .keynote5:
                return "Keynote"
            case .pages4:
                return "Pages"
            case .numbers2:
                return "Numbers"
            default:
                return self.nameOfChosenApp
            }
        }
    }
    
    private var _compatibleLongVersionOfChosenApp: [String] {
        switch self.chosenApp {
        case .logicPro9:
            return ["1700.67"]
        case .keynote5:
            return []
        case .pages4:
            return []
        case .numbers2:
            return []
        default:
            return []
        }
    }

    private var _compatibleShortVersionOfChosenApp: [String] {
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
            case .configurator:
                return ["999.99.99"]
            case .classicTheme:
                return ["11.4"]
            case .coverFlow:
                return ["10.7"]
            case .none:
                return []
            }
        case .finalCutPro7:
            return ["7.0.3", "7.0.2", "7.0.1", "7.0"]
        case .logicPro9:
            return ["9.1.8", "9.1.7", "9.1.6", "9.1.5", "9.1.4", "9.1.3", "9.1.2", "9.1.1", "9.1.0", "9.1", "9.0.2", "9.0.1", "9.0.0", "9.0"]
        case .xcode:
            return ["11.7", "11.6", "11.5", "11.4.1", "11.4"]
        case .keynote5:
            return ["5.3"]
        case .pages4:
            return ["4.3"]
        case .numbers2:
            return ["2.3"]
        default:
            return []
        }
    }

    var compatibleVersionOfChosenApp: [String] {
        return _compatibleLongVersionOfChosenApp + _compatibleShortVersionOfChosenApp
    }
    
    func versionisTooNewForPatching(foundOnDiskShortVersion: String) -> Bool {
        if foundOnDiskShortVersion == patchedVersionStringOfChosenApp { return false }
        guard let compatibleVersion = _compatibleShortVersionOfChosenApp.first else { return false }
        let result = foundOnDiskShortVersion.compare(compatibleVersion, options: .numeric, range: nil, locale: nil)
        return result == .orderedDescending
    }
    
    var oldestShortVersionRequiringMinorUpdate: String? {
        switch self.chosenApp {
        case .keynote5:
            return "5.0"
        case .pages4:
            return "4.0"
        case .numbers2:
            return "2.0"
        default:
            return nil
        }
    }
    
    func versionOnlyRequiresMinorUpdateToBeCompatible(foundOnDiskShortVersion: String) -> Bool {
        if versionisTooNewForPatching(foundOnDiskShortVersion: foundOnDiskShortVersion) { return false }
        guard let maxCompatibleVersion = _compatibleShortVersionOfChosenApp.first else { return false }
        guard let oldestUpdateCapable = oldestShortVersionRequiringMinorUpdate else { return false }
        let initialComparison = oldestUpdateCapable.compare(foundOnDiskShortVersion, options: .numeric, range: nil, locale: nil)
        return (initialComparison == .orderedAscending || initialComparison == .orderedSame)
            && foundOnDiskShortVersion.compare(maxCompatibleVersion, options: .numeric, range: nil, locale: nil) == .orderedAscending
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
                case .configurator:
                    return ""
                case .classicTheme:
                    return "11.4"
                case .coverFlow:
                    return "10.7"
                case .none:
                    return ""
                }
            case .finalCutPro7:
                return "7.0.3"
            case .logicPro9:
                return "9.1.8"
            case .xcode:
                return "11.7"
            case .keynote5:
                return "5.3"
            case .pages4:
                return "4.3"
            case .numbers2:
                return "2.3"
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
                // This is intentionally the launcher's bundle ID
                return "com.launcher.iTunes"
            case .finalCutPro7:
                return "com.apple.FinalCutPro"
            case .logicPro9:
                return "com.apple.logic.pro"
            case .xcode:
                return "com.apple.dt.Xcode"
            case .keynote5:
                return "com.apple.iWork.Keynote"
            case .pages4:
                return "com.apple.iWork.Pages"
            case .numbers2:
                return "com.apple.iWork.Numbers"
            default:
                return ""
            }
        }
    }
    
    var patchedBundleIDOfChosenApp: String? {
        get {
            switch self.chosenApp {
            case .aperture:
                return "com.apple.Aperture3"
            case .iphoto:
                return "com.apple.iPhoto9"
            case .itunes:
                return nil
            case .xcode:
                return nil
            case .finalCutPro7:
                return nil
            case .logicPro9:
                return nil
            case .keynote5, .pages4, .numbers2:
                return nil
            default:
                return nil
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
                if self.likelyInVirtualMachine {
                    print("In VM and FCP7, using VM fixer script")
                    return "VMFCPFixerScript"
                } else {
                    print("Normal FCP7, using general fixer script")
                    return "GeneralFixerScript"
                }
            case .logicPro9:
                return "GeneralFixerScript"
            case .keynote5, .pages4, .numbers2:
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
                return "OriginFixer"
            case .finalCutPro7:
                return "VideoFixer"
            case .logicPro9:
                return "VideoFixer"
            case .keynote5, .pages4, .numbers2:
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

    var fixerBinaryRelativeToExecutablePath: String {
        return "@executable_path/../Frameworks/\(fixerFrameworkName).framework/Versions/A/\(fixerFrameworkName)"
    }
    
    var patchedVersionStringOfChosenApp: String? {
        switch self.chosenApp {
        case .aperture, .iphoto:
            return nil
        case .itunes:
            switch choseniTunesVersion {
            case .darkMode:
                return "12.9.5"
            case .appStore:
                return "12.6.5"
            case .classicTheme:
                return "11.4"
            case .coverFlow:
                return "10.7"
            case .configurator, .none:
                return nil
            }
        case .finalCutPro7:
            return "7.0.4"
        case .logicPro9:
            return "1700.68"
        case .xcode:
            return nil
        case .keynote5:
            return "1171"
        case .pages4:
            return "1049"
        case .numbers2:
            return "555"
        default:
            return nil
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
            case .keynote5, .pages4, .numbers2:
                return NSImage(named: "iwork_stage2")
            case .finalCutPro7:
                return NSImage(named: "iwork_stage2")
            case .logicPro9:
                return NSImage(named: "iwork_stage2")
            case .xcode:
                return NSImage(named: "xcode_stage2")
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
            case .keynote5, .pages4, .numbers2:
                return NSImage(named: "iwork_stage1")
            case .finalCutPro7:
                return NSImage(named: "fcp7_stage1")
            case .logicPro9:
                return NSImage(named: "fcp7_stage1")
            case .xcode:
                return NSImage(named: "xcode_stage1")
            default:
                return nil
            }
        }
    }
    
    var cartoonIcon: NSImage? {
        return cartoonIconForAppType(chosenApp)
    }
    
    func cartoonIconForAppType(_ appType: AppType?) -> NSImage? {
        switch appType {
        case .aperture:
            return NSImage(named: "aperture_cartoon")
        case .iphoto:
            return NSImage(named: "iphoto_cartoon")
        case .itunes:
            return NSImage(named: "itunes_cartoon")
        case .finalCutPro7:
            return NSImage(named: "final7_cartoon")
        case .xcode:
            return NSImage(named: "xcode_cartoon")
        case .logicPro9:
            return NSImage(named: "logic9_cartoon")
        case .keynote5:
            return NSImage(named: "keynote5_cartoon")
        case .pages4:
            return NSImage(named: "pages4_cartoon")
        case .numbers2:
            return NSImage(named: "numbers2_cartoon")
        case .proVideoUpdate:
            return NSImage(named: "fcpstudio_cartoon")
        default:
            return nil
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
                case .configurator:
                    return configuratorURL
                case .classicTheme:
                    return iTunes114Dive
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
        return presentTenseActionForAppType(chosenApp)
    }
    
    func presentTenseActionForAppType(_ appType: AppType?) -> String {
        switch appType {
        case .itunes:
            return "install".localized()
        case .keynote5, .pages4, .numbers2:
            return "fix".localized()
        case .proVideoUpdate:
            return "install".localized()
        default:
            return "unlock".localized()
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
                case .appStore, .classicTheme, .coverFlow:
                    return "10 minutes".localized()
                case .configurator:
                    return "Not Applicable"
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
            let dvdTemplate = twoNewLines
                + String(format: "If you have a DVD installer for %@, insert the DVD and install it. If you don't have a DVD installer, You may be able to purchase a boxed copy of %@ on eBay.".localized(), nameOfChosenApp, nameOfChosenApp)
                + twoNewLines
                + String(format:"If your Mac doesn't have a DVD drive, you can try to create, locate, or download a DMG installer of %@, and install %@ through the DMG installer.".localized(), nameOfChosenApp, nameOfChosenApp)

            switch self.chosenApp {
            case .aperture:
                return appStoreTemplate
            case .iphoto:
                return appStoreTemplate
            case .itunes:
                return ""
            case .finalCutPro7:
                return dvdTemplate + twoNewLines + "If you have already installed Final Cut Pro X on your Mac, the Final Cut Pro 7 package will be grayed out in the Final Cut Studio 3 installer. You need to rename “Final Cut Pro.app” into “Final Cut Pro X.app”, or move it into a different folder.".localized()
            case .logicPro9:
                return dvdTemplate + twoNewLines + appStoreTemplate
            case .keynote5, .pages4, .numbers2:
                return twoNewLines + String(format: "You can download and install iWork ’09, which includes %@, from The Internet Archive.".localized(), nameOfChosenApp)
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
            case .xcode:
                return String(format: "Download %@".localized(), nameOfChosenApp)
            case .keynote5, .pages4, .numbers2:
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
                    return "If iTunes 12.6.5 can't back up your device, try to use iTunes 12.9.5 or Finder instead.".localized()
                case .configurator:
                    return nil
                case .classicTheme:
                    return nil
                case .coverFlow:
                    return nil
                case .none:
                    return nil
                }
            case .finalCutPro7:
                return "Some serial numbers for Final Cut Pro 7.0 do not work with Final Cut Pro 7.0.3. If you are asked to register again, you need to find and enter a serial number compatible with Final Cut Pro 7.0.3.".localized()
            case .logicPro9:
                return nil
            case .keynote5, .pages4, .numbers2:
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
        case .xcode:
            AppDelegate.current.safelyOpenURL(AppManager.shared.xcode11URL)
        case .keynote5, .pages4, .numbers2:
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

                AppDelegate.skipCheck_pushAuthenticateVC()
            } else {
                AppDelegate.showTextSheet(title: "You need to install Final Cut Pro 7 first.".localized(), text: String(format: "After you have already installed Final Cut Pro 7 from a DVD installer or DMG image, Retroactive can download and update Final Cut Pro 7 from version 7.0 to 7.0.3, and unlock it to be compatible with %@.".localized(), ProcessInfo.versionName))
            }
        case .logicPro9:
            AppDelegate.current.safelyOpenURL(AppManager.shared.logicUpdate)
        case .xcode:
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: ("~/Downloads" as NSString).expandingTildeInPath)
        case .keynote5, .pages4, .numbers2:
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

    var platform: String {
        get {
            var size = 0
            sysctlbyname("hw.model", nil, &size, nil, 0)
            var machine = [CChar](repeating: 0,  count: size)
            sysctlbyname("hw.model", &machine, &size, nil, 0)
            return String(cString: machine)
        }
    }
    
    var platformShippedAfterMojave: Bool {
        let hwIdentifier = self.platform
        var machineTypeMatchedAtLeastOnce = false
        for mac in lastHWForMojave {
            if hwIdentifier.isNewerThan(otherMachine: mac) {
                return true
            }
            if hwIdentifier.machineType == mac.machineType {
                machineTypeMatchedAtLeastOnce = true
            }
        }
        return !machineTypeMatchedAtLeastOnce
    }

    var chosenAppHasLimitedFeaturesInVirtualMachine: Bool {
        get {
            switch self.chosenApp {
            case .aperture:
                return true
            case .iphoto:
                return true
            case .proVideoUpdate:
                fallthrough
            case .finalCutPro7:
                return true
            case .keynote5, .pages4, .numbers2:
                return true
            case .logicPro9:
                return false
            case .itunes:
                return false
            default:
                return false
            }
        }
    }

    var currentVM: VirtualMachine {
        let platform = self.platform
        if (platform.contains("VMware")) {
            return .vmware
        }
        if (platform.contains("Parallels")) {
            return .parallels
        }
        return .generic
    }

    var currentVMName: String {
        switch self.currentVM {
        case .vmware:
            return "VMware Fusion".localized()
        case .parallels:
            return "Parallels Desktop".localized()
        case .generic:
            fallthrough
        default:
            return "a virtual machine".localized()
        }
    }

    var currentVMImage: NSImage? {
        if (self.chosenApp == .itunes) {
            return NSImage(named: "configurator")
        }

        switch self.currentVM {
        case .vmware:
            return NSImage(named: "vmware")
        case .parallels:
            return NSImage(named: "parallels")
        case .generic:
            fallthrough
        default:
            return NSImage(named: "generic-vm")
        }
    }

    var chosenAppVMTitle: String {
        get {
            let basicFormat = "%1$@ in %2$@".localized()
            switch self.chosenApp {
            case .aperture:
                return String(format: basicFormat, "Aperture has reduced functionality".localized(), self.currentVMName)
            case .iphoto:
                return String(format: basicFormat, "iPhoto has reduced functionality".localized(), self.currentVMName)
            case .proVideoUpdate:
                fallthrough
            case .finalCutPro7:
                return String(format: basicFormat, "Final Cut Pro 7 only supports XML exports".localized(), self.currentVMName)
            case .keynote5:
                return String(format: basicFormat, "Keynote ’09 only supports PPTX exports".localized(), self.currentVMName)
            case .pages4:
                return String(format: basicFormat, "Pages ’09 only supports DOCX exports".localized(), self.currentVMName)
            case .numbers2:
                return String(format: basicFormat, "Numbers ’09 only supports XLSX exports".localized(), self.currentVMName)
            case .logicPro9:
                return ""
            case .itunes:
                return "Use Apple Configurator 2 to download iOS apps".localized()
            default:
                return ""
            }
        }
    }

    var chosenAppVMDescription: String {
        get {
            switch self.chosenApp {
            case .aperture:
                return "You can open and organize your Aperture library, or export edited images. To use editing features such as image preview, adjustments, brushes, and effects, run Retroactive on a real Mac.".localized()
            case .iphoto:
                return "You can open and organize your iPhoto library, or export edited images. To use editing features such as image preview, Quick Fixes, effects, and adjustments, run Retroactive on a real Mac.".localized()
            case .proVideoUpdate:
                fallthrough
            case .finalCutPro7:
                return "You can export existing projects into XML files, so that SendToX, DaVinci Resolve, Media Composer, and Premiere Pro can open them. To use editing features such as timeline and preview, run Retroactive on a real Mac.".localized()
            case .keynote5:
                return "You can export existing Keynote presentations into PowerPoint presentations. To view and edit your Keynote slides, animations, and transitions, run Retroactive on a real Mac.".localized()
            case .pages4:
                return "You can export existing Pages documents into Word documents. To view and edit your Pages documents, run Retroactive on a real Mac.".localized()
            case .numbers2:
                return "You can export existing Numbers spreadsheets into Excel spreadsheets. To view and edit your Numbers spreadsheets, run Retroactive on a real Mac.".localized()
            case .logicPro9:
                return ""
            case .itunes:
                return "Starting from April 2020, you'll need to use Apple Configurator 2 to download iOS apps on your Mac.".localized()
            default:
                return ""
            }
        }
    }
    
    private var _previouslyDetectedInVM: Bool = false

    var likelyInVirtualMachine: Bool {
        get {
            if _previouslyDetectedInVM == true {
                print("previously already detected in VM, skipping the check")
                return true
            }
            print("main window is \(String(describing: NSApp.mainWindow)), screen is \(String(describing: NSApp.mainWindow?.screen))")
            var window = NSApp.mainWindow
            if (window == nil) {
                let subwindows = NSApp.windows
                print("main window is nil, NSApp.windows are \(subwindows)")
                for subwindow in subwindows {
                    if let validWindow = subwindow as? RetroactiveWindow {
                        window = validWindow
                    }
                }
                if (window == nil && subwindows.count > 0) {
                    window = subwindows[0]
                }
            }
            let deviceDescription = window?.screen?.deviceDescription
            print("device description is \(String(describing: deviceDescription))")
            if let description = deviceDescription {
                print("screen number is \(String(describing: description[NSDeviceDescriptionKey("NSScreenNumber")]))")
                if let screenNumber = description[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
                    let usesOpenGL = CGDisplayUsesOpenGLAcceleration(screenNumber)
                    print("usesOpenGL is \(usesOpenGL)")
                    if CGDisplayUsesOpenGLAcceleration(screenNumber) == 1 {
                        print("OpenGL acceleration present, likely not in virtual machine")
                        return false
                    } else {
                        print("OpenGL acceleration missing, likely in virtual machine")
                        _previouslyDetectedInVM = true
                        return true
                    }
                }
            }
            print("can't find current screen, assuming not in virtual machine")
            return false
        }
    }
    
    private let NATIVE_EXECUTION = Int32(0)
    private let EMULATED_EXECUTION = Int32(1)
    private let UNKNOWN_EXECUTION = -Int32(1)
    private var processIsTranslated: Int32 {
        let key = "sysctl.proc_translated"
        var ret = Int32(0)
        var size: Int = 0
        sysctlbyname(key, nil, &size, nil, 0)
        let result = sysctlbyname(key, &ret, &size, nil, 0)
        if result == -1 {
            if errno == ENOENT {
                return 0
            }
            return -1
        }
        return ret
    }
    
    var isTranslated: Bool {
        return processIsTranslated == EMULATED_EXECUTION
    }
    
    var needsToShowiTunesWorkaround: Bool {
        return self.chosenApp == .itunes && (self.choseniTunesVersion == .appStore || self.choseniTunesVersion == .configurator)
    }

    var needsToShowCatch: Bool {
        return needsToShowiTunesWorkaround || (self.likelyInVirtualMachine && self.chosenAppHasLimitedFeaturesInVirtualMachine)
    }
    
    var iTunesLibraryPath: String? {
        let fallbackStandardPath = ("~/Music/iTunes" as NSString).expandingTildeInPath
        guard let iTunesDefaults = UserDefaults(suiteName: iTunesBundleID) else {
            return fallbackStandardPath
        }
        if let data = iTunesDefaults.data(forKey: "alis:1:iTunes Library Location"),
            let alias = BDAlias(data: data),
            let path = alias.fullPath() {
            return path
        }
        if let bookData = iTunesDefaults.data(forKey: "book:1:iTunes Library Location") {
            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: bookData, bookmarkDataIsStale: &isStale)
                print(url)
                return url.path
            } catch {
                return fallbackStandardPath
            }
        }
        return fallbackStandardPath
    }

    var needsBashAccess: Bool {
        return self.chosenApp == .itunes && !Permission.shared.bashHasFullDiskAccess()
    }
    
    var maximizePhotoAppCompatibility = true

    static func runTask(toolPath: String, arguments: [String], path: String, wait: Bool = true, allowError: Bool = false) -> OSStatus {
        if (AppManager.shared.willRelaunchSoon) {
            return errAuthorizationCanceled
        }

        let priviledgedTask = STPrivilegedTask()
        priviledgedTask.launchPath = toolPath
        priviledgedTask.arguments = arguments
        priviledgedTask.currentDirectoryPath = path
        let err: OSStatus = priviledgedTask.launch()
        if (err != errAuthorizationSuccess) {
            if (err == errAuthorizationCanceled) {
                print("User cancelled")
            } else {
                print("Something went wrong with authorization: %d", err)
                // For error codes, see http://www.opensource.apple.com/source/libsecurity_authorization/libsecurity_authorization-36329/lib/Authorization.h
            }
            if (!allowError) {
                AppManager.relaunchDueToAuthenticationFailure(failure: err)
                return err
            }
        }
        if wait == true {
            priviledgedTask.waitUntilExit()
        }
        let readHandle = priviledgedTask.outputFileHandle
        if let outputData = readHandle?.readDataToEndOfFile(), let outputString = String(data: outputData, encoding: .utf8) {
            print("Output string is \(outputString), terminationStatus is \(priviledgedTask.terminationStatus)")
        }
        return err
    }
    
    static func relaunchDueToAuthenticationFailure(failure: OSStatus) {
        let appName = AppManager.shared.nameOfChosenApp
        let presentTense = AppManager.shared.presentTenseActionOfChosenApp
        UserDefaults.standard.setValue(String(format: "Unable to %@ %@".localized(), presentTense, appName), forKey: kErrorRecoveryTitle)
        UserDefaults.standard.setValue(String(format: "Because Retroactive can't be authenticated, %@ has failed to %@ (Error %d).", appName, presentTense, failure)
            + twoNewLines
            + String(format:"You can try to %@ %@ again.".localized(), presentTense, appName), forKey: kErrorRecoveryText)

        NSApplication.shared.relaunch()
    }

    static func runUnameToPreAuthenticate() -> OSStatus {
        return AppManager.runTask(toolPath: "/usr/bin/uname", arguments: ["-a"], path: tempDir, wait: true, allowError: true)
    }
    
    func retinizeAppForCurrentUser(_ bundleIdentifier: String?) {
        guard let bundleID = bundleIdentifier else {
            return
        }
        var persistentDomain: [String : Any] = [:]
        if let appPersistent = UserDefaults.standard.persistentDomain(forName: bundleID) {
            persistentDomain = appPersistent
        }
        persistentDomain["AppleMagnifiedMode"] = false
        UserDefaults.standard.setPersistentDomain(persistentDomain, forName: bundleID)
        print("Setting AppleMagnifiedMode to false for persistence domain of \(bundleID)")
    }
    
    func retinizeSelectedAppForCurrentUser() {
        switch self.chosenApp {
        case .finalCutPro7, .logicPro9, .keynote5, .pages4, .numbers2:
            retinizeAppForCurrentUser(existingBundleIDOfChosenApp)
        default:
            return
        }
    }

}
