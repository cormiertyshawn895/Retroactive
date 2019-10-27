//
//  ChoiceViewController.swift
//  Retroactive
//

import Cocoa

let searchDisplayName = "kMDItemDisplayName"
let searchContentType = "kMDItemContentType"
let searchBundleIdentifier = "kMDItemCFBundleIdentifier"
let searchPath = "kMDItemPath"
let bundleContentType = "com.apple.application-bundle"
let debugAlwaysPatch = true

class ChoiceViewController: NSViewController {
    @IBOutlet weak var apertureButton: NSButton!
    @IBOutlet weak var iphotoButton: NSButton!
    @IBOutlet weak var itunesButton: NSButton!
    weak var shiningOnButton: NSButton?
    var appFinder: AppFinder?
    
    static func instantiate() -> ChoiceViewController
    {
        NSStoryboard.main!.instantiateController(withIdentifier: "ChoiceViewController") as! ChoiceViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    @IBAction func apertureClicked(_ sender: Any) {
        AppManager.shared.chosenApp = .aperture
        AppFinder.shared.comingFromChoiceVC = true
        AppFinder.shared.queryAllInstalledApps()
    }
    
    @IBAction func iphotoClicked(_ sender: Any) {
        AppManager.shared.chosenApp = .iphoto
        AppFinder.shared.comingFromChoiceVC = true
        AppFinder.shared.queryAllInstalledApps()
    }
    
    @IBAction func itunesClicked(_ sender: Any) {
        AppManager.shared.chosenApp = .itunes
        let versionVC = VersionViewController.instantiate()
        self.navigationController.pushViewController(versionVC, animated: true)
    }
    
}
