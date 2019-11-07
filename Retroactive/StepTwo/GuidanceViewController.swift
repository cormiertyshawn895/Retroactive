//
//  GuidanceViewController.swift
//  Retroactive
//

import Cocoa

class GuidanceViewController: NSViewController {
    @IBOutlet weak var iconImageView: NSImageView!
    @IBOutlet weak var needInstallFirstTitle: DisplayOnlyTextField!
    @IBOutlet weak var alreadyInstalledButton: NSButton!
    @IBOutlet weak var downloadAppLabel: DisplayOnlyTextField!
    @IBOutlet weak var downloadAppImage: NSButton!
    @IBOutlet weak var airDropAppImage: NSButton!
    @IBOutlet weak var airDropAppLabel: DisplayOnlyTextField!
    @IBOutlet weak var timeMachineAppLabel: DisplayOnlyTextField!
    @IBOutlet weak var continueButton: NSButton!
    @IBOutlet weak var timeMachineImageButton: HoverButton!
    
    static func instantiate() -> GuidanceViewController {
        return NSStoryboard.standard!.instantiateController(withIdentifier: "GuidanceViewController") as! GuidanceViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let labels = [needInstallFirstTitle, downloadAppLabel, airDropAppLabel, timeMachineAppLabel]
        for label in labels {
            label!.updateToken()
        }
        alreadyInstalledButton.updateTitle()
        iconImageView.updateIcon()
        continueButton.updateTitle()
        downloadAppImage.image = AppManager.shared.appStoreImage
        airDropAppImage.image = AppManager.shared.airdropImage
        downloadAppLabel.moveIntoView(downloadAppImage)
        airDropAppLabel.moveIntoView(airDropAppImage)
        timeMachineAppLabel.moveIntoView(timeMachineImageButton)
    }
    
    @IBAction func appStoreClicked(_ sender: Any) {
        AppFinder.openMacAppStore()
    }
    
    @IBAction func airDropClicked(_ sender: Any) {
        AppDelegate.openKBArticle("203106")
    }
    
    @IBAction func timeMachineClicked(_ sender: Any) {
        AppDelegate.openKBArticle("209152")
    }
    
    @IBAction func alreadyInstalledClicked(_ sender: Any) {
        AppFinder.shared.queryAllInstalledApps(shouldPresentAlert: true, claimsToHaveInstalled: true)
    }
    
    @IBAction func continueClicked(_ sender: Any) {
        AppFinder.shared.queryAllInstalledApps()
        AppFinder.shared.queryAllInstalledApps(shouldPresentAlert: true, claimsToHaveInstalled: false)
    }
    
}
