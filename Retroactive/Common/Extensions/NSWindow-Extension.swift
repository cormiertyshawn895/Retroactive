import Cocoa

extension NSWindow {
    static func createFloatingAccessoryWindow(_ viewController: NSViewController) -> NSWindow {
        var frame = CGRect.zero
        frame.size = viewController.view.bounds.size

        let window = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.backgroundColor = NSColor.clear
        window.level = .screenSaver
        window.contentViewController = viewController
        window.ret_setPreventsActivation(true)
        window.isReleasedWhenClosed = false
        window.setFrame(frame, display: true)
        return window
    }
}
