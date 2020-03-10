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
        if (AppManager.runUnameToPreAuthenticate() != errAuthorizationSuccess) {
            return
        }
        if (AppManager.shared.chosenApp == .xcode) {
            patchXcode()
            return
        }
        self.navigationController.pushViewController(ProgressViewController.instantiate(), animated: true)
    }
    
    @IBAction func viewSourceClicked(_ sender: Any) {
        AppDelegate.current.viewSource()
    }
    
    func patchXcode() {
        guard let appPath = AppManager.shared.appPathCString else { return }
        _ = AppManager.runTask(toolPath: "/usr/bin/xattr", arguments: ["-d", "com.apple.quarantine", appPath], path: tempDir)
        _ = AppManager.runTask(toolPath: "/usr/bin/plutil", arguments: ["-replace", kLSMinimumSystemVersion, "-string", "10.14", "\(appPath)/Contents/Info.plist"], path: tempDir)
        AppDelegate.pushCompletionVC()
    }
    
    
}
