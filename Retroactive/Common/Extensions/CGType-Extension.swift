import Cocoa

extension CGSize {
    func similarToSize(_ size: CGSize, maxDeltaX: CGFloat = 8, maxDeltaY: CGFloat = 8) -> Bool {
        return abs(self.width - size.width) <= maxDeltaX && abs(self.height - size.height) <= maxDeltaY
    }
}
