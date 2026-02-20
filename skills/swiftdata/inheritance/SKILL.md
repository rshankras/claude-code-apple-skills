---
name: swiftdata-inheritance
description: SwiftData class inheritance patterns for hierarchical models with type-based querying, polymorphic relationships, and when to choose inheritance vs enums. Use when designing SwiftData model hierarchies.
allowed-tools: [Read, Glob, Grep]
---

# SwiftData Class Inheritance

Guide for implementing class inheritance in SwiftData models. Covers when to use inheritance versus enums or protocols, how to annotate subclasses, query across hierarchies, and avoid common pitfalls with schema migrations and relationship modeling.

## When This Skill Activates

- User is designing a SwiftData model hierarchy with shared base properties
- User asks about `@Model` on subclasses or how inheritance works in SwiftData
- User needs to query across a type hierarchy (all trips vs only business trips)
- User is deciding between inheritance, enums, or protocols for model variants
- User has issues with polymorphic relationships or type casting in SwiftData
- User is migrating a Core Data inheritance hierarchy to SwiftData

## Decision Tree

```
Do your model variants share a common identity and most properties?
|
+-- YES: Clear IS-A relationship (BusinessTrip IS-A Trip)
|   |
|   +-- Subclasses add significant unique properties or behavior?
|   |   +-- YES --> Use class inheritance (this skill)
|   |   +-- NO, just 1-2 distinguishing fields --> Use enum property on base model
|   |
|   +-- Need to query "all trips" AND "only business trips"?
|       +-- YES --> Inheritance gives you both for free
|       +-- Only one type at a time --> Enum filter is simpler
|
+-- NO: Models share only a few properties
|   +-- Use protocol conformance (no SwiftData inheritance needed)
|
+-- UNCERTAIN: Could go either way
    +-- Prefer enum on base model (simpler schema, easier migrations)
    +-- Promote to inheritance later if variants diverge significantly
```

### When to Use Inheritance

- There is a meaningful IS-A relationship (a `BusinessTrip` fundamentally IS a `Trip`)
- Subclasses add substantial unique stored properties
- You need deep queries (fetch all `Trip` instances regardless of subtype) and shallow queries (fetch only `BusinessTrip`)
- Polymorphic relationships are required (a `[Trip]` array holding mixed subtypes)

### When to Avoid Inheritance

- Subclasses share only a few properties -- use a protocol instead
- A boolean flag or enum could represent the distinction without separate classes
- You want to minimize schema migration complexity
- The hierarchy would go deeper than two levels

## API Patterns

### Base Model Declaration

Apply `@Model` to the base class. All persistent properties live here.

```swift
@Model
class Trip {
    var name: String
    var startDate: Date
    var endDate: Date

    @Attribute(.preserveValueOnDeletion)
    var identifier: UUID

    @Relationship(deleteRule: .cascade, inverse: \Accommodation.trip)
    var accommodations: [Accommodation] = []

    init(name: String, startDate: Date, endDate: Date) {
        self.identifier = UUID()
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
    }
}
```

### Subclass Declaration

Apply `@Model` to each subclass. Call `super.init()` and add subclass-specific stored properties.

```swift
@Model
class BusinessTrip: Trip {
    var company: String
    var expenseReport: String?
    var meetingAgenda: String?

    init(name: String, startDate: Date, endDate: Date, company: String) {
        self.company = company
        super.init(name: name, startDate: startDate, endDate: endDate)
    }
}

@Model
class PersonalTrip: Trip {
    enum Reason: String, Codable {
        case vacation
        case family
        case adventure
    }

    var reason: Reason
    var companions: [String] = []

    init(name: String, startDate: Date, endDate: Date, reason: Reason) {
        self.reason = reason
        super.init(name: name, startDate: startDate, endDate: endDate)
    }
}
```

### Relationships Across the Hierarchy

Relationships defined on the base class apply to all subclasses. The inverse can point to a base class property and will resolve to the correct subclass at runtime.

```swift
@Model
class Accommodation {
    var name: String

    // Points to Trip -- could be BusinessTrip or PersonalTrip at runtime
    @Relationship(inverse: \Trip.accommodations)
    var trip: Trip?

    init(name: String) { self.name = name }
}
```

### ModelContainer Configuration

Register the base class. SwiftData discovers subclasses automatically.

```swift
// Register Trip -- BusinessTrip and PersonalTrip are included automatically
let container = try ModelContainer(for: Trip.self, Accommodation.self, Itinerary.self)
```

## Querying Hierarchies

### Deep Query (All Subclasses)

Querying the base class returns instances of every subclass.

```swift
// Returns Trip, BusinessTrip, and PersonalTrip instances
@Query(sort: \Trip.startDate)
var allTrips: [Trip]
```

### Type Filtering with Predicate

Narrow results to a specific subclass using `is` or `as?` in a `#Predicate`.

```swift
// Only BusinessTrip instances
let businessOnly = #Predicate<Trip> { trip in
    trip is BusinessTrip
}

@Query(filter: #Predicate<Trip> { $0 is BusinessTrip }, sort: \Trip.startDate)
var businessTrips: [Trip]
```

### Subclass Property Filtering

Access subclass-specific properties with conditional casting inside the predicate.

