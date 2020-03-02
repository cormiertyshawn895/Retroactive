import Foundation

extension Process {
    static func runNonAdminTask(toolPath: String, arguments: [String]) {
        let task = Process()
        task.launchPath = toolPath
        task.arguments = arguments
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String? {
            print(output)
        }
    }
}
