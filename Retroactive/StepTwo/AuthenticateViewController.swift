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
    @IBOutlet weak var catchContainerView: NSView!
    var catchViewController: CatchViewController?
    
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
        
        if (AppManager.shared.needsToShowCatch) {
            catchViewController = CatchViewController.instantiate()
            catchViewController?.dimSourceViewController = self
            if let catchView = catchViewController?.view {
                catchContainerView.addSubview(catchView)
                iconView.frame = CGRect(x: 447, y: 339, width: 143, height: 143)
            }
        } else {
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
        _ = AppManager.runTask(toolPath: "/usr/bin/defaults", arguments: ["write", kXcodeGlobalPreferencePath, kXcodeIDELastGMLicenseAgreedToKey, "-string", kXcodeMaxEAString], path: tempDir)
        _ = AppManager.runTask(toolPath: "/usr/bin/defaults", arguments: ["write", kXcodeGlobalPreferencePath, kXcodeIDELastBetaLicenseAgreedTo, "-string", kXcodeMaxEAString], path: tempDir)
        _ = AppManager.runTask(toolPath: "/usr/bin/defaults", arguments: ["write", kXcodeGlobalPreferencePath, kXcodeIDEXcodeVersionForAgreedToGMLicense, "-string", kXcodeMaxVersionString], path: tempDir)
        _ = AppManager.runTask(toolPath: "/usr/bin/defaults", arguments: ["write", kXcodeGlobalPreferencePath, kXcodeIDEXcodeVersionForAgreedToBetaLicense, "-string", kXcodeMaxVersionString], path: tempDir)
        _ = AppManager.runTask(toolPath: "/usr/bin/xattr", arguments: ["-d", "com.apple.quarantine", appPath], path: tempDir)
        _ = AppManager.runTask(toolPath: "/usr/bin/plutil", arguments: ["-replace", kLSMinimumSystemVersion, "-string", "10.14", "\(appPath)/Contents/Info.plist"], path: tempDir)
        _ = AppManager.runTask(toolPath: "/usr/bin/touch", arguments: [appPath], path: tempDir)
        AppManager.shared.allowPatchingAgain = false
        AppDelegate.pushCompletionVC()
    }
    
    
}