```swift
let vacationTrips = #Predicate<Trip> { trip in
    if let personal = trip as? PersonalTrip {
        personal.reason == .vacation
    } else {
        false
    }
}
```

### Enum-Based Filter Switching in UI

A common pattern for filter controls that switch between all trips and a specific type.

```swift
enum TripFilter: String, CaseIterable, Identifiable {
    case all, business, personal
    var id: String { rawValue }
}

struct TripListView: View {
    @State private var filter: TripFilter = .all
    @Query(sort: \Trip.startDate) var allTrips: [Trip]

    var filteredTrips: [Trip] {
        switch filter {
        case .all: return allTrips
        case .business: return allTrips.filter { $0 is BusinessTrip }
        case .personal: return allTrips.filter { $0 is PersonalTrip }
        }
    }

    var body: some View {
        List {
            Picker("Filter", selection: $filter) {
                ForEach(TripFilter.allCases) { f in
                    Text(f.rawValue.capitalized).tag(f)
                }
            }
            .pickerStyle(.segmented)

            ForEach(filteredTrips) { trip in
                TripRowView(trip: trip)
            }
        }
    }
}
```

### Type Casting at Runtime

Use standard Swift casting to access subclass-specific properties in views.

```swift
if let business = trip as? BusinessTrip {
    LabeledContent("Company", value: business.company)
}
if let personal = trip as? PersonalTrip {
    LabeledContent("Reason", value: personal.reason.rawValue)
}
```

## Top Mistakes

### 1. Missing @Model on Subclass

The `@Model` macro must appear on both the base class and every subclass. Omitting it on a subclass causes its unique properties to be silently ignored.

```swift
// WRONG -- subclass properties not persisted
class BusinessTrip: Trip {
    var company: String  // not saved
    ...
}

// RIGHT
@Model
class BusinessTrip: Trip {
    var company: String  // persisted correctly
    ...
}
```

### 2. Deep Hierarchies

Keep to one level of subclassing. Going beyond two levels (base + one tier) increases schema complexity and migration risk.

```swift
// WRONG -- three levels deep
@Model class InternationalBusinessTrip: BusinessTrip { ... }  // avoid

// RIGHT -- flat: base + one level
@Model class Trip { ... }
@Model class BusinessTrip: Trip { ... }
@Model class PersonalTrip: Trip { ... }
```

### 3. Using Inheritance When an Enum Would Suffice

If the only difference is a type tag and one or two optional fields, an enum on the base model is simpler.

```swift
// WRONG -- inheritance just for a category label
@Model class DomesticTrip: Trip { }
@Model class InternationalTrip: Trip { var passportRequired: Bool = true }

// RIGHT -- enum property on the base model
@Model class Trip {
    enum Category: String, Codable { case domestic, international }
    var name: String
    var category: Category
    var passportRequired: Bool?
}
```

### 4. Forgetting super.init()

Subclass initializers must call `super.init()` with all required base properties. Missing this causes incomplete or corrupt records.

```swift
// WRONG -- base properties uninitialized
init(company: String) {
    self.company = company
    // Missing super.init(name:startDate:endDate:)
}

// RIGHT -- always call super.init()
init(name: String, startDate: Date, endDate: Date, company: String) {
    self.company = company
    super.init(name: name, startDate: startDate, endDate: endDate)
}
```

### 5. Registering Subclasses Separately in ModelContainer

SwiftData discovers subclasses automatically. Register only the base class.

```swift
// UNNECESSARY
let container = try ModelContainer(for: Trip.self, BusinessTrip.self, PersonalTrip.self)

// RIGHT
let container = try ModelContainer(for: Trip.self)
```

## Review Checklist

When reviewing code that uses SwiftData class inheritance, verify each item:

- [ ] `@Model` is applied to the base class AND every subclass
- [ ] Each subclass calls `super.init()` with all required base properties
- [ ] Hierarchy is shallow (base + one level of subclasses, no deeper)
- [ ] The IS-A relationship is meaningful -- not just a type tag that could be an enum
- [ ] `@Attribute(.preserveValueOnDeletion)` is used on fields needed after deletion (sync IDs, audit trails)
- [ ] Relationships use `inverse:` parameters correctly, pointing to the base class property
- [ ] `@Relationship(deleteRule:)` is specified on owning side (`.cascade`, `.nullify`, or `.deny`)
- [ ] Deep queries (base class fetch) and shallow queries (type-filtered) both work as expected
- [ ] Type casting (`as? Subclass`) is used safely with `if let` in views and logic
- [ ] ModelContainer registers the base class (subclasses are auto-discovered)
- [ ] Schema migration plan exists if the hierarchy will evolve (adding/removing subclasses)
- [ ] Enum-based filter pattern is used for UI that switches between type views

## Cross-Reference

- For **SwiftData repository and architecture patterns**, see `macos/swiftdata-architecture/`
- For **SwiftData concurrency with @ModelActor**, see `swift/concurrency-patterns/`
- For **persistence setup generator**, see `generators/persistence-setup/`

## References

- [Preserving your app's model data across launches](https://developer.apple.com/documentation/swiftdata/preserving-your-apps-model-data-across-launches)
- [SwiftData documentation](https://developer.apple.com/documentation/swiftdata)
- Apple doc: `/Users/ravishankar/Downloads/docs/SwiftData-Class-Inheritance.md`
