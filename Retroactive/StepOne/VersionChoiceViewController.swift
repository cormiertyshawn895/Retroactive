//
//  VersionChoiceViewController.swift
//  Retroactive
//

import Cocoa

class VersionChoiceViewController: NSViewController {
    var itunesApp: iTunesApp?
    @IBOutlet weak var screenshotView: NSImageView!
    @IBOutlet weak var featureDescription: NSTextField!
    @IBOutlet weak var versionDescription: NSTextField!
    @IBOutlet weak var checkMark: NSImageView!
    
    static func instantiate() -> VersionChoiceViewController
    {
        return NSStoryboard.standard!.instantiateController(withIdentifier: "VersionChoiceViewController") as! VersionChoiceViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.checkMark.isHidden = true
        self.screenshotView.image = itunesApp?.previewScreenshot
        self.featureDescription.stringValue = itunesApp?.featureDescriptionString ?? ""
        self.versionDescription.stringValue = "iTunes \(itunesApp?.versionNumberString ?? "")"
    }
    
}
