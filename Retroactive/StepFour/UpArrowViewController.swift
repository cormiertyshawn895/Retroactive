import Cocoa

class DragMeViewController: NSViewController {
    @IBOutlet weak var draggingView: DragFileView!
    @IBOutlet weak var boxContainer: NSBox!

    static func instantiate() -> DragMeViewController {
        return NSStoryboard.standard!.instantiateController(withIdentifier: "DragMeViewController") as! DragMeViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        draggingView.addDiffusedShadow()
        draggingView.subviewForImagePresentation = boxContainer
    }
    
}

class UpArrowViewController: NSViewController {
    @IBOutlet weak var arrowImageView: NSImageView!
    
    static func instantiate() -> UpArrowViewController {
        return NSStoryboard.standard!.instantiateController(withIdentifier: "UpArrowViewController") as! UpArrowViewController
    }
}
