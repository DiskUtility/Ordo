import Foundation

enum AppStorePaths {
    static func appSupportDirectory() -> URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func removeKnownStores() {
        let fm = FileManager.default
        let directory = appSupportDirectory()
        let explicitStores = ["Planner.store", "default.store"].map { directory.appendingPathComponent($0) }

        for storeURL in explicitStores {
            try? fm.removeItem(at: storeURL)
            try? fm.removeItem(at: URL(fileURLWithPath: storeURL.path + "-shm"))
            try? fm.removeItem(at: URL(fileURLWithPath: storeURL.path + "-wal"))
        }

        if let files = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            for file in files where file.lastPathComponent.contains(".store") {
                try? fm.removeItem(at: file)
            }
        }
    }
}
