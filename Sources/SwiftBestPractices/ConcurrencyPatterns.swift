import Foundation

/// Modern Swift concurrency patterns for iOS 18+
public actor DataCache {
    private var cache: [String: Data] = [:]
    
    public init() {}
    
    public func get(_ key: String) -> Data? {
        cache[key]
    }
    
    public func set(_ key: String, value: Data) {
        cache[key] = value
    }
}

/// Task group pattern for parallel operations
public func fetchMultipleResources(urls: [URL]) async throws -> [Data] {
    try await withThrowingTaskGroup(of: (Int, Data).self) { group in
        for (index, url) in urls.enumerated() {
            group.addTask {
                let (data, _) = try await URLSession.shared.data(from: url)
                return (index, data)
            }
        }
        
        var results = [Data?](repeating: nil, count: urls.count)
        for try await (index, data) in group {
            results[index] = data
        }
        return results.compactMap { $0 }
    }
}
