import Cocoa

extension NSView {
    // Only works for views without Auto Layout.
    func moveIntoView(_ newView: NSView) {
        let newRect = self.convert(self.bounds, to: newView)
        self.removeFromSuperview()
        self.frame = newRect
        newView.addSubview(self)
    }
    
    func addDiffusedShadow() {
        self.wantsLayer = true
        self.shadow = NSShadow()
        self.layer?.shadowOpacity = 0.26
        self.layer?.shadowColor = NSColor.black.cgColor
        self.layer?.shadowOffset = NSMakeSize(2.0, -2.0)
        self.layer?.shadowRadius = 13.0
    }
    
    var imagePresentation: NSImage? {
        let mySize = self.bounds.size
        let imgSize = NSSize(width: mySize.width, height: mySize.height )
        
        guard let bir = self.bitmapImageRepForCachingDisplay(in: self.bounds) else {
            return nil
        }
        bir.size = imgSize
        self.cacheDisplay(in: self.bounds, to: bir)
        
        let image = NSImage(size: imgSize)
        image.addRepresentation(bir)
        return image
    }
    
    func safelyAddSubview(_ subview: NSView?) {
        if let sub = subview {
            self.addSubview(sub)
        }
    }
}
