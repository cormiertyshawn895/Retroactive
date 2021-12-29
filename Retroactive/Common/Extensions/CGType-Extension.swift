import Cocoa

extension CGSize {
    func similarToSize(_ size: CGSize, maxDeltaX: CGFloat = 8, maxDeltaY: CGFloat = 8) -> Bool {
        return abs(self.width - size.width) <= maxDeltaX && abs(self.height - size.height) <= maxDeltaY
    }
    
    var similarToSecurityPrefPaneSize: Bool {
        // Security preferences window is around 668x573 on Catalina, 668x587 on Big Sur
        return self.similarToSize(CGSize(width: 668, height: osAtLeastBigSur ? 587 : 573), maxDeltaX: 180, maxDeltaY: 5)
    }
    
    var similarToPasswordDialogSize: Bool {
        return self.similarToSize(CGSize(width: 444, height: 212), maxDeltaX: 40, maxDeltaY: 212)
    }
    
    var similarToDimmingBackgroundSize: Bool {
        if (!osAtLeastBigSur) {
            return false
        }
        // Dimming background is around 668x535 on Big Sur
        return self.similarToSize(CGSize(width: 668, height: 535), maxDeltaX: 180, maxDeltaY: 5)
    }
}
