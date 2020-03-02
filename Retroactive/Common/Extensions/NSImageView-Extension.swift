import Cocoa

extension NSImageView {
    func updateIcon() {
        self.image = AppManager.shared.cartoonIcon
    }
}
