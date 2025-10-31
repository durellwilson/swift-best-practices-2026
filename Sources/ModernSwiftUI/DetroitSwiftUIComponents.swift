import SwiftUI
import DetroitSwiftFoundation

// MARK: - SwiftUI Best Practices 2026 for Detroit Ecosystem

/// Best Practice: @Observable for state management (iOS 17+)
@Observable
public final class DetroitAppState: Sendable {
    public var currentLocation: DetroitCoordinate?
    public var isConnected: Bool = false
    public var lastUpdate: Date = .now
    
    public init() {}
    
    @MainActor
    public func updateLocation(_ coordinate: DetroitCoordinate) {
        currentLocation = coordinate
        lastUpdate = .now
    }
}

/// Best Practice: Modern view composition with @ViewBuilder
public struct DetroitContentView: View {
    @State private var appState = DetroitAppState()
    @Environment(\.colorScheme) private var colorScheme
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            DetroitMainContent()
                .environment(appState)
                .preferredColorScheme(colorScheme)
        }
        .task {
            await loadInitialData()
        }
    }
    
    private func loadInitialData() async {
        // Best Practice: Structured concurrency in SwiftUI
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await appState.updateLocation(.init(latitude: 42.3314, longitude: -83.0458))
            }
        }
    }
}

/// Best Practice: Reusable view components with generics
public struct DetroitCard<Content: View>: View {
    private let content: Content
    private let title: String
    private let subtitle: String?
    
    public init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            content
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

/// Best Practice: Custom view modifiers for reusability
public struct DetroitStyleModifier: ViewModifier {
    private let isHighlighted: Bool
    
    public init(isHighlighted: Bool = false) {
        self.isHighlighted = isHighlighted
    }
    
    public func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHighlighted ? .blue.opacity(0.1) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHighlighted ? .blue : .gray.opacity(0.3), lineWidth: 1)
            )
    }
}

public extension View {
    func detroitStyle(isHighlighted: Bool = false) -> some View {
        modifier(DetroitStyleModifier(isHighlighted: isHighlighted))
    }
}

/// Best Practice: Async image loading with modern SwiftUI
public struct DetroitAsyncImageView: View {
    private let url: URL?
    private let placeholder: String
    
    public init(url: URL?, placeholder: String = "photo") {
        self.url = url
        self.placeholder = placeholder
    }
    
    public var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Image(systemName: placeholder)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.gray.opacity(0.1))
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Best Practice: Custom container views with @ViewBuilder
public struct DetroitSection<Header: View, Content: View>: View {
    private let header: Header
    private let content: Content
    
    public init(
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header()
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
                .font(.title2)
                .fontWeight(.semibold)
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Best Practice: Environment values for dependency injection
private struct DetroitThemeKey: EnvironmentKey {
    static let defaultValue = DetroitTheme.standard
}

public extension EnvironmentValues {
    var detroitTheme: DetroitTheme {
        get { self[DetroitThemeKey.self] }
        set { self[DetroitThemeKey.self] = newValue }
    }
}

public struct DetroitTheme: Sendable {
    public let primaryColor: Color
    public let secondaryColor: Color
    public let accentColor: Color
    
    public static let standard = DetroitTheme(
        primaryColor: .blue,
        secondaryColor: .gray,
        accentColor: .orange
    )
    
    public static let detroit = DetroitTheme(
        primaryColor: Color(red: 0.0, green: 0.3, blue: 0.6), // Detroit Blue
        secondaryColor: Color(red: 0.8, green: 0.8, blue: 0.8),
        accentColor: Color(red: 1.0, green: 0.4, blue: 0.0) // Detroit Orange
    )
}

/// Best Practice: SwiftUI animations with modern API
public struct DetroitAnimatedButton: View {
    private let title: String
    private let action: () -> Void
    @State private var isPressed = false
    
    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
}

/// Best Practice: Main content view with proper state management
struct DetroitMainContent: View {
    @Environment(DetroitAppState.self) private var appState
    @Environment(\.detroitTheme) private var theme
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                DetroitSection {
                    Text("Detroit Location")
                } content: {
                    if let location = appState.currentLocation {
                        DetroitCard(
                            title: "Current Location",
                            subtitle: location.isInDetroit ? "In Detroit" : "Outside Detroit"
                        ) {
                            VStack(alignment: .leading) {
                                Text("Lat: \(location.latitude, specifier: "%.4f")")
                                Text("Lng: \(location.longitude, specifier: "%.4f")")
                            }
                            .font(.monospaced(.body)())
                        }
                    } else {
                        Text("Location not available")
                            .foregroundStyle(.secondary)
                    }
                }
                
                DetroitSection {
                    Text("Actions")
                } content: {
                    DetroitAnimatedButton(title: "Update Location") {
                        Task {
                            await appState.updateLocation(.init(
                                latitude: 42.3314 + Double.random(in: -0.01...0.01),
                                longitude: -83.0458 + Double.random(in: -0.01...0.01)
                            ))
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Detroit Swift UI")
        .navigationBarTitleDisplayMode(.large)
    }
}
