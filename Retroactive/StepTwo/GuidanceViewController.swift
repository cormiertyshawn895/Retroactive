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
        let chosen = AppManager.shared.chosenApp
        if (chosen == .keynote5) {
            downloadAppLabel.stringValue = "Download and install iWork ’09 from The Internet Archive".localized()
            airDropAppLabel.stringValue = "Download and install the iWork 9.3 Update".localized()
            hideThirdLabel()
        }
        else if (chosen == .finalCutPro7) {
            downloadAppLabel.stringValue = "Install Final Cut Pro 7 from DVD disc or DMG image".localized()
            airDropAppLabel.stringValue = "Download and update to Final Cut Pro 7.0.3 (2010-02)".localized()
            hideThirdLabel()
        }
        else if (chosen == .logicPro9) {
            downloadAppLabel.stringValue = "Install Logic Pro 9 from DVD disc or DMG image".localized()
            airDropAppLabel.stringValue = "Download and update to Logic Pro 9.1.8".localized()
            hideThirdLabel()
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
    
    func hideThirdLabel() {
        timeMachineImageButton.removeFromSuperview()
        downloadAppLabel.frame = CGRect(x: downloadAppLabel.frame.origin.x + 30, y: downloadAppLabel.frame.origin.y, width: downloadAppLabel.frame.width - 35, height: downloadAppLabel.frame.height)
        airDropAppLabel.frame = CGRect(x: airDropAppLabel.frame.origin.x + 40, y: downloadAppLabel.frame.origin.y, width: downloadAppLabel.frame.width, height: downloadAppLabel.frame.height)
        airDropAppImage.frame = CGRect(x: airDropAppImage.frame.origin.x, y: downloadAppImage.frame.origin.y, width: 403, height: 309)
    }
    
    @IBAction func appStoreClicked(_ sender: Any) {
        AppManager.shared.acquireSelectedApp()
    }
    
    @IBAction func airDropClicked(_ sender: Any) {
        AppManager.shared.updateSelectedApp()
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
