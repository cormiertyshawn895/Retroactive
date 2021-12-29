//
//  CatchViewController.swift
//  Retroactive
//
//  Created by Tyshawn on 4/5/20.
//

import Foundation

class CatchViewController: NSViewController {
    @IBOutlet weak var virtualMachineBox: NSBox!
    @IBOutlet weak var chosenAppVMTitleField: NSTextField!
    @IBOutlet weak var chosenAppVMDescriptionField: NSTextField!
    @IBOutlet weak var currentVMIconImageView: NSImageView!
    @IBOutlet weak var workaroundButton: HoverButton!
    @IBOutlet weak var workaroundLearnMoreButton: HoverButton!
    weak var dimSourceViewController: NSViewController?
    
    static func instantiate() -> CatchViewController {
        return NSStoryboard.standard!.instantiateController(withIdentifier: "CatchViewController") as! CatchViewController
    }
    
    override func viewDidLoad() {
        let showiTunesWorkaround = AppManager.shared.needsToShowiTunesWorkaround
        workaroundButton.isHidden = !showiTunesWorkaround
        workaroundLearnMoreButton.isHidden = !showiTunesWorkaround
        if (showiTunesWorkaround) {
            workaroundButton.title = "Get Apple Configurator 2".localized() + " ↗"
            workaroundLearnMoreButton.title = "Learn how to download an iOS app with Apple Configurator 2".localized() + " ↗"
        }
        chosenAppVMTitleField.stringValue = AppManager.shared.chosenAppVMTitle
        chosenAppVMDescriptionField.stringValue = AppManager.shared.chosenAppVMDescription
        currentVMIconImageView.image = AppManager.shared.currentVMImage
    }

    @IBAction func workaroundClicked(_ sender: Any) {
        AppDelegate.current.safelyOpenURL(AppManager.shared.configuratorURL)
    }
    
    @IBAction func workaroundLearnMoreClicked(_ sender: Any) {
        TutorialViewController.presentFromViewController(dimSourceViewController ?? self)
    }
}
