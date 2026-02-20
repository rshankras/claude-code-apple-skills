# Drag and Drop

Covers drag and drop using SwiftUI modifiers (`.draggable()`, `.dropDestination()`), the `Transferable` protocol, UIKit drag/drop interactions, and `NSItemProvider` for inter-app data transfer.

## SwiftUI Drag and Drop (iPadOS 16+)

### Basic Draggable

```swift
struct PhotoGrid: View {
    let photos: [Photo]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))]) {
            ForEach(photos) { photo in
                AsyncImage(url: photo.thumbnailURL)
                    .draggable(photo) // Photo must conform to Transferable
            }
        }
    }
}
```

### Drop Destination

```swift
struct DropTargetView: View {
    @State private var droppedPhotos: [Photo] = []

    var body: some View {
        VStack {
            Text("Drop photos here")
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(Color.secondary.opacity(0.1))
                .dropDestination(for: Photo.self) { photos, location in
                    droppedPhotos.append(contentsOf: photos)
                    return true // Accepted
                } isTargeted: { isTargeted in
                    // Highlight when drag is hovering
                }
        }
    }
}
```

### Reordering with Drag and Drop

```swift
struct ReorderableList: View {
    @State private var items: [Item] = Item.samples

    var body: some View {
        List {
            ForEach(items) { item in
                ItemRow(item: item)
                    .draggable(item)
            }
            .dropDestination(for: Item.self) { items, offset in
                // Insert dropped items at the target offset
                self.items.insert(contentsOf: items, at: offset)
            }
        }
    }
}
```

Note: For simple reordering within a `List`, prefer `.onMove(perform:)` which provides built-in reorder handles. Use `.draggable()` and `.dropDestination()` when you need cross-list or cross-app drag and drop.

## Transferable Protocol

The `Transferable` protocol (iPadOS 16+) defines how types are serialized for drag/drop, copy/paste, and ShareSheet.

### Basic Transferable Conformance

```swift
struct Photo: Identifiable, Codable, Transferable {
    let id: UUID
    let title: String
    let imageURL: URL

    static var transferRepresentation: some TransferRepresentation {
        // Primary: encode as Codable JSON
        CodableRepresentation(contentType: .photo)

        // Fallback: export the image file
        FileRepresentation(contentType: .jpeg) { photo in
            SentTransferredFile(photo.imageURL)
        } importing: { received in
            let savedURL = try Self.saveToDocuments(received.file)
            return Photo(id: UUID(), title: "Imported", imageURL: savedURL)
        }
    }
}

// Register custom UTType
import UniformTypeIdentifiers

extension UTType {
    static let photo = UTType(exportedAs: "com.myapp.photo")
}
```

### Multiple Representations

Order matters -- recipients choose the first representation they can handle:

```swift
struct RichTextContent: Transferable {
    let html: String
    let plainText: String

    static var transferRepresentation: some TransferRepresentation {
        // Prefer rich text
        DataRepresentation(contentType: .html) { content in
            Data(content.html.utf8)
        } importing: { data in
            RichTextContent(
                html: String(data: data, encoding: .utf8) ?? "",
                plainText: ""
            )
        }

        // Fallback to plain text
        DataRepresentation(contentType: .plainText) { content in
            Data(content.plainText.utf8)
        } importing: { data in
            RichTextContent(
                html: "",
                plainText: String(data: data, encoding: .utf8) ?? ""
            )
        }
    }
}
```

### ProxyRepresentation

Delegate to an existing Transferable type:

```swift
struct Task: Identifiable, Transferable {
    let id: UUID
    let title: String
    let notes: String

    static var transferRepresentation: some TransferRepresentation {
        // Drag the title as plain text
        ProxyRepresentation(exporting: \.title)
    }
}
```

### Built-in Transferable Types

These standard types already conform to `Transferable`:

