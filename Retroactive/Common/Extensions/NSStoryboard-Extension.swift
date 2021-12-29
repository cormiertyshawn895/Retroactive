import Cocoa

extension NSStoryboard {
    class var standard: NSStoryboard? {
        if #available(OSX 10.13, *) {
            return NSStoryboard.main
        } else {
            return NSStoryboard(name: "Main", bundle: nil)
        }
    }
}
