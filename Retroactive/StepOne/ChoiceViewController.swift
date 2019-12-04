//
//  ChoiceViewController.swift
//  Retroactive
//

import Cocoa

let searchDisplayName = "kMDItemDisplayName"
let searchContentTypeTree = "kMDItemContentTypeTree"
let searchBundleIdentifier = "kMDItemCFBundleIdentifier"
let searchPath = "kMDItemPath"
let bundleContentType = "com.apple.application-bundle"
let debugAlwaysPatch = true

class ChoiceViewController: NSViewController {
    @IBOutlet weak var getStartedSubTitle: DisplayOnlyTextField!
    @IBOutlet weak var otherOSSubtitle: NSTextField!
    @IBOutlet weak var otherOSImageView: NSImageView!
    
    @IBOutlet weak var apertureButton: NSButton!
    @IBOutlet weak var iphotoButton: NSButton!
    @IBOutlet weak var itunesButton: NSButton!
    @IBOutlet weak var apertureLabel: NSTextField!
    @IBOutlet weak var iphotoLabel: NSTextField!
    @IBOutlet weak var itunesLabel: NSTextField!
    
    @IBOutlet weak var firstActionButton: NSBox!
    @IBOutlet weak var secondActionButton: NSBox!
    @IBOutlet weak var thirdActionButton: NSBox!
    
    @IBOutlet weak var thirdActionLabel: NSTextField!
    
    var appFinder: AppFinder?
    
    let oldOS: Bool = ProcessInfo.processInfo.operatingSystemVersion.minorVersion <= 14
    
    static func instantiate() -> ChoiceViewController
    {
        NSStoryboard.standard!.instantiateController(withIdentifier: "ChoiceViewController") as! ChoiceViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        firstActionButton.fillColor = .controlAccentColorPolyfill
        secondActionButton.fillColor = .controlAccentColorPolyfill
        thirdActionButton.fillColor = .controlAccentColorPolyfill
        apertureLabel.moveIntoView(apertureButton)
        firstActionButton.moveIntoView(apertureButton)
        iphotoLabel.moveIntoView(iphotoButton)
        secondActionButton.moveIntoView(iphotoButton)
        itunesLabel.moveIntoView(itunesButton)
        thirdActionButton.moveIntoView(itunesButton)
        if (oldOS == true) {
            showMojaveChoices()
        }
    }
    
    func showMojaveChoices() {
        getStartedSubTitle.stringValue = "Unlock Final Cut Pro 7 and Logic Pro 9, or fix Keynote ’09.".localized()
        
        apertureButton.image = NSImage(named: "final7_cartoon")
        apertureLabel.stringValue = "Final Cut Pro 7"
        
        iphotoButton.image = NSImage(named: "logic9_cartoon")
        iphotoLabel.stringValue = "Logic Pro 9"
        
        itunesButton.image = NSImage(named: "keynote5_cartoon")
        itunesLabel.stringValue = "Keynote ’09"
        thirdActionLabel.stringValue = "FIX".localized()
        
        otherOSSubtitle.stringValue = "If you upgrade to macOS Catalina, Final Cut Pro 7, Logic Pro 9, and Keynote ’09 will be locked again, and can’t be unlocked. However, Retroactive can still unlock Aperture and iPhoto, or install iTunes on macOS Catalina.".localized()
        otherOSImageView.image = NSImage(named:"catalina-banner")
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    @IBAction func apertureClicked(_ sender: Any) {
        AppManager.shared.chosenApp = oldOS ? .finalCutPro7 : .aperture
        AppFinder.shared.comingFromChoiceVC = true
        AppFinder.shared.queryAllInstalledApps()
    }
    
    @IBAction func iphotoClicked(_ sender: Any) {
        AppManager.shared.chosenApp = oldOS ? .logicPro9 : .iphoto
        AppFinder.shared.comingFromChoiceVC = true
        AppFinder.shared.queryAllInstalledApps()
    }
    
    @IBAction func itunesClicked(_ sender: Any) {
        if (oldOS == true) {
            AppManager.shared.chosenApp = .keynote5
            AppFinder.shared.comingFromChoiceVC = true
            AppFinder.shared.queryAllInstalledApps()
//            AppDelegate.showTextSheet(title: "iTunes is already installed", text: "iTunes is already installed on \(ProcessInfo.versionString) by default. \n\nIf you need to run iTunes after upgrading to macOS Catalina, open Retroactive again after upgrading to macOS Catalina.")
            return
        }
        AppManager.shared.chosenApp = oldOS ? .keynote5 : .itunes
        let versionVC = VersionViewController.instantiate()
        self.navigationController.pushViewController(versionVC, animated: true)
    }
    
}
