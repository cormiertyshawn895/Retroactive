import Cocoa

class AccentGradientButton: HoverButton {
    let blendingRatio: CGFloat = 0.25
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.wantsLayer = true
        self.layer?.cornerRadius = 6.5
    }
    
    override func draw(_ dirtyRect: NSRect) {
        var startingColor = NSColor.controlAccentColorPolyfill
        startingColor = startingColor.blended(withFraction: blendingRatio, of: NSColor.controlBackgroundColor)!
        var endingColor = startingColor.blended(withFraction: blendingRatio, of: NSColor.black)!
        if (self.isHighlighted) {
            startingColor = startingColor.blended(withFraction: blendingRatio, of: NSColor.black)!
            endingColor = startingColor.blended(withFraction: blendingRatio, of: NSColor.black)!
        }

        let gradient = NSGradient(starting: startingColor, ending: endingColor)
        gradient?.draw(in: self.bounds, angle: 90)
    }
}
