//
//  ProgressViewController.swift
//  Retroactive
//

import Cocoa
import CommonCrypto

class ProgressViewController: NSViewController, URLSessionDelegate, URLSessionDataDelegate {
    @IBOutlet weak var progressGrid1: NSView!
    @IBOutlet weak var progressGrid2: NSView!
    @IBOutlet weak var progressGrid3: NSView!
    @IBOutlet weak var progressGrid4: NSView!
    @IBOutlet weak var progressHeading: NSTextField!
    @IBOutlet weak var progressCaption: NSTextField!
    @IBOutlet weak var iconImageView: NSImageView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var manualContinueButton: HoverButton!
    
    var subProgress1: SubProgressViewController!
    var subProgress2: SubProgressViewController!
    var subProgress3: SubProgressViewController!
    var subProgress4: SubProgressViewController!
    var progressTimer: Timer?
    
    var session: URLSession?
    var dataTask: URLSessionDataTask?
    var isDownloadMode = false
    var isProVideoUpdate = false
    
    var expectedContentLength = 0
    var fileHandle: FileHandle?

    static func instantiate() -> ProgressViewController
    {
        return NSStoryboard.standard!.instantiateController(withIdentifier: "ProgressViewController") as! ProgressViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        manualContinueButton.updateTitle()
        progressHeading.updateToken()
        progressCaption.updateToken()
        
        isProVideoUpdate = AppManager.shared.chosenApp == .proVideoUpdate
        isDownloadMode = AppManager.shared.chosenApp == .itunes || isProVideoUpdate
        let shortName = AppManager.shared.spaceConstrainedNameOfChosenApp
        
        subProgress1 = SubProgressViewController.instantiate()
        progressGrid1.addSubview(subProgress1.view)
        subProgress1.descriptionTextField.stringValue = isDownloadMode ? String(format: "Download %@".localized(), shortName) : "Copy support files".localized()
        subProgress1.sequenceLabel.stringValue = "1"
        if (isDownloadMode) {
            subProgress1.circularProgress.isIndeterminate = false
        }

        subProgress2 = SubProgressViewController.instantiate()
        progressGrid2.addSubview(subProgress2.view)
        subProgress2.sequenceLabel.stringValue = "2"
        subProgress2.descriptionTextField.stringValue = isDownloadMode ? String(format: "Extract %@".localized(), shortName) : "Install support files".localized()

        let installString = String(format: "Install %@".localized(), shortName)
        let configureString = String(format: "Configure %@".localized(), shortName)
        
        subProgress3 = SubProgressViewController.instantiate()
        progressGrid3.addSubview(subProgress3.view)
        subProgress3.sequenceLabel.stringValue = "3"
        subProgress3.descriptionTextField.stringValue = isDownloadMode ? configureString : String(format: "Refresh %@ icon".localized(), AppManager.shared.nameOfChosenApp)

        subProgress4 = SubProgressViewController.instantiate()
        progressGrid4.addSubview(subProgress4.view)
        subProgress4.sequenceLabel.stringValue = "4"
        subProgress4.descriptionTextField.stringValue = isDownloadMode ? installString : String(format: "Sign %@".localized(), AppManager.shared.nameOfChosenApp)

        iconImageView.updateIcon()
        
        if (isDownloadMode && AppManager.shared.choseniTunesVersion == .darkMode) {
            progressCaption.stringValue = "\(progressCaption.stringValue) " + "It is completely normal for the fans to spin up during the process.".localized()
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        STPrivilegedTask.preventSleep()
        
        let authStatus = AppManager.runUnameToPreAuthenticate()
        if (authStatus != errAuthorizationSuccess) {
            AppManager.relaunchDueToAuthenticationFailure(failure: authStatus)
        }
        
        if AppManager.shared.chosenApp == .aperture || AppManager.shared.chosenApp == .iphoto {
            self.kickoffPhotographyAppPatches()
        }

        if AppManager.shared.chosenApp == .itunes {
            self.kickoffLargeDownload()
        }
        
        if AppManager.shared.chosenApp == .finalCutPro7 {
            self.kickoffProVideoAppPatches()
        }
        
        if AppManager.shared.chosenApp == .logicPro9 {
            self.kickoffProVideoAppPatches()
        }
        
        if AppManager.shared.chosenApp == .keynote5 {
            self.kickoffProVideoAppPatches(fullMode: false)
        }
        
        if AppManager.shared.chosenApp == .proVideoUpdate {
            let kExpectedFCP7Path = "/Applications/Final Cut Pro.app"
            print("Final Cut Pro 7 found at path \(String(describing: AppManager.shared.locationOfChosenApp))")
            if let foundLocation = AppManager.shared.locationOfChosenApp {
                if (foundLocation != kExpectedFCP7Path) {
                    print("Final Cut Pro 7 found at non-standard path \(foundLocation), let's move it before updating")
                    self.runTask(toolPath: "/bin/mv", arguments: [kExpectedFCP7Path, "/Applications/Final Cut Pro Backup.app"])
                    self.runTask(toolPath: "/bin/mv", arguments: [foundLocation, kExpectedFCP7Path])
                }
            }
            self.kickoffLargeDownload()
        }

    }
    
    func runNonAdminTask(toolPath: String, arguments: [String]) {
        Process.runNonAdminTask(toolPath: toolPath, arguments: arguments)
    }
    
    func kickoffProVideoAppPatches(fullMode: Bool = true) {
        guard let appPath = AppManager.shared.appPathCString else { return }
        
        let resourcePath = Bundle.main.resourcePath!.fileSystemString

        DispatchQueue.global(qos: .userInteractive).async {
            self.stage1Started()
            self.runTask(toolPath: "/usr/bin/xattr", arguments: ["-d", "com.apple.quarantine", "\(appPath)"])

            self.stage2Started()
            let fixerPath = "\(appPath)/\(AppManager.shared.fixerFrameworkSubPath)"
            let appMacOSPath = "\(appPath)/Contents/MacOS"
            let appBinaryPath = "\(appMacOSPath)/\(AppManager.shared.binaryNameOfChosenApp)"
            let appMinSysPath = "\(appPath)/Contents/Resources/minsys.plist"
            let macAppBinaryPathUnderscore = "\(appBinaryPath)_"
            
            let kAppKitShimPath =  "/Library/Frameworks/AppKit.framework"
            // On some machines, dyld doesn't want to load AppKit from /Library/Frameworks. To guarantee the AppKit shim is loaded via
            // DYLD_FRAMEWORK_PATH, let's also copy it to the app's Frameworks directory.
            let kAppKitSecondaryShimPath =  "\(appPath)/Contents/Frameworks/AppKit.framework"

            let kLibraryFrameworkPath = "/Library/Frameworks"
            let kBrowserKitCopyPath = "\(kLibraryFrameworkPath)/BrowserKit.framework"
            let kProKitCopyPath = "\(kLibraryFrameworkPath)/ProKit.framework"
            let kAudioToolboxCopyPath = "\(appPath)/Contents/Frameworks/AudioToolbox.framework"
            let fsCustomSettingsPath = kCustomSettingsPath.fileSystemString

            if (fullMode == true) {
                // It shouldn't be possible to have ProKit or BrowserKit at /System/Library/Frameworks on High Sierra or Mojave, and deleting them will fail with SIP.
                // Handle the corner for those who manually copied or installed old versions ProKit.
                self.runTaskAtTemp(toolPath: "/bin/rm", arguments: ["-rf", "/System/Library/Frameworks/ProKit.framework"])
                self.runTaskAtTemp(toolPath: "/bin/rm", arguments: ["-rf", "/System/Library/Frameworks/BrowserKit.framework"])
                self.runTaskAtTemp(toolPath: "/bin/rm", arguments: ["-rf", "/System/Library/PrivateFrameworks/ProKit.framework"])
                self.runTaskAtTemp(toolPath: "/bin/rm", arguments: ["-rf", "/System/Library/PrivateFrameworks/BrowserKit.framework"])

                self.runTaskAtTemp(toolPath: "/bin/rm", arguments: ["-rf", kAppKitShimPath])
                self.runTaskAtTemp(toolPath: "/bin/rm", arguments: ["-rf", kAppKitSecondaryShimPath])
                self.runTaskAtTemp(toolPath: "/bin/rm", arguments: ["-rf", kBrowserKitCopyPath])
                self.runTaskAtTemp(toolPath: "/bin/rm", arguments: ["-rf", kProKitCopyPath])
                self.runTask(toolPath: "/bin/cp", arguments: ["-R", "\(resourcePath)/AppKit", kAppKitShimPath])
                self.runTask(toolPath: "/bin/cp", arguments: ["-R", "\(resourcePath)/AppKit", kAppKitSecondaryShimPath])
                
                if (AppManager.shared.likelyInVirtualMachine && AppManager.shared.chosenApp == .finalCutPro7) {
                    print("In virtual machine and unlocking Final Cut Pro 7. Delete minsys.plist and AudioToolbox framework.")
                    self.runTask(toolPath: "/bin/rm", arguments: [appMinSysPath])
                    self.runTaskAtTemp(toolPath: "/bin/rm", arguments: ["-rf", kAudioToolboxCopyPath])
                } else {
                    print("Normally extracting AudioToolbox framework.")
                    self.runTask(toolPath: "/usr/bin/ditto", arguments: ["-xk", "\(resourcePath)/AudioToolbox.framework.zip", kAudioToolboxCopyPath])
                    self.runTask(toolPath: "/bin/chmod", arguments: ["-R", "+r", kAudioToolboxCopyPath])
                }

                self.runTask(toolPath: "/usr/bin/ditto", arguments: ["-xk", "\(resourcePath)/BrowserKit.framework.zip", kBrowserKitCopyPath])
                self.runTask(toolPath: "/usr/bin/ditto", arguments: ["-xk", "\(resourcePath)/ProKit.framework.zip", kProKitCopyPath])
                self.runTask(toolPath: "/bin/chmod", arguments: ["-R", "+r", kBrowserKitCopyPath])
                self.runTask(toolPath: "/bin/chmod", arguments: ["-R", "+r", kProKitCopyPath])
            } else {
                self.runTask(toolPath: "/bin/mkdir", arguments: ["\(appPath)/Contents/Frameworks"])
            }

            // Some pro apps and iWork may hang when submitting information, skip this by setting the defaults key.
            let expandediWork09Path = ("~/Library/Preferences/com.apple.iWork09.plist" as NSString).expandingTildeInPath
            let expandedLogicProPath = ("~/Library/Preferences/com.apple.logic.pro.plist" as NSString).expandingTildeInPath
            self.runNonAdminTask(toolPath: "/usr/bin/defaults", arguments: ["write", expandediWork09Path, "ShouldNotSendRegistration", "-bool", "true"])
            self.runNonAdminTask(toolPath: "/usr/bin/defaults", arguments: ["write", expandediWork09Path, "RegistrationHasBeenSent", "-bool", "true"])
            self.runNonAdminTask(toolPath: "/usr/bin/defaults", arguments: ["write", expandedLogicProPath, "DoNotInformAgainAbout_10.0", "-bool", "true"])
            self.runNonAdminTask(toolPath: "/usr/bin/defaults", arguments: ["write", expandedLogicProPath, "MobileMeStartupCheckDone", "-bool", "true"])
            self.runNonAdminTask(toolPath: "/usr/bin/defaults", arguments: ["write", expandedLogicProPath, "MobileMeStartupCheckDone.0", "-bool", "true"])
            self.runNonAdminTask(toolPath: "/usr/bin/defaults", arguments: ["-currentHost", "write", "com.apple.RegLogicStudio", "AECoreTechDisplayedRegPanelCount", "-int", "1"])
            self.runNonAdminTask(toolPath: "/usr/bin/defaults", arguments: ["write", "com.apple.RegLogicStudio", "AECoreTechRegister", "-bool", "true"])
            self.runNonAdminTask(toolPath: "/usr/bin/defaults", arguments: ["-currentHost", "write", "com.apple.RegLogicStudio", "AECoreTechRegister", "-bool", "true"])
            self.runNonAdminTask(toolPath: "/usr/bin/defaults", arguments: ["-currentHost", "write", "com.apple.RegLogicStudio", "AECoreTechRegSent", "-bool", "true"])

            self.runTask(toolPath: "/bin/chmod", arguments: ["-R", "+r", expandediWork09Path])
            self.runTask(toolPath: "/bin/chmod", arguments: ["-R", "+r", expandedLogicProPath])

            self.runTaskAtTemp(toolPath: "/bin/rm", arguments: ["-rf", fixerPath])
            self.runTask(toolPath: "/bin/cp", arguments: ["-R", "\(resourcePath)/\(AppManager.shared.fixerFrameworkName)", fixerPath])

            self.stage3Started()
            let exists = FileManager.default.fileExists(atPath: macAppBinaryPathUnderscore)
            if (exists) {
                do {
                    if let fileSize = try FileManager.default.attributesOfItem(atPath: appBinaryPath)[.size] as? UInt64 {
                        print("file size of non underscore is \(fileSize) bytes")
                        if (fileSize < 1000) {
                            print("The non underscored file is a fixer, no mach-o binary is smaller than 1000 bytes.")
                            self.runTask(toolPath: "/bin/rm", arguments: ["-rf", appBinaryPath])
                            self.runTask(toolPath: "/bin/mv", arguments: [macAppBinaryPathUnderscore, appBinaryPath])
                        } else {
                            print("The non underscored file probably isn't a fixer because it exceeds 1000 bytes, it probably got there with an app update. Removing the underscored backup.")
                            self.runTask(toolPath: "/bin/rm", arguments: ["-rf", macAppBinaryPathUnderscore])
                        }
                    }
                } catch {
                    print("Can't determine file size, \(error)")
                }
            }

            print("Installing fixer script, and renaming the real binary to be underscored.")
            self.runTask(toolPath: "/bin/mv", arguments: [appBinaryPath, macAppBinaryPathUnderscore])
            self.runTask(toolPath: "/bin/cp", arguments: ["\(resourcePath)/\(AppManager.shared.fixerScriptName)", appBinaryPath])
            self.runTask(toolPath: "/bin/chmod", arguments: ["+x", appBinaryPath])
            self.runTask(toolPath: "/usr/bin/plutil", arguments: ["-replace", kCFBundleVersion, "-string", AppManager.shared.patchedVersionStringOfChosenApp, "Contents/Info.plist"])

            // Having custom settings will hang Final Cut Pro at launch, let's delete it.
            self.runTask(toolPath: "/bin/rm", arguments: ["-rf", fsCustomSettingsPath])

            self.stage4Started()
            self.runTask(toolPath: "/usr/bin/codesign", arguments: ["-fs", "-", appPath, "--deep"])
            self.runTask(toolPath: "/usr/bin/touch", arguments: [appPath])
            self.runTask(toolPath: "/bin/chmod", arguments: ["-R", "+r", appPath])
            self.suppress32BitWarnings()
            self.stage4Finished()
            
            self.showCompletionVC()
        }
    }
    
    func kickoffPhotographyAppPatches() {
        guard let appPath = AppManager.shared.appPathCString else { return }
        
        let resourcePath = Bundle.main.resourcePath!.fileSystemString

        DispatchQueue.global(qos: .userInteractive).async {
            self.stage1Started()
            self.runTask(toolPath: "/usr/bin/xattr", arguments: ["-d", "com.apple.quarantine", "\(appPath)"])

            self.stage2Started()
            let photoFixerPath = "\(appPath)/\(AppManager.shared.fixerFrameworkSubPath)"
            self.runTaskAtTemp(toolPath: "/bin/rm", arguments: ["-rf", photoFixerPath])
            self.runTask(toolPath: "/bin/cp", arguments: ["-R", "\(resourcePath)/NyxAudioAnalysis", "\(appPath)/Contents/Frameworks/NyxAudioAnalysis.framework"])
            self.runTask(toolPath: "/bin/cp", arguments: ["-R", "\(resourcePath)/ApertureFixer", photoFixerPath])

            self.stage3Started()
            ProgressViewController.runTask(toolPath: "install_name_tool_packed", arguments: ["-change", "/Library/Frameworks/NyxAudioAnalysis.framework/Versions/A/NyxAudioAnalysis", "@executable_path/../Frameworks/NyxAudioAnalysis.framework/Versions/A/NyxAudioAnalysis", "\(appPath)/Contents/Frameworks/iLifeSlideshow.framework/Versions/A/iLifeSlideshow"], path: resourcePath)
            ProgressViewController.runTask(toolPath: "insert_dylib", arguments: ["@executable_path/../Frameworks/ApertureFixer.framework/Versions/A/ApertureFixer", "\(appPath)/Contents/MacOS/\(AppManager.shared.binaryNameOfChosenApp)", "--inplace"], path: resourcePath)
            self.runTask(toolPath: "/usr/bin/plutil", arguments: ["-replace", kCFBundleIdentifier, "-string", AppManager.shared.patchedBundleIDOfChosenApp, "Contents/Info.plist"])
            self.runTask(toolPath: "/bin/mkdir", arguments: ["-p", "/Library/Application Support/Aperture/Plug-Ins"])

            self.stage4Started()
            self.runTask(toolPath: "/usr/bin/codesign", arguments: ["-fs", "-", appPath, "--deep"])
            self.runTask(toolPath: "/usr/bin/touch", arguments: [appPath])
            self.runTask(toolPath: "/bin/chmod", arguments: ["-R", "+r", appPath])
            self.stage4Finished()
            
            self.showCompletionVC()
        }
    }
    
    func suppress32BitWarnings() {
        if let resourcePath = Bundle.main.resourcePath?.fileSystemString {
            if (osMinorVersion == 13) {
                print("supporessing 32 bit warnings on High Sierra")
                self.runNonAdminTask(toolPath: "/usr/bin/profiles", arguments: ["install", "-path=\(resourcePath)/HighSierra32Bit.mobileconfig"])
            }
            if (osMinorVersion == 14) {
                print("supporessing 32 bit warnings on Mojave")
                self.runNonAdminTask(toolPath: "/usr/bin/profiles", arguments: ["install", "-path=\(resourcePath)/Mojave32Bit.mobileconfig"])
            }
        }
    }
    
    func showCompletionVC() {
        self.syncMainQueue {
            STPrivilegedTask.allowSleep()
            AppManager.shared.allowPatchingAgain = false
            if (AppManager.shared.needsBashAccess) {
                AppDelegate.pushSyncingVC()
            } else {
                AppDelegate.pushCompletionVC()
            }
        }
    }
    
    func guessProgressForTimer(approximateDuration: Double, startingPercent: Double, endingPercent: Double) {
        self.syncMainQueue {
            self.progressTimer?.invalidate()
            let startTime = Date().timeIntervalSinceReferenceDate
            let sectionalPercent = endingPercent - startingPercent
            let updateClosure = {
                let currentTime = Date().timeIntervalSinceReferenceDate
                let currentPercent = (currentTime - startTime) / approximateDuration
                if (self.progressIndicator.doubleValue < endingPercent - 0.03) {
                    self.progressIndicator.doubleValue = startingPercent + currentPercent * sectionalPercent
                } else if (self.progressIndicator.doubleValue < endingPercent - 0.02) {
                    self.progressIndicator.doubleValue += 0.00001
                } else {
                    self.progressTimer?.invalidate()
                }
            }
            updateClosure()
            self.progressTimer = Timer.scheduledTimer(timeInterval: 1/60, target: BlockOperation {
                updateClosure()
            }, selector: #selector(Operation.main), userInfo: nil, repeats: true)
        }
    }
    
    func stage1Started() {
        self.syncMainQueue {
            self.subProgress1.inProgress = true
        }
    }
    
    func stage2Started() {
        self.syncMainQueue {
            self.subProgress1.inProgress = false
            self.subProgress2.inProgress = true
            if (isDownloadMode) {
                var duration = 15.0
                if AppManager.shared.choseniTunesVersion == .darkMode {
                    duration = 60.0
                }
                self.guessProgressForTimer(approximateDuration: duration, startingPercent: 0.35, endingPercent: isProVideoUpdate ? 0.38 : 0.70)
            } else {
                self.progressIndicator.doubleValue = 0.1
            }
        }
    }
    
    func stage3Started() {
        self.syncMainQueue {
            self.subProgress2.inProgress = false
            self.subProgress3.inProgress = true
            if (isDownloadMode) {
                self.guessProgressForTimer(approximateDuration: 5, startingPercent: isProVideoUpdate ? 0.38 : 0.70, endingPercent: isProVideoUpdate ? 0.40 : 0.88)
            } else {
                self.progressIndicator.doubleValue = 0.3
            }
        }
    }
    
    func stage4Started() {
        self.syncMainQueue {
            self.subProgress3.inProgress = false
            self.subProgress4.inProgress = true
            if (isDownloadMode) {
                self.guessProgressForTimer(approximateDuration: isProVideoUpdate ? 35 : 10, startingPercent: isProVideoUpdate ? 0.40 : 0.88, endingPercent: 1.0)
            } else {
                self.progressIndicator.doubleValue = 0.4
                self.guessProgressForTimer(approximateDuration: 30, startingPercent: 0.4, endingPercent: 1.0)
            }
        }
    }
    
    func stage4Finished() {
        self.syncMainQueue {
            self.progressTimer?.invalidate()
            self.subProgress4.inProgress = false
            self.progressIndicator.doubleValue = 1.0
        }
    }
        
    func runTask(toolPath: String, arguments: [String]) {
        ProgressViewController.runTask(toolPath: toolPath, arguments: arguments, path: AppManager.shared.locationOfChosenApp!)
    }
    
    func runTaskAtTemp(toolPath: String, arguments: [String]) {
        ProgressViewController.runTask(toolPath: toolPath, arguments: arguments, path: tempDir)
    }

    static func runTask(toolPath: String, arguments: [String], path: String, wait: Bool = true, allowError: Bool = false) {
        _ = AppManager.runTask(toolPath: toolPath, arguments: arguments, path: path, wait: wait)
    }
    
    
    // iTunes
    func getGBFreeSpace() -> Double? {
       do {
        let fileAttributes = try FileManager.default.attributesOfFileSystem(forPath: "/")
        if let size = fileAttributes[FileAttributeKey.systemFreeSize] as? Double {
            let gbSize = size / 1000.0 / 1000.0 / 1000.0
            print("Volume Size: \(size), \(gbSize)")
            return gbSize
          }
       } catch { }
       return nil
    }

    func kickoffLargeDownload() {
        guard let urlString = AppManager.shared.downloadURLOfChosenApp, let chosenURL = URL(string: urlString) else { return }
        if let freeSpace = self.getGBFreeSpace() {
            print("free space: \(String(describing: freeSpace))")
            let freeSpaceRequirement = AppManager.shared.choseniTunesVersion == .darkMode ? 20.0 : 2.0
            if (freeSpace < freeSpaceRequirement) {
                let appName = AppManager.shared.nameOfChosenApp
                AppDelegate.showOptionSheet(title: String(format: "There isn't enough free space to install %@".localized(), appName),
                                            text: String(format: "Your startup disk only has %d GB available. To install %@, your startup disk needs to at least have %d GB of available space.\n\nFree up some space and try again.".localized(), Int(freeSpace), appName, Int(freeSpaceRequirement)),
                                            firstButtonText: "Check Again".localized(), secondButtonText: "Cancel".localized(), thirdButtonText: "") { (response) in
                    if (response == .alertFirstButtonReturn) {
                        self.kickoffLargeDownload()
                    } else {
                        self.navigationController.popToRootViewController(animated: true)
                    }
                }
                return
            }
        }
        self.stage1Started()
        self.fileHandle = nil
        self.subProgress1.inProgress = true
        DispatchQueue.global(qos: .userInteractive).async {
            let dmgPath = self.dmgPath
            let exists = FileManager.default.fileExists(atPath: dmgPath)
            if (exists == true) {
                self.guessProgressForTimer(approximateDuration: 15, startingPercent: 0.0, endingPercent: 0.4)
                let shaSum = self.sha256String(fileURL: URL(fileURLWithPath: dmgPath))
                print("shasum is \(shaSum) for \(dmgPath)")
                // Pro App 2010-02, 12.9.5, 12.6.5, 11.4, 10.7
                // shasum -a 256 [file name]
                if ["2c50f7d57d92bd783773c188de8952e2a75b81a8d886a15890d7e0164cabbb43",
                    "defd3e8fdaaed4b816ebdd7fdd92ebc44f12410a0deeb93e34486c3d7390ffb7",
                    "7404f9b766075f45f8441cd0657f51ac227249cf205281212618dffa371c50f0",
                    "70a8369ca794251fb22fd976eb8019001f8178d3e1d5044c22a665cca81b3fd8",
                    "3d92702ac8b7b2a07bcfe13cc6e0ce07c67362eb4bb2db69f3aebc0cbef27548"]
                    .contains(shaSum) {
                    self.syncMainQueue {
                        self.kickOffInstallation()
                    }
                    return
                }
                do {
                    try FileManager.default.removeItem(atPath: dmgPath)
                } catch {
                    print("Deletion \(error)")
                }
            }
            let configuration = URLSessionConfiguration.default
            let manqueue = OperationQueue.main
            self.session = URLSession(configuration: configuration, delegate:self, delegateQueue: manqueue)
            self.dataTask = self.session?.dataTask(with: URLRequest(url: chosenURL))
            self.dataTask?.resume()
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        expectedContentLength = Int(response.expectedContentLength)
        print(expectedContentLength)
        completionHandler(URLSession.ResponseDisposition.allow)

    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // guard let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first else { return }
        let fileURL = URL(fileURLWithPath: dmgPath)
        do {
            try fileHandle = FileHandle(forWritingTo: fileURL)
        } catch {
            print(error)
            do {
                try data.write(to: fileURL, options: .atomic)
            } catch {
                print(error)
            }
        }

        var bufferLength: UInt64 = 0
        if let handle = fileHandle {
            defer {
                fileHandle?.closeFile()
            }
            bufferLength = fileHandle?.seekToEndOfFile() ?? 0
            fileHandle?.write(data)
        }
        
        let percentageDownloaded = Float(bufferLength) / Float(expectedContentLength)
        self.syncMainQueue {
            progressTimer?.invalidate()
            self.subProgress1.circularProgress.progress = Double(percentageDownloaded)
            self.progressIndicator.doubleValue = Double(percentageDownloaded) * 0.35
            self.subProgress1.progressTextField.stringValue = String(format: "%d%% Complete".localized(), Int(percentageDownloaded * 100))
        }
        print("download progress: \(percentageDownloaded)")

    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("download progress, 100%")
        fileHandle?.closeFile()
        if (error != nil) {
            AppDelegate.showOptionSheet(title: String(format: "Unable to download %@".localized(), AppManager.shared.nameOfChosenApp),
                                        text: "\(error?.localizedDescription ?? "The Internet connection appears to be offline.".localized())",
                                        firstButtonText: "Try Again".localized(), secondButtonText: "Cancel".localized(), thirdButtonText: "") { (response) in
                if (response == .alertFirstButtonReturn) {
                    self.kickoffLargeDownload()
                } else {
                    self.navigationController.popToRootViewController(animated: true)
                }
            }
        } else {
            self.kickOffInstallation()
        }
    }
    
    func kickOffInstallation() {
        self.subProgress1.inProgress = false
        
        DispatchQueue.global(qos: .userInteractive).async {
            if AppManager.shared.chosenApp == .proVideoUpdate {
                self.installProAppsUpdate()
                return
            }
            let itunesType = AppManager.shared.choseniTunesVersion
            switch itunesType {
            case .darkMode:
                self.installDarkModeiTunes()
                break
            case .appStore, .classicTheme, .coverFlow:
                self.installPackagediTunes()
                break
            case .none:
                break
            }
        }
    }
    
    var dmgPath: String {
        get {
            let dmgName = AppManager.shared.downloadFileNameOfChosenApp
            let dmgPath = "\(tempDir)/\(dmgName)"
            return dmgPath
        }
    }
    
    func installProAppsUpdate() {
        self.stage2Started()
        self.runTaskAtTemp(toolPath: "/usr/bin/xattr", arguments: ["-d", "com.apple.quarantine", dmgPath])

        let pkgLocation = "ProApplicationsUpdate2010-02.mpkg"
        let distName = "ProApplicationsUpdate2010-02.dist"
        
        let mountName = AppManager.shared.mountDirNameOfChosenApp
        let extractName = AppManager.shared.extractDirNameOfChosenApp

        let mountPath = "\(tempDir)/\(mountName)"
        let badMountPath = "/Volumes/InstallESD"
        let packageExtractionPath = "\(tempDir)/\(extractName)"

        let packagePath = "\(mountPath)/\(pkgLocation.fileSystemString)"
        let afterPackagePath = "\(packageExtractionPath)/\(pkgLocation.fileSystemString)"
        
        self.runTaskAtTemp(toolPath: "/usr/bin/hdiutil", arguments: ["unmount", badMountPath])
        self.runTaskAtTemp(toolPath: "/usr/bin/hdiutil", arguments: ["attach", "-nobrowse", dmgPath, "-mountpoint", mountPath])
        
        self.stage3Started()
        self.runTaskAtTemp(toolPath: "/bin/mkdir", arguments: ["-p", packageExtractionPath])
        self.runTaskAtTemp(toolPath: "/bin/cp", arguments: ["-R", packagePath, afterPackagePath])
        
        self.stage4Started()
        let resourcePath = Bundle.main.resourcePath!.fileSystemString
        self.runTaskAtTemp(toolPath: "/bin/rm", arguments: ["\(packageExtractionPath)/Contents/\(distName)"])
        self.runTaskAtTemp(toolPath: "/bin/cp", arguments: ["\(resourcePath)/ProApplicationsUpdate2010-02.dist", "\(afterPackagePath)/Contents/\(distName)"])

        self.runTaskAtTemp(toolPath: "/usr/sbin/installer", arguments: ["-pkg", afterPackagePath, "-target", "/"])
        self.suppress32BitWarnings()

        self.stage4Finished()
        self.syncMainQueue {
            AppManager.shared.chosenApp = .finalCutPro7
            AppFinder.shared.queryAllInstalledApps()
            manualContinueButton.isHidden = false
        }
    }

    @IBAction func continueClicked(_ sender: Any) {
        AppManager.shared.chosenApp = .finalCutPro7
        AppFinder.shared.queryAllInstalledApps()
    }
    
    func installDarkModeiTunes() {
        self.installiTunesCommon("Packages/Core.pkg", appLocation: "Payload/Applications/iTunes.app")
    }
    
    func installPackagediTunes() {
        self.installiTunesCommon("Install iTunes.pkg", appLocation: "iTunesX.pkg/Payload/Applications/iTunes.app")
    }
    
    func installiTunesCommon(_ pkgLocation: String, appLocation: String) {
        guard let appPath = AppManager.shared.appPathCString else { return }

        self.stage2Started()
        let mountName = AppManager.shared.mountDirNameOfChosenApp
        let extractName = AppManager.shared.extractDirNameOfChosenApp

        let mountPath = "\(tempDir)/\(mountName)"
        let badMountPath = "/Volumes/InstallESD"
        let packageExtractionPath = "\(tempDir)/\(extractName)"

        let packagePath = "\(mountPath)/\(pkgLocation.fileSystemString)"
        let afterPackagePath = "\(packageExtractionPath)/\(appLocation.fileSystemString)"
        
        let patchedVersionString = AppManager.shared.patchedVersionStringOfChosenApp
        
        let resourcePath = Bundle.main.resourcePath!.fileSystemString
        let inAppFrameworksPath = "\(appPath)/Contents/MacOS/iTunes.app/Contents/Frameworks"
        
        self.runTaskAtTemp(toolPath: "/bin/rm", arguments: ["-rf", appPath])
        self.runTaskAtTemp(toolPath: "/usr/bin/hdiutil", arguments: ["unmount", badMountPath])
        self.runTaskAtTemp(toolPath: "/usr/bin/hdiutil", arguments: ["attach", "-nobrowse", dmgPath, "-mountpoint", mountPath])
        
        let stageAfterExpansion = {
            self.stage3Started()
            
            self.runTask(toolPath: "/bin/mkdir", arguments: ["\(appPath)"])
            self.runTask(toolPath: "/bin/mkdir", arguments: ["\(appPath)/Contents"])
            self.runTask(toolPath: "/bin/mkdir", arguments: ["\(appPath)/Contents/MacOS"])
            self.runTask(toolPath: "/bin/mkdir", arguments: ["\(appPath)/Contents/Resources"])
            if (AppManager.shared.choseniTunesVersion == .classicTheme) {
                // iTunes 11.4 asserts when setting frame origin to {nan, nan}. Insert a library to fix it.
                self.runTask(toolPath: "/bin/mkdir", arguments: ["\(appPath)/Contents/Frameworks"])
                self.runTask(toolPath: "/bin/cp", arguments: ["\(resourcePath)/iTunesOriginLauncher", "\(appPath)/Contents/MacOS/iTunes"])
                self.runTask(toolPath: "/bin/cp", arguments: ["-R", "\(resourcePath)/OriginFixer", "\(appPath)/\(AppManager.shared.fixerFrameworkSubPath)"])
            } else {
                self.runTask(toolPath: "/bin/cp", arguments: ["\(resourcePath)/iTunesLauncher", "\(appPath)/Contents/MacOS/iTunes"])
            }
            self.runTask(toolPath: "/bin/cp", arguments: ["\(resourcePath)/iTunesLauncher-Info.plist", "\(appPath)/Contents/Info.plist"])
            self.runTask(toolPath: "/bin/cp", arguments: ["\(resourcePath)/iTunesLauncher-PkgInfo", "\(appPath)/Contents/PkgInfo"])
            self.runTaskAtTemp(toolPath: "/bin/cp", arguments: ["\(afterPackagePath)/Contents/Resources/iTunes.icns", "\(appPath)/Contents/Resources/iTunes.icns"])
            self.runTaskAtTemp(toolPath: "/usr/bin/plutil", arguments: ["-replace", kCFBundleVersion, "-string", patchedVersionString, "\(appPath)/Contents/Info.plist"])
            self.runTaskAtTemp(toolPath: "/usr/bin/plutil", arguments: ["-replace", kCFBundleShortVersionString, "-string", patchedVersionString, "\(appPath)/Contents/Info.plist"])
            self.runTask(toolPath: "/usr/bin/codesign", arguments: ["-fs", "-", appPath, "--deep"])
            
            self.stage4Started()
            Permission.shared.updateThrowawayApp()
            self.runTaskAtTemp(toolPath: "/bin/cp", arguments: ["-R", afterPackagePath, "\(appPath)/Contents/MacOS/iTunes.app"])
            
            // Copy additional frameworks for iTunes 10.7 and iTunes 11.4. Other versions of iTunes will break with additional frameworks.
            if (AppManager.shared.choseniTunesVersion == .coverFlow) {
                self.runTaskAtTemp(toolPath: "/bin/cp", arguments: ["-R", "\(packageExtractionPath)/CoreFP.pkg/Payload/System/Library/PrivateFrameworks/CoreFP.framework", "\(inAppFrameworksPath)/CoreFP.framework"])
                self.runTaskAtTemp(toolPath: "/bin/cp", arguments: ["-R", "\(packageExtractionPath)/iTunesAccess.pkg/Payload/System/Library/PrivateFrameworks/iTunesAccess.framework", "\(inAppFrameworksPath)/iTunesAccess.framework"])
                self.runTaskAtTemp(toolPath: "/bin/cp", arguments: ["-R", "\(packageExtractionPath)/iTunesLibrary.pkg/Payload/System/Library/Frameworks/iTunesLibrary.framework", "\(inAppFrameworksPath)/iTunesLibrary.framework"])
                self.runTaskAtTemp(toolPath: "/bin/cp", arguments: ["-R", "\(packageExtractionPath)/MobileDevice.pkg/Payload/System/Library/PrivateFrameworks/DeviceLink.framework", "\(inAppFrameworksPath)/DeviceLink.framework"])
            }
            
            if (AppManager.shared.choseniTunesVersion == .classicTheme) {
                self.runTaskAtTemp(toolPath: "/bin/cp", arguments: ["-R", "\(packageExtractionPath)/CoreADI.pkg/Payload/System/Library/PrivateFrameworks/CoreADI.framework", "\(inAppFrameworksPath)/CoreADI.framework"])
                self.runTaskAtTemp(toolPath: "/bin/cp", arguments: ["-R", "\(packageExtractionPath)/CoreFP.pkg/Payload/System/Library/PrivateFrameworks/CoreFP.framework", "\(inAppFrameworksPath)/CoreFP.framework"])
                self.runTaskAtTemp(toolPath: "/bin/cp", arguments: ["-R", "\(packageExtractionPath)/iTunesAccess.pkg/Payload/System/Library/PrivateFrameworks/iTunesAccess.framework", "\(inAppFrameworksPath)/iTunesAccess.framework"])
                self.runTaskAtTemp(toolPath: "/bin/cp", arguments: ["-R", "\(packageExtractionPath)/iTunesX.pkg/Payload/Library/Frameworks/iTunesLibrary.framework", "\(inAppFrameworksPath)/iTunesLibrary.framework"])
                self.runTaskAtTemp(toolPath: "/bin/cp", arguments: ["-R", "\(packageExtractionPath)/MobileDevice.pkg/Payload/System/Library/PrivateFrameworks/AirTrafficHost.framework", "\(inAppFrameworksPath)/AirTrafficHost.framework"])
                self.runTaskAtTemp(toolPath: "/bin/cp", arguments: ["-R", "\(packageExtractionPath)/MobileDevice.pkg/Payload/System/Library/PrivateFrameworks/DeviceLink.framework", "\(inAppFrameworksPath)/DeviceLink.framework"])
            }
            
            // iTunes 12.6.5 needs inverted icon masking.
            if (AppManager.shared.choseniTunesVersion == .appStore) {
                if let appLocation = AppManager.shared.locationOfChosenApp {
                    let innerAssetRegularPath = "\(appLocation)/Contents/MacOS/iTunes.app/Contents/Resources/Assets.car"
                    let innerAssetCatalogCPath = innerAssetRegularPath.fileSystemString
                    let shaSum = self.sha256String(fileURL: URL(fileURLWithPath: innerAssetRegularPath))
                    let expected = "39b9cbc589ee26b34850c1956c6a1eb367310c9d1a8d22606084c532d06ab895"
                    if shaSum == expected {
                        print("SHA 256 checksum matches stock iTunes 12.6.5 Assets.car")
                        self.runTaskAtTemp(toolPath: "/usr/bin/bspatch", arguments: [innerAssetCatalogCPath, innerAssetCatalogCPath, "\(resourcePath)/iTunes12_6_5_Assets_Diff.bin"])
                    } else {
                        print("SHA 256 checksum mismatch. Expected: \(expected), actual: \(shaSum)")
                    }
                }
                
                // Clear artwork cache
                if let path = AppManager.shared.iTunesLibraryPath {
                    let artworkCachePath = path.stringByAppendingPathComponent(path: "Album Artwork").stringByAppendingPathComponent(path: "Cache")
                    do {
                        print("Found artwork cache path \(artworkCachePath)")
                        try FileManager.default.removeItem(atPath: artworkCachePath)
                        print("Deleted artwork cache")
                    } catch {
                        print("Can't remove album artwork cache, \(error)")
                    }
                }
            }
            self.runTaskAtTemp(toolPath: "/usr/bin/touch", arguments: [appPath])
            self.runTask(toolPath: "/usr/bin/xattr", arguments: ["-d", "com.apple.quarantine", "\(appPath)"])

            self.stage4Finished()
            self.showCompletionVC()
        }
        
        if AppManager.shared.choseniTunesVersion == .darkMode {
            print("Chosen Dark Mode iTunes")
            if #available(OSX 10.12, *) {
                let timer = Timer.init(timeInterval: 15.0, repeats: true) { (timer) in
                    print("Timer fired to seek for extraction progress")
                    let libraryPath = "\(packageExtractionPath)/Payload/Library"
                    let libraryExists = FileManager.default.fileExists(atPath: libraryPath)
                    let afterPackageExists = FileManager.default.fileExists(atPath: afterPackagePath)
                    print("libraryPath = \(libraryPath), libraryExists = \(libraryExists), afterPackageExists = \(afterPackageExists)")
                    if libraryExists && afterPackageExists {
                        // Extracting the entire macOS installer takes way too long
                        // Kill pkg extraction before fans spin up too loud
                        ProgressViewController.runTask(toolPath: "killpkg", arguments: [], path: resourcePath)
                        timer.invalidate()
                        stageAfterExpansion()
                    }
                }
                RunLoop.main.add(timer, forMode: .common)
                ProgressViewController.runTask(toolPath: "/usr/sbin/pkgutil", arguments: ["--expand-full", packagePath, packageExtractionPath], path: tempDir, wait: false)
            }
        }
    
        if AppManager.shared.choseniTunesVersion != .darkMode {
            self.runTaskAtTemp(toolPath: "/usr/sbin/pkgutil", arguments: ["--expand-full", packagePath, packageExtractionPath])
            self.runTaskAtTemp(toolPath: "/usr/bin/hdiutil", arguments: ["unmount", mountPath])
            stageAfterExpansion()
        }
    }
    
    func sha256String(fileURL: URL) -> String {
        if let digestData = sha256(url: fileURL) {
            let calculatedHash = digestData.map { String(format: "%02hhx", $0) }.joined()
            return calculatedHash
        }
        return ""
    }
    
    func sha256(url: URL) -> Data? {
        do {
            let bufferSize = 1024 * 1024
            // Open file for reading:
            let file = try FileHandle(forReadingFrom: url)
            defer {
                file.closeFile()
            }

            // Create and initialize SHA256 context:
            var context = CC_SHA256_CTX()
            CC_SHA256_Init(&context)

            // Read up to `bufferSize` bytes, until EOF is reached, and update SHA256 context:
            while autoreleasepool(invoking: {
                // Read up to `bufferSize` bytes
                let data = file.readData(ofLength: bufferSize)
                if data.count > 0 {
                    data.withUnsafeBytes {
                        _ = CC_SHA256_Update(&context, $0, numericCast(data.count))
                    }
                    // Continue
                    return true
                } else {
                    // End of file
                    return false
                }
            }) { }

            // Compute the SHA256 digest:
            var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
            digest.withUnsafeMutableBytes {
                _ = CC_SHA256_Final($0, &context)
            }

            return digest
        } catch {
            print(error)
            return nil
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        if (isDownloadMode) {
            let mountPath = "\(tempDir)/\(AppManager.shared.mountDirNameOfChosenApp)"
            self.runTaskAtTemp(toolPath: "/usr/bin/hdiutil", arguments: ["unmount", mountPath])
        }
    }

}
