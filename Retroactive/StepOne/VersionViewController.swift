//
//  VersionViewController.swift
//  Retroactive
//

import Cocoa

class VersionViewController: NSViewController {
    @IBOutlet weak var darkModeVersionView: NSView!
    @IBOutlet weak var appStoreVersionView: NSView!
    @IBOutlet weak var configuratorVersionView: NSView!
    @IBOutlet weak var classicThemeVersionView: NSView!
    @IBOutlet weak var coverFlowVersionView: NSView!
    @IBOutlet weak var nextButton: NSButton!
    @IBOutlet weak var darkModeButton: HoverButton!
    @IBOutlet weak var appStoreButton: HoverButton!
    @IBOutlet weak var configuratorButton: HoverButton!
    @IBOutlet weak var classicThemeButton: HoverButton!
    @IBOutlet weak var coverFlowButton: HoverButton!
    
    var choiceVCs: [VersionChoiceViewController] = []
    
    static func instantiate() -> VersionViewController
    {
        return NSStoryboard.standard!.instantiateController(withIdentifier: "VersionViewController") as! VersionViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let versionViews : [(NSView, HoverButton, iTunesVersion)] = [(darkModeVersionView, darkModeButton, .darkMode), (appStoreVersionView, appStoreButton, .appStore), (configuratorVersionView, configuratorButton, .configurator), (classicThemeVersionView, classicThemeButton, .classicTheme), (coverFlowVersionView, coverFlowButton, .coverFlow)]
        for (view, button, version) in versionViews {
            let choiceVC = VersionChoiceViewController.instantiate()
            choiceVC.itunesApp = iTunesApp(version)
            view.addSubview(choiceVC.view)
            self.addChild(choiceVC)
            for choiceSubview in choiceVC.view.subviews {
                choiceSubview.moveIntoView(button)
            }
            choiceVCs.append(choiceVC)
        }
        nextButton.updateTitle()
        self.selectedVersion = .darkMode
        AppManager.shared.choseniTunesVersion = .darkMode
        Permission.shared.updateThrowawayApp()
    }
    
    var selectedVersion: iTunesVersion? {
        didSet {
            for vc in choiceVCs {
                vc.checkMark.isHidden = vc.itunesApp?.version != selectedVersion
            }
            AppManager.shared.choseniTunesVersion = selectedVersion
        }
    }
    
    @IBAction func darkClicked(_ sender: Any) {
        self.selectedVersion = .darkMode
    }
    
    @IBAction func appStoreClicked(_ sender: Any) {
        self.selectedVersion = .appStore
    }
    
    @IBAction func configuratorClicked(_ sender: Any) {
        self.selectedVersion = .configurator
    }
    
    @IBAction func classicThemeClicked(_ sender: Any) {
        self.selectedVersion = .classicTheme
    }
    
    @IBAction func coverFlowClicked(_ sender: Any) {
        self.selectedVersion = .coverFlow
    }
    
    @IBAction func nextClicked(_ sender: Any) {
        if (self.selectedVersion == .configurator) {
            AppDelegate.current.safelyOpenURL(AppManager.shared.configuratorURL)
            TutorialViewController.presentFromViewController(self)
            return
        }
        AppFinder.shared.comingFromChoiceVC = true
        AppFinder.shared.queryAllInstalledApps()
    }
}
