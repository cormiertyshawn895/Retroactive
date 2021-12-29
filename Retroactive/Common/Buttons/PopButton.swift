import Cocoa

class PopButton : HoverButton {
    override func awakeFromNib() {
        self.wantsLayer = true
        self.layer?.cornerRadius = 15.0
        self.focusRingType = .none
        if let font = font {
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            
            let attributes = [
                    .foregroundColor: NSColor.white,
                    .font: font,
                    .paragraphStyle: style
                    ] as [NSAttributedString.Key : Any]
            
            let attributedTitle = NSAttributedString(string: title, attributes: attributes)
            self.attributedTitle = attributedTitle
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        let bgColor = NSColor.controlAccentColorPolyfill
        bgColor.setFill()
        dirtyRect.fill()
        super.draw(dirtyRect)
    }
}
