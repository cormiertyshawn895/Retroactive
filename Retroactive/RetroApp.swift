//
//  RetroApp.swift
//  Retroactive
//

import Cocoa

class RetroApp: NSObject {
    var stage1Text: String = "Download support files"
    var stage2Text: String = "Extract support files"
    var stage3Text: String = "Copy support files"
    var stage4Text: String = "Associate support files"
}

let itunesVersionMapping: [iTunesVersion: String] = [.darkMode: "12.9.5", .appStore: "12.6.5", .coverFlow: "10.7"]
let itunesFeatureMapping: [iTunesVersion: String] = [.darkMode: "DJ apps and Dark Mode", .appStore: "App Store", .coverFlow: "CoverFlow"]
let itunesScreenshotMapping: [iTunesVersion: String] = [.darkMode: "itunes12_9", .appStore: "itunes12_6", .coverFlow: "itunes_10_7"]

class iTunesApp: RetroApp {
    var version: iTunesVersion!
    var versionNumberString: String!
    var featureDescriptionString: String!
    var previewScreenshot: NSImage!
    var downloadURL: URL!
    
    init(_ version: iTunesVersion) {
        super.init()
        self.version = version
        self.versionNumberString = itunesVersionMapping[version]
        self.featureDescriptionString = itunesFeatureMapping[version]
        self.previewScreenshot = NSImage(named: itunesScreenshotMapping[version]!)
        self.downloadURL = URL(string: "")
        
        stage1Text = "Download iTunes"
        stage2Text = "Extract iTunes"
        stage3Text = "Install iTunes"
        stage4Text = "Configure iTunes"
    }
}
