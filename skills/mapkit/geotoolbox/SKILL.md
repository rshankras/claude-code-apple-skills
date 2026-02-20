---
name: geotoolbox
description: GeoToolbox PlaceDescriptor patterns with MapKit integration for location representation, geocoding, and multi-service place identifiers. Use when working with place descriptors, geocoding, or cross-service location data.
allowed-tools: [Read, Glob, Grep]
---

# GeoToolbox and PlaceDescriptor Patterns

Portable location representation using `PlaceDescriptor` from the GeoToolbox framework. Covers place construction from coordinates, addresses, and MapKit items; forward and reverse geocoding with the new async APIs; and multi-service place identifiers for cross-platform interop.

## When This Skill Activates

Use this skill when the user:
- Asks about **GeoToolbox** or **PlaceDescriptor**
- Wants to represent a place with coordinates, address, or common name
- Needs to convert between **MKMapItem** and **PlaceDescriptor**
- Asks about **forward geocoding** (address to coordinates) or **reverse geocoding** (coordinates to address)
- Wants to store or transmit **multi-service place identifiers** (Apple Maps, Google Maps, etc.)
- Mentions **PlaceRepresentation**, **SupportingPlaceRepresentation**, or **MKGeocodingRequest**
- Asks about portable or interoperable location data structures

## Decision Tree

```
What do you need?
|
+-- Represent a place with coordinates and/or address
|   +-- From a known coordinate
|   |   +-- PlaceRepresentation.coordinate(CLLocationCoordinate2D)
|   +-- From a known address string
|   |   +-- PlaceRepresentation.address(String)
|   +-- Both coordinate and address
|   |   +-- Pass multiple representations to PlaceDescriptor
|   +-- From an existing MKMapItem
|       +-- PlaceDescriptor(item: MKMapItem)
|
+-- Geocode an address to coordinates
|   +-- MKGeocodingRequest(addressString:)
|   +-- try await request.mapItems
|
+-- Reverse geocode coordinates to an address
|   +-- MKReverseGeocodingRequest(location:)
|   +-- try await request.mapItems
|
+-- Attach service identifiers (Apple Maps, Google, etc.)
|   +-- SupportingPlaceRepresentation.serviceIdentifiers([String: String])
|
+-- Read place properties
    +-- descriptor.coordinate, descriptor.address, descriptor.commonName
    +-- descriptor.serviceIdentifier(for: "com.apple.maps")
```

## API Availability

| API | Minimum OS | Import |
|-----|-----------|--------|
| `PlaceDescriptor` | iOS 26 / macOS 26 | `GeoToolbox` |
| `PlaceRepresentation` | iOS 26 / macOS 26 | `GeoToolbox` |
| `SupportingPlaceRepresentation` | iOS 26 / macOS 26 | `GeoToolbox` |
| `MKGeocodingRequest` | iOS 26 / macOS 26 | `MapKit` |
| `MKReverseGeocodingRequest` | iOS 26 / macOS 26 | `MapKit` |
| `PlaceDescriptor(item:)` | iOS 26 / macOS 26 | `GeoToolbox` + `MapKit` |
| `MKMapItem` | iOS 6 / macOS 10.9 | `MapKit` |
| `CLLocationCoordinate2D` | iOS 2 / macOS 10.6 | `CoreLocation` |

## Quick Start

### Create a PlaceDescriptor from Coordinates

```swift
import GeoToolbox
import CoreLocation

let coordinate = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)

let descriptor = PlaceDescriptor(
    representations: [.coordinate(coordinate)],
    commonName: "Apple Park"
)

// Read back
if let coord = descriptor.coordinate {
    print("Lat: \(coord.latitude), Lon: \(coord.longitude)")
}
print(descriptor.commonName ?? "No name")
```

### Create a PlaceDescriptor from an Address

```swift
import GeoToolbox

let descriptor = PlaceDescriptor(
    representations: [.address("One Apple Park Way, Cupertino, CA 95014")],
    commonName: "Apple Park"
)

if let address = descriptor.address {
    print("Address: \(address)")
}
```

### Multiple Representations and Service Identifiers

