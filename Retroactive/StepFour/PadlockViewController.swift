import Cocoa

protocol PadlockViewControllerDelegate : NSObject {
    func alreadyUnlockedClicked(_ sender: Any)
}

class PadlockViewController: NSViewController {
    @IBOutlet weak var arrowImageView: NSImageView!
    @IBOutlet weak var clickToUnlockLabel: NSTextField!
    @IBOutlet weak var alreadyUnlockedButton: HoverButton!
    @IBOutlet weak var boxView: NSBox!
    
    weak var delegate: PadlockViewControllerDelegate?

    static func instantiate() -> PadlockViewController {
        return NSStoryboard.standard!.instantiateController(withIdentifier: "PadlockViewController") as! PadlockViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        arrowImageView.addDiffusedShadow()
        boxView.addDiffusedShadow()
    }

    @IBAction func alreadyUnlockedClicked(_ sender: Any) {
        delegate?.alreadyUnlockedClicked(self)
    }
    
}
