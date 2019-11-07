//
//  RetroactiveWindowController.swift
//  Retroactive
//

import Cocoa

class RetroactiveWindowController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.isMovableByWindowBackground = true
        self.window?.titlebarAppearsTransparent = true
        self.window?.titleVisibility = .hidden
    }
    
}
