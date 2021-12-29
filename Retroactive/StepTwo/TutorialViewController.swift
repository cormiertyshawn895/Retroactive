//
//  TutorialViewController.swift
//  Retroactive
//
//  Created by Tyshawn on 4/5/20.
//

import Cocoa
import AVKit

class NonRespondingAVPlayerView: AVPlayerView
{
    override var acceptsFirstResponder: Bool {
        return false
    }
    
    override func scrollWheel(with event: NSEvent) {
        return
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        let view = super.hitTest(point)
        if view != self {
            return view
        }
        return nil
    }
    
    override func keyDown(with event: NSEvent) {
        return
    }
}

struct TutorialSection {
    var title: String
    var caption: String
    var interactive: Bool
    var startTime: Double
    var endTime: Double
}

class TutorialViewController: NSViewController {
    var player: AVPlayer?

    @IBOutlet weak var numberLabel: NSTextField!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var captionButton: NSButton!
    @IBOutlet weak var nextButton: HoverButton!
    @IBOutlet weak var indicatorContainerView: NSView!
    
    @IBOutlet weak var playerView: AVPlayerView!
    @IBOutlet weak var closeButton: HoverButton!
    
    var dismissalCallback: (() -> Void)?
    
    var token: Any?
    var sections: [TutorialSection] = [
        TutorialSection(title: "Connect an iOS device to Apple Configurator 2".localized(), caption: "Open Apple Configurator 2, then connect an iOS device to your Mac.".localized(), interactive: false, startTime: 0, endTime: 2.985333333333333),
        TutorialSection(title: "Add Apps".localized(), caption: "Select your device, click “Add”, then click “Apps”.".localized(), interactive: false, startTime: 2.985333333333334, endTime: 6.359988888888889),
        TutorialSection(title: "Add a purchased app".localized(), caption: "Sign in with your Apple ID. Select an app you have already purchased, then click “Add”.".localized(), interactive: false, startTime: 6.359988888888890, endTime: 9.8412),
        TutorialSection(title: "Go to the user Library folder".localized(), caption: "Open Finder. Hold down the ⌥ Key, and choose Go › Library.".localized(), interactive: false, startTime: 9.84121, endTime: 17.001),
        TutorialSection(title: "Open Apple Configurator 2’s temporary folder".localized(), caption: "Group Containers › …configurator › Library › Caches › Assets › TemporaryItems › MobileApps", interactive: true, startTime: 17.0011, endTime: 27.860022222222224),
        TutorialSection(title: "Add MobileApps to Favorites".localized(), caption: "To quickly access IPA downloads in the future, drag the MobileApps folder into Favorites.".localized(), interactive: false, startTime: 27.860022222222225, endTime: 30.028677777777776),
        TutorialSection(title: "Keep drilling down for the IPA".localized(), caption: "Drill in two more levels of temporary folder. You’ll see the app download in IPA format.".localized(), interactive: false, startTime: 30.028677777777777, endTime: 34.48193333333333),
        TutorialSection(title: "Save and install the IPA".localized(), caption: "Drag the IPA to a safe location. To install the app, sync it with Finder or AirDrop it to an iOS device.".localized(), interactive: false, startTime: 34.48193333333334, endTime: 37.44182222222222),
    ]
    
    static func instantiate() -> TutorialViewController {
        return NSStoryboard.standard!.instantiateController(withIdentifier: "TutorialViewController") as! TutorialViewController
    }
    
    static func presentFromViewController(_ viewController: NSViewController) {
        let tutorial = TutorialViewController.instantiate()
        if (viewController is CatchViewController) || osAtLeastBigSur {
            viewController.presentAsSheet(tutorial)
            return
        }

        let darkenView = NSView()
        darkenView.wantsLayer = true
        darkenView.layer?.backgroundColor = NSColor.black.cgColor
        darkenView.alphaValue = 0
        darkenView.frame = viewController.view.bounds
        viewController.view.safelyAddSubview(darkenView)

        tutorial.dismissalCallback = {
            NSAnimationContext.runAnimationGroup({ (context) in
                darkenView.animator().alphaValue = 0
            }) {
                darkenView.removeFromSuperview()
            }
        }
        darkenView.animator().alphaValue = 0.6
        viewController.presentAsSheet(tutorial)
    }
    
    override func viewDidLoad() {
        guard let videoURL = Bundle.main.url(forResource: "ConfiguratorTutorial", withExtension: "mp4") else {
            return
        }
        nextButton.isEnabled = true
        player = AVPlayer(url: videoURL)
        playerView.player = player
        setNextButtonTitle(hasNext: true)
        updateLabelsForIndex(index: 0)
    }
    
    override func viewDidAppear() {
        var times: [NSValue] = []
        for section in sections {
            times.append(section.endTime as NSValue)
        }
        token = player?.addBoundaryTimeObserver(forTimes: times, queue: DispatchQueue.main, using: {
            self.player?.pause()
            self.nextButton.isHidden = false
            if self.player?.approximatingEnd == true {
                self.setNextButtonTitle(hasNext: false)
            }
        })
        self.refreshAndStartPlaying()
    }
    
    @IBAction func dismissClicked(_ sender: Any) {
        player?.pause()
        self.dismiss(self)
        dismissalCallback?()
    }
    
    @IBAction func nextSlideClicked(_ sender: Any) {
        self.refreshAndStartPlaying()
    }
    
    func refreshAndStartPlaying() {
        if player?.approximatingEnd == true {
            player?.seek(to: CMTime.zero)
            setNextButtonTitle(hasNext: true)
        }
        if sections.count == 0 {
            player?.play()
            return
        }
        if let currentTime = player?.currentTimeSeconds {
            var winningSection = 0
            var winningDiff: Double = Double.infinity
            for i in 0..<sections.count {
                let section = sections[i]
                let timeDiff = abs(section.startTime - currentTime)
                if (timeDiff < winningDiff) {
                    winningSection = i
                    winningDiff = timeDiff
                }
            }
            updateLabelsForIndex(index: winningSection)
        }
        player?.play()
        nextButton.isHidden = true
    }
    
    func updateLabelsForIndex(index: Int) {
        if index >= sections.count {
            return
        }
        let matchedSection = sections[index]
        titleLabel.stringValue = matchedSection.title
        captionButton.title = matchedSection.caption
        captionButton.isEnabled = matchedSection.interactive
        if #available(OSX 10.14, *) {
            captionButton.contentTintColor = matchedSection.interactive ? NSColor.controlAccentColorPolyfill : NSColor.textColor
        }
        numberLabel.stringValue = "\(index + 1)"
    }
    
    @IBAction func captionButtonClicked(_ sender: Any) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: ("~/Library/Group Containers/K36BKF7T3D.group.com.apple.configurator/Library/Caches/Assets/TemporaryItems/" as NSString).expandingTildeInPath)
    }
    
    func setNextButtonTitle(hasNext: Bool) {
        nextButton.title = hasNext ? "Next".localized() + disclosureArrow : "Replay".localized() + disclosureLoop
        nextButton.updateTitle(titleSize: 15, chevronSize: hasNext ? 19 : 17.5, chevronOffset: hasNext ? 0.7 : 2)
    }
    
    @IBAction func printTimeClicked(_ sender: Any) {
        if let time = player?.currentTime().seconds {
            print(time)
        }
    }
}

extension AVPlayer {
    var currentTimeSeconds: Double {
        return self.currentTime().seconds
    }
    
    var approximatingEnd: Bool {
        guard let item = self.currentItem else { return false }
        return abs(item.duration.seconds - currentTimeSeconds) <= 0.05
    }
}
