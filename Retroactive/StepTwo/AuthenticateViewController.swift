//
//  SearchViewController.swift
//  Retroactive
//

import Cocoa

class AuthenticateViewController: NSViewController {
    @IBOutlet weak var iconView: DisplayOnlyImageView!
    @IBOutlet weak var searchingForLabel: DisplayOnlyTextField!
    @IBOutlet weak var explainationLabel: DisplayOnlyTextField!
    @IBOutlet weak var authenticateButton: AccentGradientButton!
    @IBOutlet weak var authenticateLabel: DisplayOnlyTextField!
    @IBOutlet weak var viewSourceButton: HoverButton!
    @IBOutlet weak var appLocationTextField: DisplayOnlyTextField!
    @IBOutlet weak var virtualMachineBox: NSBox!
    @IBOutlet weak var chosenAppVMTitleField: NSTextField!
    @IBOutlet weak var chosenAppVMDescriptionField: NSTextField!
    @IBOutlet weak var currentVMIconImageView: NSImageView!
    
    static func instantiate() -> AuthenticateViewController {
        return NSStoryboard.standard!.instantiateController(withIdentifier: "AuthenticateViewController") as! AuthenticateViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        iconView.updateIcon()
        searchingForLabel.updateToken()
        explainationLabel.updateToken()
        authenticateLabel.moveIntoView(authenticateButton)
        viewSourceButton.updateTitle()
        appLocationTextField.stringValue = AppManager.shared.locationOfChosenApp ?? ""
        
        if (AppManager.shared.likelyInVirtualMachine && AppManager.shared.chosenAppHasLimitedFeaturesInVirtualMachine) {
            virtualMachineBox.isHidden = false
            iconView.frame = CGRect(x: 447, y: 339, width: 143, height: 143)
            chosenAppVMTitleField.stringValue = AppManager.shared.chosenAppVMTitle
            chosenAppVMDescriptionField.stringValue = AppManager.shared.chosenAppVMDescription
            currentVMIconImageView.image = AppManager.shared.currentVMImage
        } else {
            virtualMachineBox.isHidden = true
            iconView.frame = CGRect(x: 388, y: 335, width: 260, height: 260)
        }
    }
    
    @IBAction func authenticateClicked(_ sender: Any) {
        let authenticateStatus = STPrivilegedTask.preAuthenticate()
        if (authenticateStatus == errAuthorizationSuccess) {
            self.navigationController.pushViewController(ProgressViewController.instantiate(), animated: true)
        }
    }
    
    @IBAction func viewSourceClicked(_ sender: Any) {
        AppDelegate.current.viewSource()
    }
    
    
}
