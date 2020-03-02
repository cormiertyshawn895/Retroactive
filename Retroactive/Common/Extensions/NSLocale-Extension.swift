import Cocoa

extension NSLocale {
    static var languageLTR: Bool {
        if let language = NSLocale.preferredLanguages.first {
            return NSLocale.characterDirection(forLanguage: language) == .leftToRight
        }
        return false
    }
}
