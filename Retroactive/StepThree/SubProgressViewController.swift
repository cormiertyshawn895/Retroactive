//
//  SubProgressViewController.swift
//  Retroactive
//

import Cocoa

class SubProgressViewController: NSViewController {
    @IBOutlet weak var circularProgress: CircularProgress!
    @IBOutlet weak var descriptionTextField: NSTextField!
    @IBOutlet weak var progressTextField: NSTextField!
    @IBOutlet weak var numberBox: NSBox!
    @IBOutlet weak var sequenceLabel: NSTextField!
    
    static func instantiate() -> SubProgressViewController
    {
        return NSStoryboard.standard!.instantiateController(withIdentifier: "SubProgressViewController") as! SubProgressViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        circularProgress.isHidden = true
        numberBox.isHidden = false
        circularProgress.lineWidth = 4.0
        circularProgress.cancelProgress()
        circularProgress.isIndeterminate = true
        numberBox.fillColor = NSColor.controlAccentColorPolyfill
        self.progressTextField.stringValue = "Waiting...".localized()
    }
    
    var stageDescription: String?
    
    var inProgress: Bool {
        set {
            if (newValue == true) {
                // circularProgress.resetProgress()
                self.progressTextField.stringValue = "Working...".localized()
                circularProgress.isHidden = false
                numberBox.isHidden = true
            } else {
                circularProgress.progress = 1.0
                circularProgress.color = NSColor.systemGreen
                self.progressTextField.stringValue = "Completed".localized()
            }
        }
        get {
            return circularProgress.progress != 1.0
        }
    }
}
