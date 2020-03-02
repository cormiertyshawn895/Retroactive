import Cocoa

let fullDiskAccessURL = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
let retroactiveBundleIdentifier = "com.retroactive.Retroactive"
let systemPreferencesIdentifier = "com.apple.systempreferences"

class SyncingViewController: NSViewController, GuaranteeViewControllerDelegate, DragFileViewDelegate, PadlockViewControllerDelegate {
    @IBOutlet weak var fullDiskAccessButtonLabel: DisplayOnlyTextField!
    @IBOutlet weak var fullDiskAccessButton: AccentGradientButton!
    @IBOutlet weak var accordionView: NSView!

    var guaranteeVCs: [GuaranteeViewController] = []
    var padlockVC: PadlockViewController!
    var padlockWindow: NSWindow!
    var draggingVC: UpArrowViewController!
    var dragWindow: NSWindow!
    
    let animationTrackingInterval: TimeInterval = 1.0 / 60.0
    var windowTrackingTimer: Timer?
    var mostRecentPrefsFrame: CGRect?
    var shouldShowDragBashView = false
    var prefsAppName = "System Preferences"
    
    static func instantiate() -> SyncingViewController {
        return NSStoryboard.standard!.instantiateController(withIdentifier: "SyncingViewController") as! SyncingViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        padlockVC = PadlockViewController.instantiate()
        padlockVC.delegate = self
        padlockWindow = NSWindow.createFloatingAccessoryWindow(padlockVC)
        draggingVC = UpArrowViewController.instantiate()
        draggingVC.loadView()
        draggingVC.draggingView.delegate = self
        dragWindow = NSWindow.createFloatingAccessoryWindow(draggingVC)
        
        fullDiskAccessButtonLabel.addShadow()
        fullDiskAccessButtonLabel.moveIntoView(fullDiskAccessButton)
        
        populateGuarantees()
    }
    
    deinit {
        windowTrackingTimer?.invalidate()
        padlockWindow.close()
        dragWindow.close()
    }

    func populateGuarantees() {
        let guarantees: [GuaranteeSection] = [
            GuaranteeSection(title: "Why does iPod syncing need Full Disk Access?".localized(),
                             explaination: "iPod devices are considered as removable storage by macOS Catalina. iTunes needs Full Disk Access to access removable storage and shared network drives.".localized(),
                             buttonText: nil,
                             buttonAction: nil),
            GuaranteeSection(title: "Can I use iTunes without Full Disk Access?".localized(),
                             explaination: "Yes, you can. However, iTunes will not sync with iPod devices, play music on removable storage, or access shared iTunes libraries on a network drive.".localized(),
                             buttonText: "Use iTunes without Full Disk Access".localized() + disclosureString,
                             buttonAction: { self.skipSyncingClicked(self) }),
            GuaranteeSection(title: "Why isn’t this more granular?".localized(),
                             explaination: "While apps optimized for macOS Catalina can request granular access to Removable Volumes, iTunes was built before macOS Catalina. Retroactive’s loader script has similar requirements.".localized(),
                             buttonText: nil,
                             buttonAction: nil)
        ]

        accordionView.translatesAutoresizingMaskIntoConstraints = false
        var previousAnchor: NSLayoutAnchor = accordionView.topAnchor

        for (index, guarantee) in guarantees.enumerated() {
            let guaranteeVC = GuaranteeViewController(guarantee: guarantee)
            guaranteeVC.delegate = self
            guaranteeVC.view.translatesAutoresizingMaskIntoConstraints = false
            accordionView.addSubview(guaranteeVC.view)
            NSLayoutConstraint.activate([
                guaranteeVC.view.leadingAnchor.constraint(equalTo: accordionView.leadingAnchor),
                guaranteeVC.view.trailingAnchor.constraint(equalTo: accordionView.trailingAnchor),
                guaranteeVC.view.topAnchor.constraint(equalTo: previousAnchor)
            ])
            previousAnchor = guaranteeVC.view.bottomAnchor
            if index == guarantees.endIndex - 1 {
                guaranteeVC.dividorBox.isHidden = true
            }
            guaranteeVCs.append(guaranteeVC)
        }
        
        guaranteeVCs.first?.expand()
    }
    
    func startShowingTips() {
        windowTrackingTimer = Timer.scheduledTimer(withTimeInterval: animationTrackingInterval, repeats: true) { (timer) in
            self.updateTips()
        }
    }
    
    func updateTips() {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return
        }
        if (frontmostApp.bundleIdentifier == systemPreferencesIdentifier) {
            if let localizedName = frontmostApp.localizedName {
                prefsAppName = localizedName
            }
            padlockWindow.makeKeyAndOrderFront(self)
            dragWindow.makeKeyAndOrderFront(self)
        } else {
            padlockWindow.orderOut(self)
            dragWindow.orderOut(self)
            return
        }