```swift
import GeoToolbox
import CoreLocation

let coordinate = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)

let descriptor = PlaceDescriptor(
    representations: [
        .coordinate(coordinate),
        .address("One Apple Park Way, Cupertino, CA 95014")
    ],
    commonName: "Apple Park",
    supportingRepresentations: [
        .serviceIdentifiers([
            "com.apple.maps": "apple-maps-id-12345",
            "com.google.maps": "ChIJ-bfVTh8_j4ARDMPaL2Njo3I"
        ])
    ]
)

// Access a specific service identifier
if let appleId = descriptor.serviceIdentifier(for: "com.apple.maps") {
    print("Apple Maps ID: \(appleId)")
}
```

### Convert from MKMapItem

```swift
import GeoToolbox
import MapKit

func descriptorFromMapItem(_ mapItem: MKMapItem) -> PlaceDescriptor {
    PlaceDescriptor(item: mapItem)
}
```

## Forward Geocoding (Address to Coordinates)

```swift
import MapKit

func geocodeAddress(_ addressString: String) async throws -> [MKMapItem] {
    let request = MKGeocodingRequest(addressString: addressString)
    let mapItems = try await request.mapItems
    return mapItems
}

// Usage
let items = try await geocodeAddress("One Apple Park Way, Cupertino, CA")
if let first = items.first {
    let coord = first.placemark.coordinate
    print("Found: \(coord.latitude), \(coord.longitude)")
}
```

## Reverse Geocoding (Coordinates to Address)

```swift
import MapKit
import CoreLocation

func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async throws -> [MKMapItem] {
    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    let request = MKReverseGeocodingRequest(location: location)
    let mapItems = try await request.mapItems
    return mapItems
}

// Usage
let coordinate = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
let items = try await reverseGeocode(coordinate)
if let first = items.first {
    print("Address: \(first.placemark.title ?? "Unknown")")
}
```

## Full Integration Example

Geocode an address, convert the result to a PlaceDescriptor with service identifiers, and read back all properties:

```swift
import GeoToolbox
import MapKit
import CoreLocation

func buildPlaceDescriptor(from addressString: String) async throws -> PlaceDescriptor? {
    // Forward geocode
    let request = MKGeocodingRequest(addressString: addressString)
    let mapItems = try await request.mapItems
    guard let mapItem = mapItems.first else { return nil }

    // Convert MKMapItem to PlaceDescriptor
    var descriptor = PlaceDescriptor(item: mapItem)

    // Or build manually with extra data
    let coordinate = mapItem.placemark.coordinate
    descriptor = PlaceDescriptor(
        representations: [
            .coordinate(coordinate),
            .address(addressString)
        ],
        commonName: mapItem.name,
        supportingRepresentations: [
            .serviceIdentifiers([
                "com.apple.maps": "resolved-id-\(coordinate.latitude)"
            ])
        ]
    )

    return descriptor
}

func displayDescriptor(_ descriptor: PlaceDescriptor) {
    if let name = descriptor.commonName {
        print("Name: \(name)")
    }
    if let coord = descriptor.coordinate {
        print("Coordinate: \(coord.latitude), \(coord.longitude)")
    }
    if let address = descriptor.address {
        print("Address: \(address)")
    }
    if let appleId = descriptor.serviceIdentifier(for: "com.apple.maps") {
        print("Apple Maps ID: \(appleId)")
    }
}
```

## Top Mistakes

| # | Mistake | Problem | Fix |
|---|---------|---------|-----|
| 1 | Importing only `MapKit` when using `PlaceDescriptor` | `PlaceDescriptor` lives in `GeoToolbox`, not `MapKit` | Add `import GeoToolbox` alongside `import MapKit` |
| 2 | Using `CLGeocoder` instead of `MKGeocodingRequest` | `CLGeocoder` returns `CLPlacemark` which lacks MapKit integration | Use `MKGeocodingRequest` / `MKReverseGeocodingRequest` for `MKMapItem` results |
| 3 | Assuming `PlaceDescriptor` always has a coordinate | A descriptor can be address-only with no coordinate | Check `descriptor.coordinate` for `nil` before use |
| 4 | Assuming `PlaceDescriptor` always has an address | A descriptor can be coordinate-only with no address | Check `descriptor.address` for `nil` before use |
| 5 | Hardcoding service identifier keys | Service identifier keys are strings; typos cause silent failures | Define constants for service keys like `"com.apple.maps"` |
| 6 | Passing `CLLocationCoordinate2D` directly to `MKReverseGeocodingRequest` | The initializer takes a `CLLocation`, not a raw coordinate | Wrap in `CLLocation(latitude:longitude:)` first |
| 7 | Ignoring empty geocoding results | Geocoding can return zero results for ambiguous or invalid input | Guard against empty `mapItems` arrays |
| 8 | Not handling geocoding errors | Network or service failures throw errors | Use `do/catch` or `try await` with proper error handling |

