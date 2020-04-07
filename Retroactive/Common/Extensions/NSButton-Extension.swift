import Cocoa

let disclosureArrow = " ›"
let disclosureLoop = " ↻"
let disclosureStrings = [disclosureArrow, disclosureLoop]

extension NSButton {
    func addShadow(blurRadius: CGFloat = 1.0, offset: CGFloat = 1.5, opacity: CGFloat = 0.25) {
        var tintColor: NSColor = .black
        if #available(OSX 10.14, *) {
            if let tc = self.contentTintColor {
                tintColor = tc
            }
        }
        self.attributedTitle = self.title.attributedStringWithShadow(font: self.font!, blurRadius: blurRadius, offset: offset, opacity: opacity, color: tintColor)
    }
    
    func updateTitle(titleSize: CGFloat = 19, chevronSize: CGFloat = 25, chevronOffset: CGFloat = 1.5) {
        let newTitle = AppManager.replaceTokenFor(self.title)
        for disclosureString in disclosureStrings {
            if (newTitle.contains(disclosureString)) {
                let attrString = NSMutableAttributedString(string: newTitle.replacingOccurrences(of: disclosureString, with: ""),
                                                           attributes:[.font: NSFont.systemFont(ofSize: titleSize), .foregroundColor: NSColor.controlAccentColorPolyfill])
                attrString.append(NSMutableAttributedString(string: disclosureString,
                                                            attributes:[.font: NSFont.systemFont(ofSize: chevronSize), .foregroundColor: NSColor.controlAccentColorPolyfill, .baselineOffset: -chevronOffset]))
                self.attributedTitle = attrString
                return
            }
        }

        self.title = newTitle
        let attrString = NSMutableAttributedString(attributedString: self.attributedTitle)
        attrString.addAttribute(.foregroundColor, value: NSColor.controlAccentColorPolyfill, range: NSRange(location: 0, length: attrString.length))
        self.attributedTitle = attrString
    }
}
