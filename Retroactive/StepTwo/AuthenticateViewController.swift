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