- `String` -- plain text
- `URL` -- file or web URL
- `Data` -- raw bytes
- `AttributedString` -- styled text
- `Image` (SwiftUI) -- image data
- `Color` (SwiftUI) -- color data

```swift
// Drag a URL
Link(destination: url) {
    Text("Visit")
}
.draggable(url)

// Drop text
Text("Drop text here")
    .dropDestination(for: String.self) { strings, _ in
        receivedText = strings.first ?? ""
        return true
    }
```

## UIKit Drag and Drop (iPadOS 11+)

### UIDragInteraction

```swift
class DraggableCell: UICollectionViewCell, UIDragInteractionDelegate {
    var item: DataItem?

    override init(frame: CGRect) {
        super.init(frame: frame)
        let dragInteraction = UIDragInteraction(delegate: self)
        dragInteraction.isEnabled = true
        addInteraction(dragInteraction)
    }

    required init?(coder: NSCoder) { fatalError() }

    func dragInteraction(
        _ interaction: UIDragInteraction,
        itemsForBeginning session: UIDragSession
    ) -> [UIDragItem] {
        guard let item else { return [] }

        let provider = NSItemProvider(object: item.title as NSString)
        let dragItem = UIDragItem(itemProvider: provider)
        dragItem.localObject = item // For same-app drops
        return [dragItem]
    }

    // Optional: provide a custom drag preview
    func dragInteraction(
        _ interaction: UIDragInteraction,
        previewForLifting item: UIDragItem,
        session: UIDragSession
    ) -> UITargetedDragPreview? {
        let parameters = UIDragPreviewParameters()
        parameters.visiblePath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: 12
        )
        return UITargetedDragPreview(view: self, parameters: parameters)
    }
}
```

### UIDropInteraction

```swift
class DropZoneView: UIView, UIDropInteractionDelegate {
    override init(frame: CGRect) {
        super.init(frame: frame)
        let dropInteraction = UIDropInteraction(delegate: self)
        addInteraction(dropInteraction)
    }

    required init?(coder: NSCoder) { fatalError() }

    func dropInteraction(
        _ interaction: UIDropInteraction,
        canHandle session: UIDropSession
    ) -> Bool {
        // Accept plain text and images
        return session.canLoadObjects(ofClass: NSString.self)
            || session.canLoadObjects(ofClass: UIImage.self)
    }

    func dropInteraction(
        _ interaction: UIDropInteraction,
        sessionDidUpdate session: UIDropSession
    ) -> UIDropProposal {
        // .copy for inter-app, .move for intra-app reordering
        let operation: UIDropOperation = session.localDragSession != nil ? .move : .copy
        return UIDropProposal(operation: operation)
    }

    func dropInteraction(
        _ interaction: UIDropInteraction,
        performDrop session: UIDropSession
    ) {
        session.loadObjects(ofClass: NSString.self) { items in
            for case let string as String in items {
                self.handleDroppedText(string)
            }
        }

        session.loadObjects(ofClass: UIImage.self) { items in
            for case let image as UIImage in items {
                self.handleDroppedImage(image)
            }
        }
    }
}
```

### UICollectionView Drag and Drop

UICollectionView has built-in drag and drop support:

