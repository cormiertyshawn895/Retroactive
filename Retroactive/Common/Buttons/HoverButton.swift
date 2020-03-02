import Cocoa

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
