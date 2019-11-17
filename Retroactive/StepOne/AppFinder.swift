//
//  AppFinder.swift
//  Retroactive
//

import Cocoa

let shortBundleVersionKey = "CFBundleShortVersionString"
let bundleVersionKey = "CFBundleVersion"
let fixerFrameworkSubPath = "Contents/Frameworks/ApertureFixer.framework"

class AppFinder: NSObject {
    var query: NSMetadataQuery?
    var comingFromChoiceVC: Bool = false

    static let shared = AppFinder()
    
    private override init() {
    }

    func queryAllInstalledApps() {
        queryAllInstalledApps(shouldPresentAlert: false, claimsToHaveInstalled: false)
    }
    
    func queryAllInstalledApps(shouldPresentAlert: Bool, claimsToHaveInstalled: Bool) {
        query?.stop()
        query = NSMetadataQuery()
        let chosen = AppManager.shared.chosenApp
        if chosen == .itunes || chosen == .finalCutPro7 || chosen == .logicPro9 || chosen == .keynote5 {
            query?.searchScopes = ["/Applications"]
        } else {
            query?.searchScopes = [NSMetadataQueryLocalComputerScope]
        }
        let pred = NSPredicate.init(format: "\(searchContentType) == '\(bundleContentType)' AND \(searchBundleIdentifier) CONTAINS[c] %@", AppManager.shared.existingBundleIDOfChosenApp)
//        let pred = NSPredicate.init(format: "\(searchContentType) == '\(bundleContentType)' AND \(searchDisplayName) CONTAINS[c] %@ AND \(searchBundleIdentifier) CONTAINS[c] %@", AppManager.shared.nameOfChosenApp, AppManager.shared.existingBundleIDOfChosenApp)
        query?.predicate = pred
        query?.start()
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(gatheringProgressChanged), name: NSNotification.Name.NSMetadataQueryGatheringProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(gatheringDataUpdated), name: NSNotification.Name.NSMetadataQueryDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(finishedQueryInstalledApps), name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: nil)
    }
    
    @objc func gatheringProgressChanged(_ notif: NSNotification) {
        print("gatheringProgressChanged")
    }
    
    @objc func gatheringDataUpdated(_ notif: NSNotification) {
        print("gatheringDataUpdated")
    }
    
    @objc func finishedQueryInstalledApps(_ notif: NSNotification) {
        guard let actualQuery = notif.object as? NSMetadataQuery else {
            return
        }
        if actualQuery != query {
            return
        }

        guard let queriedApps = query?.results as? [NSMetadataItem] else {
            self.pushGuidanceVC()
            return
        }
        
        var incompatibleVersion: String?
        
        for result in queriedApps {
            if let bundleID = result.value(forAttribute: searchBundleIdentifier) as? String, let path = result.value(forAttribute: searchPath) as? String {
                let appBundle = Bundle(path: path)
                let versionNumberString: String = appBundle?.object(forInfoDictionaryKey: shortBundleVersionKey) as? String ?? ""
                let fullVersionNumberString: String = appBundle?.object(forInfoDictionaryKey: bundleVersionKey) as? String ?? ""
                if bundleID.elementsEqual(AppManager.shared.patchedBundleIDOfChosenApp) || fullVersionNumberString == AppManager.shared.patchedVersionStringOfChosenApp {
                    print("Found compatible patched app: \(bundleID), \(path)")
                    AppManager.shared.locationOfChosenApp = path
                    
                    if AppManager.shared.chosenApp == .aperture || AppManager.shared.chosenApp == .iphoto {
                        let existingFixerPath = "\(path)/\(fixerFrameworkSubPath)"
                        if let existingFixerBundle = Bundle.init(path: existingFixerPath),
                            let existingFixerVersion = existingFixerBundle.cfBundleVersionInt,
                            let resourcePath = Bundle.main.resourcePath {
                            let fixerResourcePath = "\(resourcePath)/ApertureFixer/Resources/Info.plist"
                            if let loadedFixerInfoPlist = NSDictionary(contentsOfFile: fixerResourcePath) as? Dictionary<String, Any>,
                                let bundledFixerVersionString = loadedFixerInfoPlist[bundleVersionKey] as? String, let bundledFixerVersion = Int(bundledFixerVersionString) {
                                if (existingFixerVersion < bundledFixerVersion) {
                                    print("existing fixer is \(existingFixerVersion), bundled fixer is \(bundledFixerVersion), upgrade is available")
                                    AppManager.shared.fixerUpdateAvailable = true
                                } else {
                                    self.pushCompletionVC()
                                    return
                                }
                            }
                        }
                    } else {
                        self.pushCompletionVC()
                        return
                    }

                } else {
                    let contains = AppManager.shared.compatibleVersionOfChosenApp.contains { (compatibleID) -> Bool in
                        return compatibleID == versionNumberString
                    }
                    if contains {
                        AppManager.shared.locationOfChosenApp = path
                        print("Found compatible unpatched app: \(bundleID), \(path), \(versionNumberString)")
                    } else {
                        incompatibleVersion = versionNumberString
                        print("Found incompatible unpatched app: \(bundleID), \(path), \(versionNumberString)")
                    }
                }
            }
        }
        
        if AppManager.shared.locationOfChosenApp == nil {
            if let lastCompatibleVersion = AppManager.shared.compatibleVersionOfChosenApp.first, let knownIncompatible = incompatibleVersion {
                let compareResult = knownIncompatible.compare(lastCompatibleVersion, options: .numeric, range: nil, locale: nil)
                if compareResult == .orderedDescending {
                    incompatibleVersion = nil
                }
            }
            self.pushGuidanceVC(incompatibleVersion)
        } else {
            self.pushAuthenticateVC()
        }
    }
    
    private func pushGuidanceVC(_ incompatibleVersionString: String? = nil) {
        if AppDelegate.rootVC?.navigationController.topViewController is GuidanceViewController {
            let name = AppManager.shared.nameOfChosenApp
            var title: String = ""
            var explaination: String = ""
            let compat = AppManager.shared.compatibleVersionOfChosenApp.first ?? ""
            if let incompat = incompatibleVersionString {
                title = "You need to update \(name) from \(incompat) to \(compat)."
                explaination = "The copy of \(name) you have installed is \(name) (\(incompat)), and is too old to be modified. \n\nDownload the latest version of \(name) (\(compat)) from the Purchased list in the Mac App Store, then run Retroactive again.\n\nIf you have installed \(name) (\(compat)) at a custom location, locate it manually."
            } else {
                title = "\(name) is not installed on your Mac."
                explaination = "Retroactive is unable to locate \(name) on your Mac. If you have previously downloaded \(name) from the Mac App Store, download it again from the Purchased list.\n\nIf you have installed \(name) at a custom location, locate it manually."
            }
            AppDelegate.showOptionSheet(title: title, text: explaination, firstButtonText: "Locate Manually...", secondButtonText: "Open Mac App Store", thirdButtonText: "Cancel") { (result) in
                if (result == .alertFirstButtonReturn) {
                    AppDelegate.manuallyLocateApp { (result, url, path) in
                        if (result) {
                            if let bundlePath = path {
                                let appBundle = Bundle(path: bundlePath)
                                let versionNumberString: String = appBundle?.object(forInfoDictionaryKey: bundleVersionKey) as? String ?? ""
                                let displayShortVersionNumberString: String = appBundle?.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
                                let identifier: String = appBundle?.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String ?? ""
                                let matchesCompatible = AppManager.shared.compatibleVersionOfChosenApp.contains { (compatible) -> Bool in
                                    return compatible == versionNumberString || compatible == displayShortVersionNumberString
                                }
                                if matchesCompatible && AppManager.shared.existingBundleIDOfChosenApp.contains(identifier) {
                                    AppManager.shared.locationOfChosenApp = bundlePath
                                    self.pushAuthenticateVC()
                                } else {
                                    AppDelegate.showTextSheet(title: "Selected app is incompatible", text: "\(url?.deletingPathExtension().lastPathComponent ?? "") (\(displayShortVersionNumberString)) is not \(name) (\(compat)). To proceed, you need to locate a valid copy of \(name) (\(compat)).")
                                }
                            }
                        }
                    }
                }
                if (result == .alertSecondButtonReturn) {
                    AppFinder.openMacAppStore()
                }
            }
            return
        }
        if AppManager.shared.chosenApp == .itunes {
            let itunesPath = "/Applications/iTunes.app"
// iTunes won't launch if the path isn't exactly "/Applications/iTunes.app".
//            let alreadyHasiTunes = FileManager.default.fileExists(atPath: itunesPath)
//            if (alreadyHasiTunes) {
//                let fallbackPath = "/Applications/iTunes \(AppManager.shared.compatibleVersionOfChosenApp.first!).app"
//                itunesPath = fallbackPath
//            }
            AppManager.shared.locationOfChosenApp = itunesPath
            self.pushAuthenticateVC()
            return
        }
        AppDelegate.rootVC?.navigationController.pushViewController(GuidanceViewController.instantiate(), animated: true)
    }
    
    private func pushCompletionVC() {
        let completionVC = CompletionViewController.instantiate()
        if (self.comingFromChoiceVC) {
            completionVC.allowPatchingAgain = true
        }
        AppDelegate.rootVC?.navigationController.pushViewController(completionVC, animated: true)
    }
    
    private func pushAuthenticateVC() {
        AppDelegate.rootVC?.navigationController.pushViewController(AuthenticateViewController.instantiate(), animated: true)
    }
    
    static func openMacAppStore() {
        if #available(OSX 10.15, *) {
            NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/System/Applications/App Store.app"), configuration: .init(), completionHandler: nil)
        } else {
            NSWorkspace.shared.launchApplication("App Store")
        }
    }

}
