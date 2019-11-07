//
//  VersionViewController.swift
//  Retroactive
//

import Cocoa

class VersionViewController: NSViewController {
    @IBOutlet weak var darkModeVersionView: NSView!
    @IBOutlet weak var appStoreVersionView: NSView!
    @IBOutlet weak var coverFlowVersionView: NSView!
    @IBOutlet weak var nextButton: NSButton!
    @IBOutlet weak var darkModeButton: HoverButton!
    @IBOutlet weak var appStoreButton: HoverButton!
    @IBOutlet weak var coverFlowButton: HoverButton!
    
    var choiceVCs: [VersionChoiceViewController] = []
    
    static func instantiate() -> VersionViewController
    {
        return NSStoryboard.standard!.instantiateController(withIdentifier: "VersionViewController") as! VersionViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let versionViews : [(NSView, HoverButton, iTunesVersion)] = [(darkModeVersionView, darkModeButton, .darkMode), (appStoreVersionView, appStoreButton, .appStore), (coverFlowVersionView, coverFlowButton, .coverFlow)]
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
    
    @IBAction func coverFlowClicked(_ sender: Any) {
        self.selectedVersion = .coverFlow
    }
    
    @IBAction func nextClicked(_ sender: Any) {
        AppFinder.shared.comingFromChoiceVC = true
        AppFinder.shared.queryAllInstalledApps()
    }
}
