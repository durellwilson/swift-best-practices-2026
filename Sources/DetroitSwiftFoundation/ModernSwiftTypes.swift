import Foundation
import Algorithms

// MARK: - Swift 6.0+ Best Practices for Detroit Ecosystem

/// Modern Swift value types with complete Sendable conformance
/// Best Practice: Use @frozen for performance-critical types
@frozen
public struct DetroitCoordinate: Sendable, Hashable, Codable {
    public let latitude: Double
    public let longitude: Double
    
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    /// Best Practice: Computed properties for derived values
    public var isInDetroit: Bool {
        // Detroit bounding box
        (42.25...42.45).contains(latitude) && (-83.25...(-82.90)).contains(longitude)
    }
}

/// Modern error handling with typed throws (Swift 6.0+)
public enum DetroitServiceError: Error, Sendable {
    case networkUnavailable
    case invalidLocation(DetroitCoordinate)
    case serviceTimeout(duration: TimeInterval)
    case rateLimited(retryAfter: TimeInterval)
}

/// Best Practice: Actor for thread-safe state management
@globalActor
public actor DetroitDataActor {
    public static let shared = DetroitDataActor()
    
    private var cache: [String: Any] = [:]
    private var lastUpdate: Date = .distantPast
    
    public func getValue<T>(_ key: String, as type: T.Type) -> T? {
        cache[key] as? T
    }
    
    public func setValue<T: Sendable>(_ value: T, forKey key: String) {
        cache[key] = value
        lastUpdate = Date()
    }
    
    public func clearExpiredCache(maxAge: TimeInterval = 300) {
        guard Date().timeIntervalSince(lastUpdate) > maxAge else { return }
        cache.removeAll()
    }
}

/// Best Practice: Protocol-oriented programming with associated types
public protocol DetroitDataSource: Sendable {
    associatedtype DataType: Sendable & Codable
    associatedtype ErrorType: Error & Sendable
    
    func fetchData() async throws(ErrorType) -> DataType
    func validateData(_ data: DataType) -> Bool
}

/// Best Practice: Generic types with constraints
public struct DetroitAPIClient<T: DetroitDataSource>: Sendable {
    private let dataSource: T
    private let session: URLSession
    
    public init(dataSource: T, session: URLSession = .shared) {
        self.dataSource = dataSource
        self.session = session
    }
    
    /// Best Practice: Async/await with typed throws
    public func fetchValidatedData() async throws(T.ErrorType) -> T.DataType {
        let data = try await dataSource.fetchData()
        
        guard dataSource.validateData(data) else {
            throw DetroitServiceError.invalidLocation(.init(latitude: 0, longitude: 0)) as! T.ErrorType
        }
        
        return data
    }
}

/// Best Practice: Result builders for DSL creation
@resultBuilder
public struct DetroitConfigurationBuilder {
    public static func buildBlock(_ components: DetroitConfigurationComponent...) -> [DetroitConfigurationComponent] {
        components
    }
    
    public static func buildOptional(_ component: [DetroitConfigurationComponent]?) -> [DetroitConfigurationComponent] {
        component ?? []
    }
    
    public static func buildEither(first component: [DetroitConfigurationComponent]) -> [DetroitConfigurationComponent] {
        component
    }
    
    public static func buildEither(second component: [DetroitConfigurationComponent]) -> [DetroitConfigurationComponent] {
        component
    }
}

public protocol DetroitConfigurationComponent: Sendable {
    var name: String { get }
    var isEnabled: Bool { get }
}

public struct DetroitConfiguration: Sendable {
    public let components: [DetroitConfigurationComponent]
    
    public init(@DetroitConfigurationBuilder _ builder: () -> [DetroitConfigurationComponent]) {
        self.components = builder()
    }
}

/// Best Practice: Modern collection operations with Swift Algorithms
public extension Collection where Element: Numeric {
    /// Calculate moving average using Swift Algorithms
    func movingAverage(windowSize: Int) -> [Element] {
        self.windows(ofCount: windowSize)
            .map { window in
                window.reduce(.zero, +) / Element(exactly: windowSize) ?? .zero
            }
    }
}

/// Best Practice: Macro usage for code generation (Swift 5.9+)
/// Note: This would require actual macro implementation
public protocol DetroitObservable {
    // @Observable macro would be applied here in real implementation
}

/// Best Practice: Sendable closures and strict concurrency
public struct DetroitEventHandler: Sendable {
    private let handler: @Sendable (DetroitEvent) async -> Void
    
    public init(_ handler: @escaping @Sendable (DetroitEvent) async -> Void) {
        self.handler = handler
    }
    
    public func handle(_ event: DetroitEvent) async {
        await handler(event)
    }
}

public struct DetroitEvent: Sendable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let type: EventType
    public let location: DetroitCoordinate?
    
    public enum EventType: String, Sendable, Codable, CaseIterable {
        case userAction = "user_action"
        case systemEvent = "system_event"
        case networkRequest = "network_request"
        case errorOccurred = "error_occurred"
    }
    
    public init(type: EventType, location: DetroitCoordinate? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.location = location
    }
}
