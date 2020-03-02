import Cocoa

extension NSTextField {
    static func makeLabel(text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor = .controlAccentColorPolyfill) -> NSTextField {
        let textField = NSTextField(labelWithString: text)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = NSFont.systemFont(ofSize: size, weight: weight)
        textField.textColor = color
        textField.lineBreakMode = .byWordWrapping
        
        return textField
    }

    func updateToken() {
        self.stringValue = AppManager.replaceTokenFor(self.stringValue)
    }
    
    func addShadow(blurRadius: CGFloat = 1.0, offset: CGFloat = 1.5, opacity: CGFloat = 0.25) {
        self.attributedStringValue = self.stringValue.attributedStringWithShadow(font: self.font!, blurRadius: blurRadius, offset: offset, opacity: opacity)
    }
}
