//
//  ViewController.swift
//  Retroactive
//

import Cocoa

class RootViewController: NSViewController, CCNNavigationControllerDelegate, NSWindowDelegate {
    @IBOutlet weak var backButton: NSButton!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var titleStackView: NSStackView!
    @IBOutlet weak var updateButton: PillButton!
    @IBOutlet weak var retroactiveLabel: NSTextField!
    
    var currentDocumentTitle: String {
        get {
            return titleLabel.stringValue
        }
        set {
            titleLabel.stringValue = newValue
            retroactiveLabel.stringValue = newValue.count > 0 ? "— Retroactive".localized() : "Retroactive".localized()
            self.view.window?.title = String(format: "%@ — Retroactive".localized(), newValue)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.alertForOSIncompatibility()

        self.navigationController = CCNNavigationController(rootViewController: ChoiceViewController.instantiate())
        self.navigationController.delegate = self
        self.navigationController.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.navigationController.view)
        
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: self.view, attribute: .top, relatedBy: .equal, toItem: self.navigationController.view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.view, attribute: .leading, relatedBy: .equal, toItem: self.navigationController.view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.view, attribute: .trailing, relatedBy: .equal, toItem: self.navigationController.view, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.view, attribute: .bottom, relatedBy: .equal, toItem: self.navigationController.view, attribute: .bottom, multiplier: 1, constant: 0),
        ])
        
        titleStackView.wantsLayer = true
    }
    
    func alertForOSIncompatibility() {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        if osVersion.minorVersion > 15 {
            AppDelegate.showOptionSheet(title: "Update to a newer version of Retroactive".localized(),
                                        text: String(format: "This version of Retroactive is only designed and tested for macOS High Sierra, macOS Mojave, and macOS Catalina, which may be incompatible with %@.".localized(), ProcessInfo.versionString),
                                        firstButtonText: "Check for Updates",
                                        secondButtonText: "Run Anyways",
                                        thirdButtonText: "Quit") { (response) in
                if (response == .alertFirstButtonReturn) {
                    AppDelegate.current.checkForUpdates()
                    // NSApplication.shared.terminate(self)
                } else if (response == .alertSecondButtonReturn) {
                } else {
                    NSApplication.shared.terminate(self)
                }
            }
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.delegate = self
    }
    
    @IBAction func previousClicked(_ sender: Any) {
        if AppManager.shared.chosenApp == .proVideoUpdate {
            self.navigationController.popToRootViewController(animated: true)
            return
        }
        
        if let topVC = self.navigationController.topViewController {
            if topVC is CompletionViewController {
                self.navigationController.popToRootViewController(animated: true)
                return
            }
        }
        
        if let previousVC = self.navigationController.previousViewController {
            if previousVC is CompletionViewController || previousVC is ProgressViewController {
                self.navigationController.popToRootViewController(animated: true)
                return
            }
        }

        self.navigationController.popViewController(animated: true)
    }
    
    func navigationController(_ navigationController: CCNNavigationController!, willShow viewController: NSViewController!, animated: Bool) {
    }
    
    func navigationController(_ navigationController: CCNNavigationController!, didPop viewController: NSViewController!, animated: Bool) {
        self.updateBackButtonAndTitle()
    }
    
    func updateBackButtonAndTitle() {
        if let topVC = self.navigationController.topViewController {
            self.backButton.isHidden = topVC is ChoiceViewController
            if (topVC is ChoiceViewController) {
                AppManager.shared.chosenApp = nil
                AppManager.shared.choseniTunesVersion = nil
            }
            self.backButton.isEnabled = !(topVC is ProgressViewController)
            return
        }
        self.backButton.isHidden = false
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        self.titleStackView.alphaValue = 1.0
    }
    
    func windowDidResignKey(_ notification: Notification) {
        self.titleStackView.alphaValue = 0.34
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard let appDelegate = NSApp.delegate as? AppDelegate else {
            return true
        }
        return appDelegate.determineClosing()
    }
    
    func windowWillClose(_ notification: Notification) {
        print("will close")
    }

    @IBAction func checkForUpdatesClicked(_ sender: Any) {
        AppDelegate.current.promptForUpdateAvailable()
    }
}