```swift
class CollectionViewController: UICollectionViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true // Required on iPad
    }
}

extension CollectionViewController: UICollectionViewDragDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        itemsForBeginning session: UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {
        let item = dataSource[indexPath.item]
        let provider = NSItemProvider(object: item.title as NSString)
        let dragItem = UIDragItem(itemProvider: provider)
        dragItem.localObject = item
        return [dragItem]
    }
}

extension CollectionViewController: UICollectionViewDropDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        performDropWith coordinator: UICollectionViewDropCoordinator
    ) {
        let destinationIndexPath = coordinator.destinationIndexPath
            ?? IndexPath(item: 0, section: 0)

        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath {
                // Same collection -- reorder
                collectionView.performBatchUpdates {
                    let movedItem = dataSource.remove(at: sourceIndexPath.item)
                    dataSource.insert(movedItem, at: destinationIndexPath.item)
                    collectionView.moveItem(at: sourceIndexPath, to: destinationIndexPath)
                }
                coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
            } else {
                // From another app -- load asynchronously
                item.dragItem.itemProvider.loadObject(ofClass: NSString.self) { string, _ in
                    guard let text = string as? String else { return }
                    DispatchQueue.main.async {
                        self.insertNewItem(text, at: destinationIndexPath)
                    }
                }
            }
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UICollectionViewDropProposal {
        if session.localDragSession != nil {
            return UICollectionViewDropProposal(
                operation: .move,
                intent: .insertAtDestinationIndexPath
            )
        }
        return UICollectionViewDropProposal(
            operation: .copy,
            intent: .insertAtDestinationIndexPath
        )
    }
}
```

## NSItemProvider

`NSItemProvider` is the underlying transport for inter-app drag and drop. Use it when you need fine-grained control or UIKit compatibility.

### Creating Providers

```swift
// From string
let provider = NSItemProvider(object: "Hello" as NSString)

// From URL
let provider = NSItemProvider(object: url as NSURL)

// From image
let provider = NSItemProvider(object: image)

// From custom type with UTType
let provider = NSItemProvider()
provider.registerDataRepresentation(
    forTypeIdentifier: UTType.json.identifier,
    visibility: .all
) { completion in
    let data = try? JSONEncoder().encode(myModel)
    completion(data, nil)
    return nil // No progress needed
}
```

### Loading from Providers

```swift
func handleDrop(providers: [NSItemProvider]) {
    for provider in providers {
        // Check what types are available
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { image, error in
                guard let image = image as? UIImage else { return }
                DispatchQueue.main.async {
                    self.addImage(image)
                }
            }
        } else if provider.canLoadObject(ofClass: NSString.self) {
            provider.loadObject(ofClass: NSString.self) { string, error in
                guard let text = string as? String else { return }
                DispatchQueue.main.async {
                    self.addText(text)
                }
            }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.json.identifier) {
            provider.loadDataRepresentation(
                forTypeIdentifier: UTType.json.identifier
            ) { data, error in
                guard let data, let model = try? JSONDecoder().decode(MyModel.self, from: data)
                else { return }
                DispatchQueue.main.async {
                    self.addModel(model)
                }
            }
        }
    }
}
```

### Async Loading (iPadOS 16+)

```swift
func handleDrop(providers: [NSItemProvider]) async {
    for provider in providers {
        if provider.canLoadObject(ofClass: UIImage.self) {
            do {
                let image = try await provider.loadObject(ofClass: UIImage.self) as? UIImage
                if let image {
                    addImage(image)
                }
            } catch {
                print("Failed to load image: \(error)")
            }
        }
    }
}
```

## Spring Loading

Spring loading allows users to drag over a navigable element (tab, folder), hold briefly, and the app navigates into it so the user can drop into a deeper location.

### SwiftUI Spring Loading

```swift
struct FolderView: View {
    let folder: Folder
    @State private var isTargeted = false

    var body: some View {
        NavigationLink(value: folder) {
            Label(folder.name, systemImage: "folder")
        }
        .dropDestination(for: FileItem.self) { items, _ in
            moveItems(items, to: folder)
            return true
        } isTargeted: { targeted in
            isTargeted = targeted
            // When targeted during drag, NavigationLink activates after delay (spring loading)
        }
    }
}
```

### UIKit Spring Loading

```swift
class FolderCell: UICollectionViewCell, UISpringLoadedInteractionSupporting {
    var isSpringLoaded: Bool = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        let springInteraction = UISpringLoadedInteraction { interaction, context in
            // Navigate into folder when spring-loaded
            self.navigateIntoFolder()
        }
        addInteraction(springInteraction)
    }

    required init?(coder: NSCoder) { fatalError() }
}
```

