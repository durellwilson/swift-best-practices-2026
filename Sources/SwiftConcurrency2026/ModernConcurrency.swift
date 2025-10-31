import Foundation
import DetroitSwiftFoundation

// MARK: - Swift Concurrency Best Practices 2026

/// Best Practice: Actor for thread-safe data management
public actor DetroitDataManager {
    private var cache: [String: CacheEntry] = [:]
    private let maxCacheSize = 100
    
    private struct CacheEntry: Sendable {
        let data: Data
        let timestamp: Date
        let expirationDate: Date
    }
    
    public init() {}
    
    /// Best Practice: Async methods with proper error handling
    public func fetchData(for key: String) async throws -> Data? {
        // Check cache first
        if let entry = cache[key], entry.expirationDate > Date() {
            return entry.data
        }
        
        // Simulate network request
        let data = try await performNetworkRequest(for: key)
        
        // Cache the result
        await cacheData(data, for: key, ttl: 300) // 5 minutes TTL
        
        return data
    }
    
    private func performNetworkRequest(for key: String) async throws -> Data {
        // Best Practice: Use URLSession with async/await
        let url = URL(string: "https://api.detroit.gov/data/\(key)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw DetroitServiceError.networkUnavailable
        }
        
        return data
    }
    
    private func cacheData(_ data: Data, for key: String, ttl: TimeInterval) {
        let entry = CacheEntry(
            data: data,
            timestamp: Date(),
            expirationDate: Date().addingTimeInterval(ttl)
        )
        
        cache[key] = entry
        
        // Best Practice: Maintain cache size limits
        if cache.count > maxCacheSize {
            cleanupOldestEntries()
        }
    }
    
    private func cleanupOldestEntries() {
        let sortedEntries = cache.sorted { $0.value.timestamp < $1.value.timestamp }
        let entriesToRemove = sortedEntries.prefix(cache.count - maxCacheSize + 10)
        
        for (key, _) in entriesToRemove {
            cache.removeValue(forKey: key)
        }
    }
}

/// Best Practice: TaskGroup for concurrent operations
public struct DetroitBatchProcessor: Sendable {
    private let dataManager: DetroitDataManager
    
    public init(dataManager: DetroitDataManager) {
        self.dataManager = dataManager
    }
    
    /// Process multiple items concurrently with proper error handling
    public func processBatch<T: Sendable>(
        items: [String],
        transform: @Sendable @escaping (Data) async throws -> T
    ) async throws -> [Result<T, Error>] {
        try await withThrowingTaskGroup(of: (Int, Result<T, Error>).self) { group in
            // Add tasks for each item
            for (index, item) in items.enumerated() {
                group.addTask {
                    do {
                        let data = try await dataManager.fetchData(for: item)
                        guard let data = data else {
                            throw DetroitServiceError.networkUnavailable
                        }
                        let result = try await transform(data)
                        return (index, .success(result))
                    } catch {
                        return (index, .failure(error))
                    }
                }
            }
            
            // Collect results in order
            var results: [(Int, Result<T, Error>)] = []
            for try await result in group {
                results.append(result)
            }
            
            // Sort by original index and return values
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
}

/// Best Practice: AsyncSequence for streaming data
public struct DetroitEventStream: AsyncSequence, Sendable {
    public typealias Element = DetroitEvent
    
    private let eventSource: DetroitEventSource
    
    public init(eventSource: DetroitEventSource) {
        self.eventSource = eventSource
    }
    
    public func makeAsyncIterator() -> DetroitEventIterator {
        DetroitEventIterator(eventSource: eventSource)
    }
}

public struct DetroitEventIterator: AsyncIteratorProtocol {
    public typealias Element = DetroitEvent
    
    private let eventSource: DetroitEventSource
    private var isActive = true
    
    init(eventSource: DetroitEventSource) {
        self.eventSource = eventSource
    }
    
    public mutating func next() async throws -> DetroitEvent? {
        guard isActive else { return nil }
        
        // Best Practice: Cancellation support
        try Task.checkCancellation()
        
        return try await eventSource.nextEvent()
    }
}

/// Best Practice: Actor for event source management
public actor DetroitEventSource {
    private var subscribers: [UUID: AsyncStream<DetroitEvent>.Continuation] = [:]
    private var eventQueue: [DetroitEvent] = []
    
    public init() {}
    
    public func nextEvent() async throws -> DetroitEvent? {
        // Simulate event generation
        try await Task.sleep(for: .milliseconds(100))
        
        if eventQueue.isEmpty {
            generateSampleEvent()
        }
        
        return eventQueue.isEmpty ? nil : eventQueue.removeFirst()
    }
    
    private func generateSampleEvent() {
        let event = DetroitEvent(
            type: .systemEvent,
            location: DetroitCoordinate(
                latitude: 42.3314 + Double.random(in: -0.1...0.1),
                longitude: -83.0458 + Double.random(in: -0.1...0.1)
            )
        )
        eventQueue.append(event)
    }
    
    /// Best Practice: AsyncStream for real-time updates
    public func eventStream() -> AsyncStream<DetroitEvent> {
        AsyncStream { continuation in
            let id = UUID()
            subscribers[id] = continuation
            
            continuation.onTermination = { _ in
                Task {
                    await self.removeSubscriber(id)
                }
            }
        }
    }
    
    private func removeSubscriber(_ id: UUID) {
        subscribers.removeValue(forKey: id)
    }
    
    public func broadcastEvent(_ event: DetroitEvent) {
        for continuation in subscribers.values {
            continuation.yield(event)
        }
    }
}

/// Best Practice: Structured concurrency with proper cancellation
public struct DetroitTaskManager: Sendable {
    
    /// Execute tasks with timeout and cancellation support
    public static func executeWithTimeout<T: Sendable>(
        timeout: TimeInterval,
        operation: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation
            group.addTask {
                try await operation()
            }
            
            // Add timeout task
            group.addTask {
                try await Task.sleep(for: .seconds(timeout))
                throw DetroitServiceError.serviceTimeout(duration: timeout)
            }
            
            // Return first completed task and cancel others
            defer { group.cancelAll() }
            return try await group.next()!
        }
    }
    
    /// Best Practice: Retry logic with exponential backoff
    public static func executeWithRetry<T: Sendable>(
        maxAttempts: Int = 3,
        baseDelay: TimeInterval = 1.0,
        operation: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                guard attempt < maxAttempts else { break }
                
                // Exponential backoff
                let delay = baseDelay * pow(2.0, Double(attempt - 1))
                try await Task.sleep(for: .seconds(delay))
            }
        }
        
        throw lastError ?? DetroitServiceError.networkUnavailable
    }
}

/// Best Practice: Custom async property wrapper
@propertyWrapper
public struct AsyncLazy<Value: Sendable>: Sendable {
    private let loader: @Sendable () async throws -> Value
    private let storage = AsyncLazyStorage<Value>()
    
    public init(_ loader: @Sendable @escaping () async throws -> Value) {
        self.loader = loader
    }
    
    public var wrappedValue: Value {
        get async throws {
            try await storage.getValue(loader: loader)
        }
    }
}

private actor AsyncLazyStorage<Value: Sendable> {
    private var value: Value?
    private var loadTask: Task<Value, Error>?
    
    func getValue(loader: @Sendable () async throws -> Value) async throws -> Value {
        if let value = value {
            return value
        }
        
        if let loadTask = loadTask {
            return try await loadTask.value
        }
        
        let task = Task {
            try await loader()
        }
        loadTask = task
        
        do {
            let result = try await task.value
            value = result
            loadTask = nil
            return result
        } catch {
            loadTask = nil
            throw error
        }
    }
}
