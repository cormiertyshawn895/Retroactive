//
//  DisplayOnlyTextField.swift
//  Retroactive
//

import Cocoa

class DisplayOnlyTextField: NSTextField {
    public override func hitTest(_ point: NSPoint) -> NSView? {
        return subviews.first { subview in
            !subview.isHidden && nil != subview.hitTest(point)
        }
    }
}

class DisplayOnlyImageView: NSImageView {
    public override func hitTest(_ point: NSPoint) -> NSView? {
        return subviews.first { subview in
            !subview.isHidden && nil != subview.hitTest(point)
        }
    }
}

public class DisplayOnlyNSView: NSView {
    public override func hitTest(_ point: NSPoint) -> NSView? {
        return subviews.first { subview in
            !subview.isHidden && nil != subview.hitTest(point)
        }
    }
}

class AcceptsMouseView: NSView {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}

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

class AccentGradientButton: HoverButton {
    let blendingRatio: CGFloat = 0.25
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.wantsLayer = true
        self.layer?.cornerRadius = 6.5
    }
    
    override func draw(_ dirtyRect: NSRect) {
        var startingColor = NSColor.controlAccentColor
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

class PillButton: NSButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.controlAccentColor.blended(withFraction: 0.25, of: NSColor.white)?.cgColor
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
        self.layer?.backgroundColor = NSColor.controlAccentColor.blended(withFraction: 0.25, of: NSColor.white)?.cgColor
    }
}

extension String {
    var fileSystemString: String {
        let cStr = (self as NSString).fileSystemRepresentation
        let swiftString = String(cString: cStr)
        return swiftString
    }
}

extension NSTextField {
    func updateToken() {
        self.stringValue = AppManager.replaceTokenFor(self.stringValue)
    }
    
    func addShadow() {
        let shadow = NSShadow()
        shadow.shadowBlurRadius = 1.0
        shadow.shadowOffset = NSSize(width: 1.5, height: 1.5)
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        self.attributedStringValue = NSMutableAttributedString(string: self.stringValue, attributes:[.font: self.font!, .foregroundColor: NSColor.white, .shadow: shadow, .paragraphStyle: paragraph])
    }
}

let disclosureString = " ›"

extension NSButton {
    func updateTitle() {
        let newTitle = AppManager.replaceTokenFor(self.title)
        if (newTitle.contains(disclosureString)) {
            let attrString = NSMutableAttributedString(string: newTitle.replacingOccurrences(of: disclosureString, with: ""),
                                                       attributes:[.font: NSFont.systemFont(ofSize: 19), .foregroundColor: NSColor.controlAccentColor])
            attrString.append(NSMutableAttributedString(string: disclosureString,
                                                        attributes:[.font: NSFont.systemFont(ofSize: 25), .foregroundColor: NSColor.controlAccentColor, .baselineOffset: -1.5]))
            self.attributedTitle = attrString
        } else {
            self.title = newTitle
        }
    }
}

extension NSImageView {
    func updateIcon() {
        self.image = AppManager.shared.cartoonIcon
    }
}

class HoverButton: NSButton {
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        let area = NSTrackingArea.init(rect: self.bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
        self.addTrackingArea(area)
    }
    
    override func mouseEntered(with event: NSEvent) {
        if (self.isEnabled) {
            self.animator().alphaValue = 0.7
            NSCursor.pointingHand.set()
        }
        super.mouseEntered(with: event)
    }
    
    override func mouseExited(with event: NSEvent) {
        if (self.isEnabled) {
            self.animator().alphaValue = 1.0
            NSCursor.arrow.set()
        }
        super.mouseExited(with: event)
    }
    
    override func mouseDown(with event: NSEvent) {
        if (self.isEnabled) {
            NSAnimationContext.runAnimationGroup({ (context: NSAnimationContext) in
                context.duration = 0.1
                self.animator().alphaValue = 1.0
            }, completionHandler: {
                NSAnimationContext.runAnimationGroup({ (context) in
                    context.duration = 0.1
                    self.animator().alphaValue = 0.7
                }, completionHandler: nil)
            })
        }
        super.mouseDown(with: event)
    }
}

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
        let bgColor = NSColor.controlAccentColor
        bgColor.setFill()
        dirtyRect.fill()
        super.draw(dirtyRect)
    }
}
