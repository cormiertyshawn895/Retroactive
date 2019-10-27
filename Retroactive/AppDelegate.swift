//
//  AppDelegate.swift
//  Retroactive
//

import Cocoa

@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        _ = AppManager.shared
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    static var current: AppDelegate {
        return NSApplication.shared.delegate as! AppDelegate
    }
    
    static var rootVC: RootViewController? {
        get {
            return NSApp.mainWindow?.contentViewController as? RootViewController
        }
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
        if let window = NSApp.mainWindow {
            alert.beginSheetModal(for: window) { (response) in
                callback(response)
            }
        } else {
            let response = alert.runModal()
            callback(response)
        }
    }
    
    static func appWindow() -> NSWindow? {
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
        guard let window = self.appWindow() else {
            return
        }
        let dialog = NSOpenPanel()
        dialog.title = "Locate \(AppManager.shared.nameOfChosenApp) \(AppManager.shared.compatibleVersionOfChosenApp.first ?? "")"

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
        alert.addButton(withTitle: "OK")
        if let window = NSApp.mainWindow {
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
        
        if !(rootVC.navigationController.topViewController is ProgressViewController) {
            return true
        }
        
        let name = AppManager.shared.nameOfChosenApp
        
        let showUnableToClose = {
            AppDelegate.showTextSheet(title: "Unable to quit Retroactive", text: "Retroactive is modifying \(name). Quitting Retroactive will result in a corrupted copy of \(name).")
        }

        if AppManager.shared.chosenApp == .itunes {
            if let progressVC = rootVC.navigationController.topViewController as? ProgressViewController {
                if progressVC.subProgress1.inProgress {
                    AppDelegate.showOptionSheet(title: "Are you sure you want to stop installing \(name)?", text: "Quitting Retroactive now may result in a corrupted install of \(name) and is not recommended.", firstButtonText: "Keep Installing", secondButtonText: "Stop Installing \(name)", thirdButtonText: "") { (response) in
                        if (response == .alertSecondButtonReturn) {
                            AppDelegate.appWindow()?.close()
                        }
                    }
                } else {
                    showUnableToClose()
                }
            }
        } else {
            showUnableToClose()
        }
        return false
    }
    
    @IBAction func checkForUpdates(_ sender: Any? = nil) {
        AppManager.shared.checkForConfigurationUpdates()
        if (AppManager.shared.hasNewerVersion == true) {
            self.promptForUpdateAvailable()
        } else {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { (timer) in
                self.promptForUpdateAvailable()
            }
        }
    }

    @IBAction func openIssue(_ sender: Any? = nil) {
        self.safelyOpenURL(AppManager.shared.issuesPage)
    }

    @IBAction func viewSource(_ sender: Any? = nil) {
        self.safelyOpenURL(AppManager.shared.sourcePage)
    }
    
    @IBAction func projectPage(_ sender: Any? = nil) {
        self.safelyOpenURL(AppManager.shared.sourcePage)
    }
    
    func safelyOpenURL(_ urlString: String?) {
        if let page = urlString, let url = URL(string: page) {
            NSWorkspace.shared.open(url)
        }
    }
    
    func promptForUpdateAvailable() {
        if (AppManager.shared.hasNewerVersion == true) {
            AppDelegate.showOptionSheet(title: AppManager.shared.newVersionVisibleTitle ?? "Update available.", text: AppManager.shared.newVersionChangelog ?? "A newer version of Retroactive is available.", firstButtonText: "Download", secondButtonText: "Learn More...", thirdButtonText: "Cancel") { (response) in
                if (response == .alertFirstButtonReturn) {
                    AppDelegate.current.safelyOpenURL(AppManager.shared.latestZIP)
                } else if (response == .alertSecondButtonReturn) {
                    AppDelegate.current.safelyOpenURL(AppManager.shared.releasePage)
                }
            }
        } else {
            AppDelegate.showOptionSheet(title: "Retroactive \(Bundle.main.cfBundleVersionString ?? "") is already the latest available version.", text:"", firstButtonText: "OK", secondButtonText: "View Release Page...", thirdButtonText: "") { (response) in
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
}