## Patterns

### Service Identifier Constants

Define constants to avoid typos in service identifier keys:

```swift
// Good -- constants prevent typos
enum PlaceService {
    static let appleMaps = "com.apple.maps"
    static let googleMaps = "com.google.maps"
    static let foursquare = "com.foursquare"
}

if let id = descriptor.serviceIdentifier(for: PlaceService.appleMaps) {
    // use id
}
```

```swift
// Bad -- raw string literals are error-prone
if let id = descriptor.serviceIdentifier(for: "com.apple.map") { // typo: "map" not "maps"
    // silently nil
}
```

### Nil-Safe Property Access

```swift
// Good -- check each optional property
func formatPlace(_ descriptor: PlaceDescriptor) -> String {
    var parts: [String] = []
    if let name = descriptor.commonName {
        parts.append(name)
    }
    if let address = descriptor.address {
        parts.append(address)
    }
    if let coord = descriptor.coordinate {
        parts.append("\(coord.latitude), \(coord.longitude)")
    }
    return parts.joined(separator: " -- ")
}
```

```swift
// Bad -- force-unwrapping optional properties
let name = descriptor.commonName! // crashes if nil
let coord = descriptor.coordinate! // crashes if no coordinate representation
```

### Geocoding with Fallback

```swift
// Good -- handle empty results and errors
func resolvePlace(_ address: String) async -> PlaceDescriptor? {
    do {
        let request = MKGeocodingRequest(addressString: address)
        let items = try await request.mapItems
        guard let item = items.first else {
            print("No results for address: \(address)")
            return nil
        }
        return PlaceDescriptor(item: item)
    } catch {
        print("Geocoding failed: \(error.localizedDescription)")
        return nil
    }
}
```

```swift
// Bad -- no error handling, no empty check
func resolvePlace(_ address: String) async -> PlaceDescriptor {
    let request = MKGeocodingRequest(addressString: address)
    let items = try! await request.mapItems // crashes on failure
    return PlaceDescriptor(item: items.first!) // crashes if empty
}
```

## Review Checklist

- [ ] `import GeoToolbox` is present when using `PlaceDescriptor`, `PlaceRepresentation`, or `SupportingPlaceRepresentation`
- [ ] `import MapKit` is present when using `MKGeocodingRequest`, `MKReverseGeocodingRequest`, or `MKMapItem`
- [ ] `import CoreLocation` is present when using `CLLocationCoordinate2D` or `CLLocation`
- [ ] `PlaceDescriptor` properties (`coordinate`, `address`, `commonName`) are checked for `nil` before use
- [ ] Service identifier keys use defined constants, not raw string literals
- [ ] `MKReverseGeocodingRequest` receives a `CLLocation`, not a raw `CLLocationCoordinate2D`
- [ ] Geocoding results are checked for empty arrays before accessing elements
- [ ] Geocoding calls use proper `async/await` error handling with `do/catch`
- [ ] Multiple representations are provided when both coordinate and address are known
- [ ] Supporting representations include service identifiers when cross-service interop is needed

## Cross-References

- For **MapKit map views** and annotations, see MapKit documentation
- For **CoreLocation** permissions and location updates, see CoreLocation documentation
- For **SwiftUI integration** with maps, see `Map` view in SwiftUI

## References

- [GeoToolbox Framework](https://developer.apple.com/documentation/geotoolbox)
- [PlaceDescriptor](https://developer.apple.com/documentation/geotoolbox/placedescriptor)
- [MKGeocodingRequest](https://developer.apple.com/documentation/mapkit/mkgeocodingrequest)
- [MKReverseGeocodingRequest](https://developer.apple.com/documentation/mapkit/mkreversegeocodingrequest)
- [MKMapItem](https://developer.apple.com/documentation/mapkit/mkmapitem)
