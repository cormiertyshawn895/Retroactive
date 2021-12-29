import Cocoa

class ClippingShadowView: NSView {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.wantsLayer = true
        self.shadow = NSShadow()
        self.layer?.shadowOpacity = 0.15
        self.layer?.shadowColor = NSColor.black.cgColor
        self.layer?.shadowOffset = NSMakeSize(1.5, -2.0)
        self.layer?.shadowRadius = 2.5
    }
}
