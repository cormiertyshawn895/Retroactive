//
//  ChoiceViewController.swift
//  Retroactive
//

import Cocoa

let searchDisplayName = "kMDItemDisplayName"
let searchContentTypeTree = "kMDItemContentTypeTree"
let searchBundleIdentifier = "kMDItemCFBundleIdentifier"
let searchPath = "kMDItemPath"
let bundleContentType = "com.apple.application-bundle"
let debugAlwaysPatch = true

class ChoiceViewController: NSViewController {
    @IBOutlet weak var getStartedSubTitle: DisplayOnlyTextField!
    @IBOutlet weak var otherOSSubtitle: NSTextField!
    @IBOutlet weak var otherOSImageView: NSImageView!
    
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var scrollContentView: NSView!
    var singularVCs: [SingularChoiceViewController] = []
    
    var appFinder: AppFinder?
    
    let marginBetweenApps:CGFloat = 54
    
    static func instantiate() -> ChoiceViewController
    {
        NSStoryboard.standard!.instantiateController(withIdentifier: "ChoiceViewController") as! ChoiceViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let totalCount = AppManager.shared.supportedApps.count
        let clippingWidth = scrollView.bounds.size.width
        var previousView = NSView()

        for i in 0..<totalCount {
            let appType = AppManager.shared.supportedApps[i]
            let singularChoiceVC = SingularChoiceViewController.instantiate()
            singularChoiceVC.loadView()
            singularChoiceVC.correspondingAppType = appType
            let svcView = singularChoiceVC.view
            var start = previousView.frame.origin.x + previousView.frame.size.width + marginBetweenApps
            let endIfFits = svcView.bounds.width * CGFloat(totalCount) + marginBetweenApps * CGFloat(totalCount - 1)
            var end = start + svcView.frame.size.width
            if (clippingWidth >= endIfFits) {
                if (i == 0) {
                    start = (clippingWidth - endIfFits) / 2
                    end = start + svcView.frame.size.width
                }
            } else {
                end += marginBetweenApps
            }
            svcView.frame = CGRect(x: start, y: 0, width: svcView.bounds.width, height: svcView.bounds.height)
            scrollContentView.addSubview(svcView)
            scrollContentView.setFrameSize(NSSize(width: end, height: scrollContentView.frame.size.height))
            singularVCs.append(singularChoiceVC)
            
            previousView = svcView
        }
        getStartedSubTitle.stringValue = AppManager.shared.getStartedSubTitle
        otherOSSubtitle.stringValue = AppManager.shared.otherOSSubtitle
        otherOSImageView.image = AppManager.shared.otherOSImage
    }
    
}

class SingularChoiceViewController: NSViewController {
    var correspondingAppType: AppType? {
        didSet {
            guard let type = correspondingAppType else { return }
            imageView.image = AppManager.shared.cartoonIconForAppType(type)
            nameLabel.stringValue = AppManager.shared.nameForAppType(type)
            actionLabel.stringValue = AppManager.shared.presentTenseActionForAppType(type).uppercased()
        }
    }
    var clickedAction: (() -> Void)?
    
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var actionLabel: NSTextField!
    @IBOutlet weak var actionBox: NSBox!
    @IBOutlet weak var hoverButton: HoverButton!
    
    static func instantiate() -> SingularChoiceViewController {
        NSStoryboard.standard!.instantiateController(withIdentifier: "SingularChoiceViewController") as! SingularChoiceViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.moveIntoView(hoverButton)
        nameLabel.moveIntoView(hoverButton)
        actionBox.moveIntoView(hoverButton)
        actionBox.fillColor = .controlAccentColorPolyfill
    }
    
    @IBAction func sectionClicked(_ sender: Any) {
        print("Clicked on \(String(describing: correspondingAppType))")
        AppManager.shared.chosenApp = correspondingAppType
        if (correspondingAppType == .itunes) {
            AppDelegate.pushVersionVC()
        } else {
            AppFinder.shared.comingFromChoiceVC = true
            AppFinder.shared.queryAllInstalledApps()
        }
    }
}
