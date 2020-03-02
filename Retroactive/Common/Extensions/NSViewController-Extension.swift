import Cocoa

extension NSViewController {
    func runAnimationGroup(parameter: (() -> Void)? = nil, duration: TimeInterval = 0.3) {
        NSAnimationContext.runAnimationGroup { (context) in
            context.duration = duration
            context.allowsImplicitAnimation = true
            parameter?()
            self.view.layoutSubtreeIfNeeded()
        }
    }
}
