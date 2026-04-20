---
name: networking-layer
description: Generates a protocol-based networking layer with async/await, error handling, and swappable implementations. Use when user wants to add API client, networking, or HTTP layer.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Networking Layer Generator

Generate a modern, protocol-based networking layer using Swift's async/await concurrency, with proper error handling and easy testability.

## When This Skill Activates

Use this skill when the user:
- Asks to "add networking" or "create API client"
- Mentions "HTTP layer" or "REST API"
- Wants to "fetch data from API"
- Asks about "URLSession wrapper" or "network requests"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check Swift version (async/await requires Swift 5.5+)
- [ ] Check deployment target (async/await requires iOS 15+ / macOS 12+)
- [ ] Search for existing networking implementations
- [ ] Identify source file locations

### 2. Conflict Detection
Search for existing networking:
```
Glob: **/*API*.swift, **/*Network*.swift, **/*Client*.swift
Grep: "URLSession" or "HTTPURLResponse"
```

If found, ask user:
- Replace existing implementation?
- Extend with new endpoints?

## Configuration Questions

Ask user via AskUserQuestion:

1. **Authentication type?**
   - Bearer token
   - API key (header or query param)
   - None
   - Custom

2. **Base URL configuration?**
   - Single environment
   - Multiple environments (dev/staging/prod)

3. **Additional features?**
   - Retry logic with exponential backoff
   - Request/response logging
   - Caching

## Generation Process

### Step 1: Create Core Files

Generate these files:
1. `APIClient.swift` - Protocol and implementation
2. `APIEndpoint.swift` - Endpoint definition protocol
3. `NetworkError.swift` - Typed errors
4. `APIConfiguration.swift` - Base URL and auth config

### Step 2: Optional Files

Based on configuration:
- `RetryPolicy.swift` - If retry logic selected
- `NetworkLogger.swift` - If logging selected

### Step 3: Determine File Location

Check project structure:
- If `Sources/` exists → `Sources/Networking/`
- If `App/` exists → `App/Networking/`
- Otherwise → `Networking/`

## Swift 6.2 Concurrency Notes

Reference: Apple's Swift Concurrency Updates

### @concurrent for Background Work
Use `@concurrent` to offload heavy processing:
```swift
@concurrent
static func parseResponse<T: Decodable>(_ data: Data) async throws -> T {
    try JSONDecoder().decode(T.self, from: data)
}
```

### MainActor for UI Updates
Keep UI-related code on MainActor:
```swift
@Observable
@MainActor
final class NetworkViewModel {
    var items: [Item] = []

    func fetch() async {
        items = try await apiClient.fetch(ItemsEndpoint())
    }
}
```

## Output Format

After generation, provide:

### Files Created
```
Sources/Networking/
├── APIClient.swift           # Protocol + URLSession implementation
├── APIEndpoint.swift         # Endpoint protocol
├── NetworkError.swift        # Error types
├── APIConfiguration.swift    # Config (base URL, auth)
└── Endpoints/                # Example endpoints
    └── ExampleEndpoint.swift
```

### Integration Steps

**Define an Endpoint:**
```swift
struct UsersEndpoint: APIEndpoint {
    typealias Response = [User]

    var path: String { "/users" }
    var method: HTTPMethod { .get }
}
```

**Make a Request:**
```swift
let client = URLSessionAPIClient(configuration: .production)
let users = try await client.request(UsersEndpoint())
```

**With SwiftUI:**
```swift
struct UsersView: View {
    @State private var users: [User] = []
    @Environment(\.apiClient) private var apiClient

    var body: some View {
        List(users) { user in
            Text(user.name)
        }
        .task {
            users = try await apiClient.request(UsersEndpoint())
        }
    }
}
```

### Testing

Use `MockAPIClient` for tests:
```swift
let mockClient = MockAPIClient()
mockClient.mockResponse(for: UsersEndpoint.self, response: [User.mock])

let viewModel = UsersViewModel(apiClient: mockClient)
await viewModel.fetch()

XCTAssertEqual(viewModel.users.count, 1)
```

## References

- **networking-patterns.md** - Architecture patterns and best practices
- **templates/** - All template files
- Apple Docs: Swift Concurrency Updates (Swift 6.2)