        let cfWindowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID)
        guard let windowList = cfWindowList as? [Dictionary<String, Any>] else {
            return
        }
        var lastWonWindowID: Int = 0
        var lastOrigin: CGPoint = .zero
        var lastWidthHeight: CGSize = CGSize.zero
    
        for window in windowList {
            guard let windowName = window["kCGWindowOwnerName"] as? String else {
                continue
            }
            if (windowName != prefsAppName) {
                continue
            }
            guard let windowBounds = window["kCGWindowBounds"] as? Dictionary<String, Int>,
                let windowNumber = window["kCGWindowNumber"] as? Int,
                let windowX = windowBounds["X"],
                let windowY = windowBounds["Y"],
                let windowWidth = windowBounds["Width"],
                let windowHeight = windowBounds["Height"] else {
                continue
            }
            if (windowNumber > lastWonWindowID) {
                lastWonWindowID = windowNumber
                lastOrigin = CGPoint(x: windowX, y: windowY)
                lastWidthHeight = CGSize(width: windowWidth, height: windowHeight)
            }
        }
        
        let screen = NSScreen.screens.first!
        let yPositionInScreenSpace = screen.frame.size.height - lastOrigin.y - lastWidthHeight.height
        if (lastWidthHeight.similarToSize(CGSize(width: 668, height: 573), maxDeltaX: 80, maxDeltaY: 5)) {
            // Security preferences window is around 668x573
            if (shouldShowDragBashView) {
                padlockWindow.orderOut(self)
                // to drag window
                dragWindow.makeKeyAndOrderFront(self)
                let newX = NSLocale.languageLTR ? lastOrigin.x + 340 : lastOrigin.x + 120
                dragWindow.setFrameOrigin(NSPoint(x: newX,
                                                  y: yPositionInScreenSpace - dragWindow.frame.height + 260))
            } else {
                dragWindow.orderOut(self)
                padlockWindow.makeKeyAndOrderFront(self)
                let newX = NSLocale.languageLTR ? lastOrigin.x - 198 : lastOrigin.x + lastWidthHeight.width - 269
                padlockWindow.setFrameOrigin(NSPoint(x: newX,
                                                      y: yPositionInScreenSpace - padlockWindow.frame.height + 25))
            }
            mostRecentPrefsFrame = CGRect(x: lastOrigin.x, y: lastOrigin.y, width: lastWidthHeight.width, height: lastWidthHeight.height)
        } else if (lastWidthHeight.similarToSize(CGSize(width: 444, height: 212), maxDeltaX: 40, maxDeltaY: 212)) {
            // Password entry
            shouldShowDragBashView = true
            padlockWindow.orderOut(self)
            dragWindow.orderOut(self)
        } else {
            // Main preferences window is around 668x586
            shouldShowDragBashView = false
            padlockWindow.orderOut(self)
            dragWindow.orderOut(self)
            self.view.window?.deminiaturize(self)
            self.view.window?.makeKeyAndOrderFront(self)
        }
    }
    
    func draggingStarted(view: DragFileView, point: NSPoint) {
        self.draggingVC.arrowImageView.alphaValue = 0.3
        self.draggingVC.boxContainer.isHidden = true
    }
    
    func draggingSucceeded(view: DragFileView, point: NSPoint) {
        guard let prefsFrame = mostRecentPrefsFrame else {
            return
        }
        let screen = NSScreen.screens.first!
        let normalizedDragPoint = NSPoint(x: point.x, y: screen.frame.size.height - point.y)
        if !NSPointInRect(normalizedDragPoint, prefsFrame) {
            self.draggingFailed(view: view, point: point)
            return
        }
        pushCompletion()
    }
    
    func draggingFailed(view: DragFileView, point: NSPoint) {
        openFullDiskAccess(shouldTerminate: false)
        self.draggingVC.arrowImageView.alphaValue = 1
        self.draggingVC.boxContainer.isHidden = false
    }
    
    func pushCompletion() {
        windowTrackingTimer?.invalidate()
        padlockWindow.close()
        dragWindow.close()
        self.view.window?.deminiaturize(self)
        terminateSystemPreferences()

        if (self.navigationController != nil) {
            self.navigationController.pushViewController(CompletionViewController.instantiate(), animated: true)
        }
    }
    
    func openFullDiskAccess(shouldTerminate: Bool) {
        if let fullDiskAccessURL = URL(string: fullDiskAccessURL) {
            if (shouldTerminate) {
                self.terminateSystemPreferences()
                Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { (timer) in
                    NSWorkspace.shared.open(fullDiskAccessURL)
                }
            } else {
                NSWorkspace.shared.open(fullDiskAccessURL)
            }
        }
    }
    
    func terminateSystemPreferences() {
        let settingsInstances = NSRunningApplication.runningApplications(withBundleIdentifier: systemPreferencesIdentifier)
        for settings in settingsInstances {
            settings.terminate()
        }
    }
    
    @IBAction func enableFullDiskAccessClicked(_ sender: Any) {
        shouldShowDragBashView = false
        mostRecentPrefsFrame = nil
        padlockWindow.orderOut(self)
        dragWindow.orderOut(self)
        windowTrackingTimer?.invalidate()

        openFullDiskAccess(shouldTerminate: true)
        startShowingTips()
    }
    
    @IBAction func skipSyncingClicked(_ sender: Any) {
        pushCompletion()
    }
    
    func alreadyUnlockedClicked(_ sender: Any) {
        shouldShowDragBashView = true
    }
    
    func viewDidExpand(controller: GuaranteeViewController) {
        for vc in guaranteeVCs {
            if (vc != controller) {
                vc.collapse()
                vc.runAnimationGroup()
            }
        }
    }

}
