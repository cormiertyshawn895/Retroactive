import Cocoa

class UpArrowViewController: NSViewController {
    @IBOutlet weak var draggingView: DragFileView!
    @IBOutlet weak var boxContainer: NSBox!
    @IBOutlet weak var arrowImageView: NSImageView!
    
    static func instantiate() -> UpArrowViewController {
        return NSStoryboard.standard!.instantiateController(withIdentifier: "UpArrowViewController") as! UpArrowViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        draggingView.addDiffusedShadow()
        draggingView.subviewForImagePresentation = boxContainer
    }
    
}
