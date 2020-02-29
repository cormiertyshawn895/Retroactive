//
//  CompletionViewController.swift
//  Retroactive
//

import Cocoa

class CompletionViewController: NSViewController {
    @IBOutlet weak var iconView: NSImageView!
    @IBOutlet weak var congratulatoryLabel: NSTextField!
    @IBOutlet weak var launchAppButton: NSButton!
    @IBOutlet weak var launchAppLabel: NSTextField!
    @IBOutlet weak var behindTheScenesButton: NSButton!
    @IBOutlet weak var clippingView: NSView!
    @IBOutlet weak var extraInfoLabel: DisplayOnlyTextField!
    @IBOutlet weak var dividerLine: NSBox!
        
    var confettiView: ConfettiView?
    var allowPatchingAgain: Bool = false
    
    static func instantiate() -> CompletionViewController
    {
        return NSStoryboard.standard!.instantiateController(withIdentifier: "CompletionViewController") as! CompletionViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if (allowPatchingAgain == true) {
            behindTheScenesButton.title = NSLocalizedString("Unlock {name} again".localized(), comment: "")
            congratulatoryLabel.stringValue = String(format: "You have already unlocked %@.\nThere's usually no need to unlock it again.".localized(), placeholderToken)
        } else if (AppManager.shared.behindTheScenesOfChosenApp == nil) {
            behindTheScenesButton.isHidden = true
        }
        congratulatoryLabel.updateToken()
        launchAppLabel.updateToken()
        launchAppLabel.addShadow()
        iconView.updateIcon()
        behindTheScenesButton.updateTitle()
        launchAppLabel.moveIntoView(launchAppButton)
        if let knownIssues = AppManager.shared.appKnownIssuesText {
            dividerLine.isHidden = false
            extraInfoLabel.stringValue = String(format: "Note: %@".localized(), knownIssues)
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        addConfettiView()
        confettiView?.startConfetti()
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(stopConfetti), userInfo: nil, repeats: false)
    }
    
    @objc func stopConfetti() {
        self.confettiView?.stopConfetti()
    }
    
    func addConfettiView() {
        confettiView = ConfettiView(frame: self.view.bounds)
        confettiView?.intensity = 1.5
        if let confetti = confettiView {
            self.view.addSubview(confetti)
        }
    }
    
    @IBAction func launchAppClicked(_ sender: Any) {
        if AppManager.shared.chosenApp == .itunes && AppManager.shared.choseniTunesVersion != .darkMode {
            if let path = AppManager.shared.iTunesLibraryPath {
                do {
                    var libraryPath: String?
                    let directoryContents = try FileManager.default.contentsOfDirectory(atPath: path)
                    for content in directoryContents {
                        if (libraryPath == nil && content.hasSuffix(".itl")) || (libraryPath != nil && content == "iTunes Library.itl") {
                            libraryPath = path.stringByAppendingPathComponent(path: content)
                        }
                    }
                    if let libPath = libraryPath {
                        print("Library path is \(libPath)")
                        let data = try Data(contentsOf: URL(fileURLWithPath: libPath))
                        if (data.count > 26) {
                            var values = [UInt8](repeating:0, count:8)
                            data.copyBytes(to: &values, from: 17..<25)
                            print("Library version bytes: \(values)")
                            if let versionString = String(bytes: values, encoding: .ascii) {
                                print("Library version string: \(versionString)")
                                let targetiTunes = AppManager.shared.userFacingLatestShortVersionOfChosenApp
                                if versionString.iTunesIsNewerThan(otheriTunes: targetiTunes) {
                                    print("\(versionString) > \(targetiTunes), prompting to create a new library")
                                    promptToCreateNewLibrary(libPath, installedVersion: targetiTunes, libraryVersion: versionString)
                                    return
                                }
                            }
                        }
                    }
                } catch {
                    print("Can't read iTunes Library data, \(error)")
                }
            }
        }
        if (allowPatchingAgain == true) {
            openApp()
            return
        }
        openApp()
    }
    
    func openApp() {
        if let knownLocation = AppManager.shared.locationOfChosenApp {
            NSWorkspace.shared.launchApplication(knownLocation)
        }
    }
    
    func promptToCreateNewLibrary(_ libraryPath: String, installedVersion: String, libraryVersion: String) {
        var description = String(format: "You have installed an older version of iTunes (%@), which is not compatible with your current iTunes library (%@).\n\nWould you like to create a new iTunes library to use with iTunes %@?".localized(), installedVersion, libraryVersion, installedVersion)
        description = description + "\n\n" + "Don't worry. Your existing iTunes library won't be deleted. Instead, it will be renamed.".localized()
        AppDelegate.showOptionSheet(title: "Would you like to create a new iTunes library?".localized(), text: description, firstButtonText: "Create New Library".localized(), secondButtonText: "Don't Create".localized(), thirdButtonText: "") { (response) in
            if (response == .alertFirstButtonReturn) {
                do {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
                    let dateString = dateFormatter.string(from: Date())
                    let newPath = "\((libraryPath as NSString).deletingPathExtension) \(dateString).itl"
                    try FileManager.default.moveItem(atPath: libraryPath, toPath: newPath)
                } catch {
                    print(error)
                }
            }
            self.openApp()
        }
    }
    
    @IBAction func behindTheScenesClicked(_ sender: Any) {
        if (allowPatchingAgain == true) {
            self.navigationController.pushViewController(AuthenticateViewController.instantiate(), animated: true)
            return
        }
        AppDelegate.current.safelyOpenURL(AppManager.shared.behindTheScenesOfChosenApp)
    }

}
