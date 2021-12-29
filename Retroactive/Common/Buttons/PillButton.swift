import Cocoa

class PillButton: NSButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.controlAccentColorPolyfill.blended(withFraction: 0.25, of: NSColor.white)?.cgColor
        self.layer?.cornerRadius = 15.0
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted == true {
                self.layer?.opacity = 0.85
            } else {
                self.layer?.opacity = 1.0
            }
        }
    }
    
    override func viewDidChangeEffectiveAppearance() {
        self.layer?.backgroundColor = NSColor.controlAccentColorPolyfill.blended(withFraction: 0.25, of: NSColor.white)?.cgColor
    }
}
