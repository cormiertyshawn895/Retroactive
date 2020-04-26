//
//  AppFinder.swift
//  Retroactive
//

import Cocoa

class AppFinder: NSObject {
    var query: NSMetadataQuery?
    var comingFromChoiceVC: Bool = false

    static let shared = AppFinder()
    
    private override init() {
    }

    func queryAllInstalledApps() {
        print("query all installed apps")
        queryAllInstalledApps(shouldPresentAlert: false, claimsToHaveInstalled: false)
    }
    
    func queryAllInstalledApps(shouldPresentAlert: Bool, claimsToHaveInstalled: Bool) {
        query?.stop()
        query = NSMetadataQuery()
        query?.searchScopes = ["/Applications"]
        print("query = \(String(describing: query))")
        let pred = NSPredicate.init(format: "\(searchContentTypeTree) == '\(bundleContentType)' AND \(searchBundleIdentifier) CONTAINS[c] %@", AppManager.shared.existingBundleIDOfChosenApp)
        print("pred = \(String(describing: pred))")
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
        
        print("finishedQueryInstalledApps, results = \(String(describing: query?.results))")

        if actualQuery != query {
            return
        }

        guard let queriedApps = query?.results as? [NSMetadataItem] else {
            self.pushGuidanceVC()
            return
        }
        
        var incompatibleVersion: String?
        var installedFullVersionString: String?
        var installedShortVersionString: String?

        for result in queriedApps {
            if let bundleID = result.value(forAttribute: searchBundleIdentifier) as? String, let path = result.value(forAttribute: searchPath) as? String {
                var appBundle = Bundle(path: path)
                STPrivilegedTask.flushBundleCache(appBundle)
                appBundle = Bundle(path: path)

                let versionNumberString: String = appBundle?.object(forInfoDictionaryKey: kCFBundleShortVersionString) as? String ?? ""
                let fullVersionNumberString: String = appBundle?.object(forInfoDictionaryKey: kCFBundleVersion) as? String ?? ""
                if bundleID.elementsEqual(AppManager.shared.patchedBundleIDOfChosenApp) || fullVersionNumberString == AppManager.shared.patchedVersionStringOfChosenApp {
                    print("Found compatible patched app: \(bundleID), \(path)")
                    AppManager.shared.locationOfChosenApp = path
                    let chosenApp = AppManager.shared.chosenApp
                    if chosenApp == .aperture || chosenApp == .iphoto || AppManager.shared.hasChoseniWork {
                        let existingFixerPath = "\(path)/\(AppManager.shared.fixerFrameworkSubPath)"
                        if let existingFixerBundle = Bundle.init(path: existingFixerPath),
                            let existingFixerVersion = existingFixerBundle.cfBundleVersionInt,
                            let resourcePath = Bundle.main.resourcePath {
                            let fixerResourcePath = "\(resourcePath)/\(AppManager.shared.fixerFrameworkName)/Resources/Info.plist"
                            if let loadedFixerInfoPlist = NSDictionary(contentsOfFile: fixerResourcePath) as? Dictionary<String, Any>,
                                let bundledFixerVersionString = loadedFixerInfoPlist[kCFBundleVersion] as? String, let bundledFixerVersion = Int(bundledFixerVersionString) {
                                if (existingFixerVersion < bundledFixerVersion) {
                                    print("existing fixer is \(existingFixerVersion), bundled fixer is \(bundledFixerVersion), upgrade is available")
                                    AppManager.shared.fixerUpdateAvailable = true
                                } else {
                                    self.pushCompletionVC()
                                    return
                                }
                            }
                        }
                    } else if AppManager.shared.chosenApp == .finalCutPro7 {
                        do {
                            let exists = FileManager.default.fileExists(atPath: kCustomSettingsPath)
                            if (!exists) {
                                self.pushCompletionVC()
                                return
                            }
                            let contents = try FileManager.default.contentsOfDirectory(atPath: kCustomSettingsPath)
                            let presets = contents.filter { $0.lowercased().hasSuffix(".fcpre") }
                            if (presets.count == 0) {
                                self.pushCompletionVC()
                                return
                            }
                        } catch {
                            print("Can't determine if custom settings exist \(error)")
                        }
                    } else {
                        self.pushCompletionVC()
                        return
                    }

                } else {
                    let contains = AppManager.shared.compatibleVersionOfChosenApp.contains { (compatibleID) -> Bool in
                        return (compatibleID == versionNumberString)
                    }
                    if contains {
                        AppManager.shared.locationOfChosenApp = path
                        installedFullVersionString = fullVersionNumberString
                        installedShortVersionString = versionNumberString
                        if AppManager.shared.chosenApp == .xcode {
                            if let minSysVersionString = appBundle?.object(forInfoDictionaryKey: kLSMinimumSystemVersion) as? String {
                                print("Xcode min OS version: \(minSysVersionString), current OS version: \(ProcessInfo.osVersionNumberString)")
                                if (ProcessInfo.osVersionNumberString.osIsAtLeast(otherOS: minSysVersionString)) {
                                    print("Current OS is at least Xcode min OS")
                                    self.pushCompletionVC()
                                    return
                                }
                            }
                        }
                        print("Found compatible unpatched app: \(bundleID), \(path), \(versionNumberString)")
                    } else {
                        var alreadyFoundVersionOnlyRequiresMinorUpdate = false
                        if let alreadyFoundIncompatibleVersion = incompatibleVersion {
                            alreadyFoundVersionOnlyRequiresMinorUpdate = AppManager.shared.versionOnlyRequiresMinorUpdateToBeCompatible(foundOnDiskShortVersion: alreadyFoundIncompatibleVersion)
                        }
                        if (!alreadyFoundVersionOnlyRequiresMinorUpdate) {
                            incompatibleVersion = versionNumberString
                        }
                        print("Found incompatible unpatched app: \(bundleID), \(path), \(versionNumberString); alreadyFoundVersionOnlyRequiresMinorUpdate = \(alreadyFoundVersionOnlyRequiresMinorUpdate)")
                    }
                }
            }
        }
        
        let lastCompatible = AppManager.shared.compatibleVersionOfChosenApp.first
        if AppManager.shared.locationOfChosenApp == nil {
            if let lastCompatibleVersion = lastCompatible, let knownIncompatible = incompatibleVersion {
                let compareResult = knownIncompatible.compare(lastCompatibleVersion, options: .numeric, range: nil, locale: nil)
                if compareResult == .orderedDescending {
                    incompatibleVersion = nil
                }
            }
            self.pushGuidanceVC(incompatibleVersion)
        } else {
            if let lastCompatibleVersion = lastCompatible, let installed = installedFullVersionString, let shortVersion = installedShortVersionString {
                let compareResult = installed.compare(lastCompatibleVersion, options: .numeric, range: nil, locale: nil)
                if compareResult == .orderedAscending {
                    self.pushGuidanceVC(nil, shortOldVersionString: shortVersion, shouldOfferOptionalUpdate: true)
                    return
                }
            }
            self.pushAuthenticateVC()
        }
    }

