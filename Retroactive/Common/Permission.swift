import Foundation

/* There's no API to figure out if another app (bash) has FDA.
 
 A naive way is to open /Library/Application Support/com.apple.TCC/TCC.db with SQLite, and execute:
 select * from access where client="/bin/bash" and service="kTCCServiceSystemPolicyAllFiles" and allowed=1
 This doesn't work because reading TCC.db requires FDA by itself.
 
 Instead, here's a contrived workaround. Build a throwaway app bundle and make its main executable a shebang
 script. Let the shebang script copy TCC.db to /tmp. If it copied successfully, bash has FDA.
 
*/

class Permission {
    static let shared = Permission()

    var sharedUUID: String = String.randomUUID

    func updateThrowawayApp() {
        DispatchQueue.global(qos: .background).async {
            do {
                self.sharedUUID = String.randomUUID
                let appPath = "\(throwawayTmpPath)/\(self.sharedUUID).app"
                let contents = "\(appPath)/Contents"
                let scriptName = "\(contents)/MacOS/\(self.sharedUUID)"
                
                try FileManager.default.createDirectory(atPath: "\(contents)/MacOS", withIntermediateDirectories: true, attributes: nil)
                let string = plistTemplate.replacingOccurrences(of: nameReplaceToken, with: self.sharedUUID)
                try string.write(toFile: "\(contents)/Info.plist", atomically: true, encoding: .utf8)
                
                let bashString = bashScriptTemplate.replacingOccurrences(of: nameReplaceToken, with: self.sharedUUID)
                try bashString.write(toFile: scriptName, atomically: true, encoding: .utf8)
                print("Made throwaway bundle, \(contents)")
                
                Process.runNonAdminTask(toolPath: "/bin/chmod", arguments: ["+x", scriptName])
                Process.runNonAdminTask(toolPath: "/usr/bin/open", arguments: [appPath])
            } catch {
                print(error)
            }
        }
    }

    func bashHasFullDiskAccess() -> Bool {
        return FileManager.default.fileExists(atPath: "\(throwawayTmpPath)/\(sharedUUID).db")
    }
}

let nameReplaceToken = "{NAMEREPLACE}"

let plistTemplate = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>BuildMachineOSBuild</key>
    <string>19E242d</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>\(nameReplaceToken)</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.temporary.\(nameReplaceToken)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>\(nameReplaceToken)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>MacOSX</string>
    </array>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>DTCompiler</key>
    <string>com.apple.compilers.llvm.clang.1_0</string>
    <key>DTPlatformBuild</key>
    <string>11C504</string>
    <key>DTPlatformVersion</key>
    <string>GM</string>
    <key>DTSDKBuild</key>
    <string>19B90</string>
    <key>DTSDKName</key>
    <string>macosx10.15</string>
    <key>DTXcode</key>
    <string>1130</string>
    <key>DTXcodeBuild</key>
    <string>11C504</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.14</string>
    <key>NSMainNibFile</key>
    <string>MainMenu</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
"""

let throwawayTmpPath = "/tmp/retroactive"

let bashScriptTemplate = """
#!/bin/bash
cp "/Library/Application Support/com.apple.TCC/TCC.db" "\(throwawayTmpPath)/\(nameReplaceToken).db"
"""
