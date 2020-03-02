import Foundation
import SQLite3

class Permission {
    static let shared = Permission()

    var db: OpaquePointer?
    var copiedDBPath: String?
    
    // If the system and Retroactive accesses TCC.db at the same time, bad things will happen.
    // Instead, make a copy and query the copy.
    func bashHasFullDiskAccess() -> Bool {
        db = self.openCopiedTCCDatabase()
        let result = query("select * from access where client='/bin/bash' and service='kTCCServiceSystemPolicyAllFiles' and allowed=1")
        sqlite3_close(db)
        db = nil
        print(result)
        do {
            if let path = copiedDBPath {
                try FileManager.default.removeItem(atPath: path)
            }
        } catch {
            print("Can't remove copied database")
        }
        return result
    }
    
    func openCopiedTCCDatabase() -> OpaquePointer? {
        let randomizedCopiedPath = "/tmp/\(UUID().uuidString).db"
        do {
            try FileManager.default.copyItem(atPath: "/Library/Application Support/com.apple.TCC/TCC.db", toPath: randomizedCopiedPath)
            copiedDBPath = randomizedCopiedPath
            if sqlite3_open(randomizedCopiedPath, &db) == SQLITE_OK {
                print("Successfully opened connection to TCC database")
                return db
            } else {
                print("Unable to open database.")
                return nil
            }
        } catch {
            print("Can't copy database")
            return nil
        }
    }
    
    func query(_ queryStatementString: String) -> Bool {
        var queryStatement: OpaquePointer?
        // 1
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) ==
            SQLITE_OK {
            // 2
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                // 3
                let id = sqlite3_column_int(queryStatement, 0)
                // 4
                guard let queryResultCol1 = sqlite3_column_text(queryStatement, 1) else {
                    print("Query result is nil")
                    return false
                }
                let name = String(cString: queryResultCol1)
                // 5
                print("\nQuery Result:")
                print("\(id) | \(name)")
                return true
            } else {
                print("\nQuery returned no results.")
            }
        } else {
            // 6
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("\nQuery is not prepared \(errorMessage)")
        }
        // 7
        sqlite3_finalize(queryStatement)
        return false
    }
    
}