    private func pushGuidanceVC(_ incompatibleVersionString: String? = nil, shortOldVersionString: String? = nil, shouldOfferOptionalUpdate: Bool = false) {
        if AppDelegate.rootVC?.navigationController.topViewController is GuidanceViewController {
            let name = AppManager.shared.spaceConstrainedNameOfChosenApp
            var title: String = ""
            var explaination: String = ""
            
            let localizedBuildPrefix = "Build".localized()
            var compat = AppManager.shared.compatibleVersionOfChosenApp.first ?? ""
            var userFacingCompat = AppManager.shared.userFacingLatestShortVersionOfChosenApp
            var onlyRequiresMinorUpdate = false
            
            if let incompat = incompatibleVersionString {
                if (userFacingCompat == incompat) {
                    compat = "\(userFacingCompat) (\(localizedBuildPrefix) \(compat))"
                } else {
                    compat = userFacingCompat
                }

                let isTooNew = AppManager.shared.versionisTooNewForPatching(foundOnDiskShortVersion: incompat)
                onlyRequiresMinorUpdate = AppManager.shared.versionOnlyRequiresMinorUpdateToBeCompatible(foundOnDiskShortVersion: incompat)
                title = isTooNew ?
                    String(format: "You need to install an older version of %@ %@".localized(), name, compat) :
                    String(format: "You need to update %@ from %@ to %@.".localized(), name, incompat, compat)
                
                let firstParagraph = String(format: isTooNew ?
                    "The copy of %@ you have installed is %@ %@, and is too new to be modified.".localized() :
                    (onlyRequiresMinorUpdate ?
                        "The copy of %@ you have installed is %@ %@. You need to first install a minor update before Retroactive can modify it.".localized() :
                        "The copy of %@ you have installed is %@ %@, and is too old to be modified.".localized()),
                                            name, name, incompat)

                var secondParagraph = ""
                if AppManager.shared.chosenApp == .xcode {
                    secondParagraph = String(format: "Directly download %@ from the Apple Developer website, then run Retroactive again.".localized(), name)
                } else if AppManager.shared.hasChoseniWork {
                    secondParagraph = onlyRequiresMinorUpdate ?
                        String(format: "Click on “Download Update“ to download and install the iWork 9.3 Update.".localized(), name, compat) :
                        "Download and install iWork ’09 from The Internet Archive, then install the iWork 9.3 Update.".localized()
                } else {
                    secondParagraph = String(format: "Download the latest version of %@ %@ from the Purchased list in the Mac App Store, then run Retroactive again.".localized(), name, compat)
                }
                
                let thirdParagraph = String(format: "If you have already installed %@ %@ at a custom location, you can also locate it manually.".localized(), name, compat)
                explaination = firstParagraph + " " + secondParagraph + twoNewLines + thirdParagraph
            } else {
                if (shouldOfferOptionalUpdate) {
                    let short = shortOldVersionString ?? ""
                    if (userFacingCompat == short) {
                        userFacingCompat = "\(userFacingCompat) (\(localizedBuildPrefix) \(compat))"
                    }

                    title = String.init(format: "We recommend updating %@ to version %@.".localized(), name, userFacingCompat)
                    explaination = String.init(format: "Retroactive can unlock your installed version of %@ %@, but works best with %@ %@. To avoid stability issues, we recommend updating to %@ %@ before proceeding.".localized(), name, short, name, userFacingCompat, name, userFacingCompat)
                } else {
                    title = String(format: "%@ is not installed on your Mac.".localized(), name)
                    explaination = String(format: "Retroactive is unable to locate %@ on your Mac. %@".localized(), name, AppManager.shared.notInstalledText)
                        + twoNewLines
                        + String(format:"If you have installed %@ at a custom location, locate it manually.".localized(), name)
                }
            }
            if (shouldOfferOptionalUpdate) {
                AppDelegate.showOptionSheet(title: title, text: explaination, firstButtonText: "Update (Recommended)".localized(), secondButtonText: "Don't Update (Not Recommended)".localized(), thirdButtonText: "Cancel".localized()) { (result) in
                    if (result == .alertFirstButtonReturn) {
                        AppManager.shared.updateSelectedApp()
                    }
                    if (result == .alertSecondButtonReturn) {
                        self.pushAuthenticateVC()
                    }
                }
                return
            }

            let downloadAppText = AppManager.shared.notInstalledActionText
            let downloadUpdateText = "Download Update".localized()
            let locateManuallyText = "Locate Manually...".localized()
            AppDelegate.showOptionSheet(title: title,
                                        text: explaination,
                                        firstButtonText: onlyRequiresMinorUpdate ? downloadUpdateText : downloadAppText,
                                        secondButtonText: locateManuallyText,
                                        thirdButtonText: "Cancel".localized()) { (result) in
                if result == .alertSecondButtonReturn {
                    AppDelegate.manuallyLocateApp { (result, url, path) in
                        if (result) {
                            if let bundlePath = path {
                                let appBundle = Bundle(path: bundlePath)
                                let versionNumberString: String = appBundle?.object(forInfoDictionaryKey: kCFBundleVersion) as? String ?? ""
                                let displayShortVersionNumberString: String = appBundle?.object(forInfoDictionaryKey: kCFBundleShortVersionString) as? String ?? ""
                                let identifier: String = appBundle?.object(forInfoDictionaryKey: kCFBundleIdentifier) as? String ?? ""
                                let matchesCompatible = AppManager.shared.compatibleVersionOfChosenApp.contains { (compatible) -> Bool in
                                    return compatible == versionNumberString || compatible == displayShortVersionNumberString
                                }
                                if matchesCompatible && AppManager.shared.existingBundleIDOfChosenApp.contains(identifier) {
                                    AppManager.shared.locationOfChosenApp = bundlePath
                                    self.pushAuthenticateVC()
                                } else {
                                    let text = String(format: "%@ %@ is not %@ %@. To proceed, you need to locate a valid copy of %@ %@.".localized(), url?.deletingPathExtension().lastPathComponent ?? "", displayShortVersionNumberString, name, compat, name, compat)
                                    AppDelegate.showTextSheet(title: "Selected app is incompatible".localized(), text: text)
                                }
                            }
                        }
                    }
                }
                if (result == .alertFirstButtonReturn && AppManager.shared.notInstalledActionText.count > 0) {
                    if (onlyRequiresMinorUpdate) {
                        AppManager.shared.updateSelectedApp()
                    } else {
                        AppManager.shared.acquireSelectedApp()
                    }
                }
            }
            return
        }
        if AppManager.shared.chosenApp == .itunes {
            let itunesPath = "/Applications/iTunes.app"
            AppManager.shared.locationOfChosenApp = itunesPath
            self.pushAuthenticateVC()
            return
        }
        AppDelegate.rootVC?.navigationController.pushViewController(GuidanceViewController.instantiate(), animated: true)
    }
    
    private func pushCompletionVC() {
        AppManager.shared.allowPatchingAgain = self.comingFromChoiceVC
        if (AppManager.shared.needsBashAccess) {
            AppDelegate.pushSyncingVC()
            return
        }
        AppManager.shared.retinizeSelectedAppForCurrentUser()
        AppDelegate.pushCompletionVC()
    }
    
    private func pushAuthenticateVC() {
        AppDelegate.rootVC?.navigationController.pushViewController(AuthenticateViewController.instantiate(), animated: true)
    }
    
}