## Common Mistakes

### Not Conforming to Transferable

```swift
// ❌ Wrong -- type cannot be dragged because it has no Transferable conformance
struct Task: Identifiable {
    let id: UUID
    let title: String
}

Text(task.title)
    .draggable(task) // Compiler error: Task does not conform to Transferable

// ✅ Right -- add Transferable conformance
struct Task: Identifiable, Codable, Transferable {
    let id: UUID
    let title: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}
```

### Blocking Main Thread on Drop

```swift
// ❌ Wrong -- loading synchronously blocks UI
func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
    let data = loadDataSynchronously(from: session) // Blocks main thread
    processData(data)
}

// ✅ Right -- use async loading
func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
    session.loadObjects(ofClass: UIImage.self) { items in
        DispatchQueue.main.async {
            self.processImages(items.compactMap { $0 as? UIImage })
        }
    }
}
```

### Wrong Drop Operation for Context

```swift
// ❌ Wrong -- always using .copy even for same-app reordering
func dropInteraction(
    _ interaction: UIDropInteraction,
    sessionDidUpdate session: UIDropSession
) -> UIDropProposal {
    return UIDropProposal(operation: .copy)
}

// ✅ Right -- .move for same app, .copy for cross-app
func dropInteraction(
    _ interaction: UIDropInteraction,
    sessionDidUpdate session: UIDropSession
) -> UIDropProposal {
    let operation: UIDropOperation = session.localDragSession != nil ? .move : .copy
    return UIDropProposal(operation: operation)
}
```

### Missing Visual Feedback During Drag

```swift
// ❌ Wrong -- no indication that a view accepts drops
.dropDestination(for: String.self) { items, _ in
    handle(items)
    return true
}

// ✅ Right -- highlight drop target
@State private var isDropTargeted = false

VStack {
    content
}
.background(isDropTargeted ? Color.accentColor.opacity(0.15) : Color.clear)
.overlay(
    RoundedRectangle(cornerRadius: 8)
        .strokeBorder(isDropTargeted ? Color.accentColor : Color.clear, lineWidth: 2)
)
.dropDestination(for: String.self) { items, _ in
    handle(items)
    return true
} isTargeted: { targeted in
    withAnimation(.easeInOut(duration: 0.2)) {
        isDropTargeted = targeted
    }
}
```

### Not Providing Drag Preview

```swift
// The default drag preview is a snapshot of the entire view.
// For large cells or complex views, provide a focused preview.

// ✅ Right -- custom drag preview for cleaner appearance
func dragInteraction(
    _ interaction: UIDragInteraction,
    previewForLifting item: UIDragItem,
    session: UIDragSession
) -> UITargetedDragPreview? {
    // Use just the thumbnail, not the entire cell
    guard let thumbnailView = thumbnailImageView else { return nil }
    let parameters = UIDragPreviewParameters()
    parameters.backgroundColor = .clear
    return UITargetedDragPreview(view: thumbnailView, parameters: parameters)
}
```

## Checklist

- [ ] Draggable types conform to `Transferable` (SwiftUI) or provide `NSItemProvider` (UIKit)
- [ ] Drop targets show visual feedback via `isTargeted` callback
- [ ] Drop operation is `.move` for same-app reordering, `.copy` for cross-app
- [ ] Drop loading is asynchronous -- never blocks main thread
- [ ] Multiple representations provided (rich + fallback) for cross-app compatibility
- [ ] `CodableRepresentation` used for app-specific types, `ProxyRepresentation` for simple types
- [ ] Drag preview is appropriately sized (not the entire view if it is large)
- [ ] Spring loading enabled on navigable elements (folders, tabs) for drag-through navigation
- [ ] Collection/table view drag delegates set and `dragInteractionEnabled = true`
- [ ] Custom UTType registered in Info.plist if using app-specific content types
