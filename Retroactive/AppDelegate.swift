//
//  AppDelegate.swift
//  Retroactive
//

import Cocoa

let kErrorRecoveryTitle = "ErrorRecoveryTitle"
let kErrorRecoveryText = "ErrorRecoveryText"

@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        _ = AppManager.shared
        showRecoveryTitleIfNeeded()
        NSApp.activate(ignoringOtherApps: true)
    }

    func showRecoveryTitleIfNeeded() {
        if let recoveryTitle = UserDefaults.standard.string(forKey: kErrorRecoveryTitle),
            let recoveryText = UserDefaults.standard.string(forKey: kErrorRecoveryText) {
            if (recoveryTitle.count > 0 && recoveryText.count > 0) {
                UserDefaults.standard.setValue(nil, forKey: kErrorRecoveryTitle)
                UserDefaults.standard.setValue(nil, forKey: kErrorRecoveryText)

                AppDelegate.showOptionSheet(title: recoveryTitle,
                                            text: recoveryText,
                                            firstButtonText: "OK".localized(), secondButtonText: "", thirdButtonText: "") { (response) in
                }
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        do {
            try FileManager.default.removeItem(atPath: throwawayTmpPath)
        } catch {
            print(error)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        AppDelegate.appWindow?.makeKeyAndOrderFront(self)
        return true
    }
    
    static var current: AppDelegate {
        return NSApplication.shared.delegate as! AppDelegate
    }
    
    static var rootVC: RootViewController? {
        get {
            return self.appWindow?.contentViewController as? RootViewController
        }
    }
    
    static func openKBArticle(_ identifier: String) {
        let url = URL(string:"https://support.apple.com/HT\(identifier)")!
        NSWorkspace.shared.open(url)
    }

    static func showOptionSheet(title: String, text: String, firstButtonText: String, secondButtonText: String, thirdButtonText: String, callback: @escaping ((_ response: NSApplication.ModalResponse)-> ())) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.alertStyle = NSAlert.Style.informational
        alert.addButton(withTitle: firstButtonText)
        if secondButtonText.count > 0 {
            alert.addButton(withTitle: secondButtonText)
        }
        if thirdButtonText.count > 0 {
            alert.addButton(withTitle: thirdButtonText)
        }
        if let window = self.appWindow {
            alert.beginSheetModal(for: window) { (response) in
                callback(response)
            }
        } else {
            let response = alert.runModal()
            callback(response)
        }
    }
    
    static var appWindow: NSWindow? {
        if let mainWindow = NSApp.mainWindow {
            return mainWindow
        }
        for window in NSApp.windows {
            if let typed = window as? RetroactiveWindow {
                return typed
            }
        }
        return nil
    }

    static func manuallyLocateApp(callback: @escaping ((_ selectedFile: Bool, _ fileURL: URL?, _ filePath: String?)-> ())) {
        guard let window = self.appWindow else {
            return
        }
        let dialog = NSOpenPanel()
        dialog.title = String(format: "Locate %@ %@".localized(), AppManager.shared.nameOfChosenApp, AppManager.shared.compatibleVersionOfChosenApp.first ?? "")

        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.canChooseDirectories = false
        dialog.canCreateDirectories = true
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes = ["app"]

        dialog.beginSheetModal(for: window) { (result) in
            if result != .OK {
                callback(false, nil, nil)
            } else {
                if let result = dialog.url, let path = dialog.url?.path {
                    callback(true, result, path)
                }
            }
        }
    }
    
    static func showTextSheet(title: String, text: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.alertStyle = NSAlert.Style.informational
        alert.addButton(withTitle: "OK".localized())
        if let window = self.appWindow {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let status = self.determineClosing()
        if (status == true) {
            return .terminateNow
        }
        return .terminateCancel
    }
    
    func determineClosing() -> Bool {
        guard let rootVC = AppDelegate.rootVC else {
            return true
        }
        
        let topVC = rootVC.navigationController.topViewController
        if !(topVC is ProgressViewController) && !(topVC is SyncingViewController && !AppManager.shared.allowPatchingAgain) {
            return true
        }
        
        if AppManager.shared.willRelaunchSoon {
            return true
        }
        
        let name = AppManager.shared.nameOfChosenApp
        
        let showUnableToClose = {
            AppDelegate.showTextSheet(title: "Unable to quit Retroactive".localized(), text: String(format: "Retroactive is unlocking %@. Quitting Retroactive will result in a corrupted copy of %@.".localized(), name, name))
        }

        if AppManager.shared.chosenApp == .itunes {
            if let progressVC = topVC as? ProgressViewController {
                if progressVC.subProgress1.inProgress {
                    AppDelegate.showOptionSheet(title: String(format: "Are you sure you want to stop installing %@?".localized(), name),
                                                text: String(format: "Quitting Retroactive now may result in a corrupted install of %@ and is not recommended.".localized(), name),
                                                firstButtonText: "Keep Installing".localized(),
                                                secondButtonText: String(format: "Stop Installing %@".localized(), name),
                                                thirdButtonText: "") { (response) in
                        if (response == .alertSecondButtonReturn) {
                            AppDelegate.appWindow?.close()
                        }
                    }
                    return false
                }
            }
        }

        showUnableToClose()
        return false
    }
    
    @IBAction func checkForUpdates(_ sender: Any? = nil) {
        AppManager.shared.checkForConfigurationUpdates()
        if (AppManager.shared.hasNewerVersion == true) {
            self.promptForUpdateAvailable()
        } else {
            Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(promptForUpdateAvailable), userInfo: nil, repeats: false)
        }
    }

    @IBAction func openIssue(_ sender: Any? = nil) {
        self.safelyOpenURL(AppManager.shared.newIssuePage)
    }

    @IBAction func viewSource(_ sender: Any? = nil) {
        self.safelyOpenURL(AppManager.shared.sourcePage)
    }
    
    @IBAction func projectPage(_ sender: Any? = nil) {
        self.safelyOpenURL(AppManager.shared.sourcePage)
    }
    
    @IBAction func wikiPage(_ sender: Any) {
        self.safelyOpenURL(AppManager.shared.wikiPage)
    }
    
    @IBAction func issueTracker(_ sender: Any) {
        self.safelyOpenURL(AppManager.shared.issuesPage)
    }
    
    func safelyOpenURL(_ urlString: String?) {
        if let page = urlString, let url = URL(string: page) {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func promptForUpdateAvailable() {
        if (AppManager.shared.hasNewerVersion == true) {
            AppDelegate.showOptionSheet(title: AppManager.shared.newVersionVisibleTitle ?? "Update available.".localized(),
                                        text: AppManager.shared.newVersionChangelog ?? "A newer version of Retroactive is available.".localized(),
                                        firstButtonText: "Download".localized(),
                                        secondButtonText: "Learn More...".localized(),
                                        thirdButtonText: "Cancel".localized()) { (response) in
                if (response == .alertFirstButtonReturn) {
                    AppDelegate.current.safelyOpenURL(AppManager.shared.latestZIP)
                } else if (response == .alertSecondButtonReturn) {
                    AppDelegate.current.safelyOpenURL(AppManager.shared.releasePage)
                }
            }
        } else {
            AppDelegate.showOptionSheet(title: String(format: "Retroactive %@ is already the latest available version.".localized(), Bundle.main.cfBundleVersionString ?? ""),
                                        text:"",
                                        firstButtonText: "OK".localized(),
                                        secondButtonText: "View Release Page...".localized(),
                                        thirdButtonText: "") { (response) in
                if (response == .alertSecondButtonReturn) {
                    AppDelegate.current.safelyOpenURL(AppManager.shared.releasePage)
                }
            }
        }
    }
    
    @IBAction func showCredits(_ sender: Any) {
        if let credits = Bundle.main.url(forResource: "Credits", withExtension: "pdf") {
            NSWorkspace.shared.open(credits)
        }
    }
    
    static func pushVersionVC() {
        AppDelegate.rootVC?.navigationController.pushViewController(VersionViewController.instantiate(), animated: true)
    }

    static func pushSyncingVC() {
        AppDelegate.rootVC?.navigationController.pushViewController(SyncingViewController.instantiate(), animated: true)
    }
    
    static func pushCompletionVC() {
        AppDelegate.rootVC?.navigationController.pushViewController(CompletionViewController.instantiate(), animated: true)
    }
}

extension NSApplication {
    func relaunch() {
        self.syncMainQueue {
            AppManager.shared.willRelaunchSoon = true
            let path = Bundle.main.bundlePath
            print("Re-launching \(path)")
            _ = Process.launchedProcess(launchPath: "/usr/bin/open", arguments: [path])
            NSApp.terminate(self)
        }
    }
}
