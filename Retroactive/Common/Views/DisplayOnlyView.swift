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
