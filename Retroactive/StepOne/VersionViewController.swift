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
    var choiceVCs: [VersionChoiceViewController] = []
    
    static func instantiate() -> VersionViewController
    {
        return NSStoryboard.main!.instantiateController(withIdentifier: "VersionViewController") as! VersionViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let versionViews = [darkModeVersionView, appStoreVersionView, coverFlowVersionView]
        var versions: [iTunesVersion] = [.darkMode, .appStore, .coverFlow]
        for view in versionViews {
            let choiceVC = VersionChoiceViewController.instantiate()
            choiceVC.itunesApp = iTunesApp(versions.first!)
            versions.removeFirst()
            view?.addSubview(choiceVC.view)
            self.addChild(choiceVC)
            choiceVCs.append(choiceVC)
        }
        nextButton.updateTitle()
        self.selectedVersion = .darkMode
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
