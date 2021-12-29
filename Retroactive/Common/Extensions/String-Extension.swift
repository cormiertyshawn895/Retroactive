import Cocoa

extension String {
    var fileSystemString: String {
        let cStr = (self as NSString).fileSystemRepresentation
        let swiftString = String(cString: cStr)
        return swiftString
    }
    
    func stringByAppendingPathComponent(path: String) -> String {
        let nsSt = self as NSString
        return nsSt.appendingPathComponent(path)
    }

    func attributedStringWithShadow(font: NSFont, blurRadius: CGFloat, offset: CGFloat, opacity: CGFloat, color: NSColor = .white) -> NSAttributedString {
        let shadow = NSShadow()
        shadow.shadowBlurRadius = blurRadius
        shadow.shadowOffset = NSSize(width: offset, height: offset)
        shadow.shadowColor = NSColor.black.withAlphaComponent(opacity)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        return NSMutableAttributedString(string: self, attributes:[.font: font, .foregroundColor: color, .shadow: shadow, .paragraphStyle: paragraph])
    }
    
    static var randomUUID: String {
        return UUID().uuidString
    }
}
