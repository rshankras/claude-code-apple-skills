# Core ML Architecture Patterns and Best Practices

## Model Manager Pattern

Central service for model lifecycle management. Prevents redundant loading, manages memory, and provides a clean API for the rest of the app.

### Singleton or Injected Service

```swift
// Option 1: Actor-based singleton (simplest)
actor MLModelManager {
    static let shared = MLModelManager()
    private var loadedModels: [String: MLModel] = [:]

    func model(named name: String) async throws -> MLModel {
        if let cached = loadedModels[name] { return cached }

        guard let url = Bundle.main.url(forResource: name, withExtension: "mlmodelc") else {
            throw MLModelError.modelNotFound(name)
        }

        let config = MLModelConfiguration()
        config.computeUnits = .all
        let model = try await MLModel.load(contentsOf: url, configuration: config)
        loadedModels[name] = model
        return model
    }

    func unloadModel(named name: String) {
        loadedModels.removeValue(forKey: name)
    }

    func unloadAll() {
        loadedModels.removeAll()
    }
}

// Option 2: Protocol-based for dependency injection
protocol ModelProviding: Sendable {
    func model(named name: String) async throws -> MLModel
    func unloadModel(named name: String) async
}
```

### Lazy Loading
Do not load models at app launch. Load on first prediction request:

```swift
// Wrong - loads at init, delays app launch
class AppDelegate: NSObject, UIApplicationDelegate {
    let model = try! MyClassifier(configuration: .init())  // Blocks launch
}

// Right - loads on first use
struct ClassifierView: View {
    @State private var result: String?

    var body: some View {
        Button("Classify") {
            Task {
                let model = try await MLModelManager.shared.model(named: "MyClassifier")
                // First call loads; subsequent calls return cached
            }
        }
    }
}
```

### Memory Management
Unload models when no longer needed, especially on memory warnings:

```swift
// Respond to memory pressure
actor MLModelManager {
    func handleMemoryWarning() {
        // Keep most-used model, unload others
        let keep = mostRecentlyUsedModelName
        for name in loadedModels.keys where name != keep {
            loadedModels.removeValue(forKey: name)
        }
    }
}

// In SwiftUI
.onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
    Task { await MLModelManager.shared.handleMemoryWarning() }
}
```

### Error Handling with Graceful Fallback

```swift
enum MLModelError: Error, LocalizedError {
    case modelNotFound(String)
    case predictionFailed(Error)
    case lowConfidence(best: String, confidence: Float)
    case invalidInput(String)
    case modelCorrupted

    var errorDescription: String? {
        switch self {
        case .modelNotFound(let name):
            return "ML model '\(name)' not found in bundle"
        case .predictionFailed(let error):
            return "Prediction failed: \(error.localizedDescription)"
        case .lowConfidence(let best, let confidence):
            return "Low confidence result: \(best) (\(String(format: "%.1f", confidence * 100))%)"
        case .invalidInput(let reason):
            return "Invalid input: \(reason)"
        case .modelCorrupted:
            return "ML model file is corrupted"
        }
    }
}
```

## Vision Request Pipeline Pattern

Structured approach for executing Vision framework requests with proper error handling and image orientation support.

### Basic Pipeline

```swift
struct VisionService {
    func performRequests(
        on image: CGImage,
        orientation: CGImagePropertyOrientation = .up,
        requests: [VNRequest]
    ) async throws {
        let handler = VNImageRequestHandler(
            cgImage: image,
            orientation: orientation,
            options: [:]
        )
        try handler.perform(requests)
    }
}
```

### Handling Image Orientation (Critical for Camera Input)
Camera images come with EXIF orientation metadata. Ignoring this produces incorrect results:

```swift
// Convert UIImage orientation to Vision orientation
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up:            self = .up
        case .upMirrored:    self = .upMirrored
        case .down:          self = .down
        case .downMirrored:  self = .downMirrored
        case .left:          self = .left
        case .leftMirrored:  self = .leftMirrored
        case .right:         self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default:    self = .up
        }
    }
}

// Always pass orientation
func classify(_ image: UIImage) throws -> [VNClassificationObservation] {
    guard let cgImage = image.cgImage else { throw MLModelError.invalidInput("No CGImage") }

    let request = VNClassifyImageRequest()
    let handler = VNImageRequestHandler(
        cgImage: cgImage,
        orientation: CGImagePropertyOrientation(image.imageOrientation),
        options: [:]
    )
    try handler.perform([request])
    return request.results ?? []
}
```

### Pipeline Multiple Requests on Same Image

```swift
func analyzeImage(_ image: CGImage) async throws -> ImageAnalysis {
    let classifyRequest = VNClassifyImageRequest()
    let textRequest = VNRecognizeTextRequest()
    textRequest.recognitionLevel = .accurate
    let faceRequest = VNDetectFaceRectanglesRequest()

    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    try handler.perform([classifyRequest, textRequest, faceRequest])

    return ImageAnalysis(
        classifications: classifyRequest.results ?? [],
        recognizedText: textRequest.results?.compactMap { $0.topCandidates(1).first?.string } ?? [],
        faces: faceRequest.results ?? []
    )
}

struct ImageAnalysis {
    let classifications: [VNClassificationObservation]
    let recognizedText: [String]
    let faces: [VNFaceObservation]
}
```

## Camera + ML Real-Time Pattern

Process camera frames with ML in real-time while maintaining smooth UI.

### AVCaptureSession to Vision Pipeline

```swift
final class CameraMLPipeline: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let captureSession = AVCaptureSession()
    private let processingQueue = DispatchQueue(label: "ml.processing", qos: .userInitiated)
    private var lastProcessingTime: Date = .distantPast
    private let minimumInterval: TimeInterval = 0.5  // Process every 500ms

    var onResult: ((String, Float) -> Void)?

    func startCapture() throws {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw MLModelError.invalidInput("No camera available")
        }

        let input = try AVCaptureDeviceInput(device: device)
        captureSession.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: processingQueue)
        output.alwaysDiscardsLateVideoFrames = true
        captureSession.addOutput(output)

        captureSession.startRunning()
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Throttle: skip frames to avoid overwhelming ML pipeline
        let now = Date()
        guard now.timeIntervalSince(lastProcessingTime) >= minimumInterval else { return }
        lastProcessingTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNClassifyImageRequest { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let top = results.first else { return }
            DispatchQueue.main.async {
                self?.onResult?(top.identifier, top.confidence)
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}
```

### Key Rules for Camera + ML
1. **Throttle predictions** — not every frame. Every 5th frame or 500ms minimum
2. **Use `.alwaysDiscardsLateVideoFrames = true`** — prevents buffer queue buildup
3. **Process on background queue** — never block the camera pipeline
4. **Use `MLComputeUnits.all`** — let the system choose the fastest hardware
5. **Update UI on main thread** — always dispatch results back to `@MainActor`

## Model Versioning Pattern

Support model updates over time without breaking the app.

### Versioned Model Files

```swift
struct ModelVersion {
    let name: String
    let version: Int
    let url: URL

    var filename: String { "\(name)_v\(version)" }

    static func latestBundled(name: String) -> ModelVersion? {
        // Find highest version in bundle
        var version = 1
        var latest: ModelVersion?
        while let url = Bundle.main.url(forResource: "\(name)_v\(version)", withExtension: "mlmodelc") {
            latest = ModelVersion(name: name, version: version, url: url)
            version += 1
        }
        return latest
    }
}
```

### Remote Model Download and Update

```swift
actor ModelUpdater {
    private let fileManager = FileManager.default

    func downloadModel(from remoteURL: URL, name: String, version: Int) async throws -> URL {
        let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)

        // Compile the downloaded .mlmodel
        let compiledURL = try MLModel.compileModel(at: tempURL)

        // Move to permanent location
        let modelsDir = try modelsDirectory()
        let destination = modelsDir.appendingPathComponent("\(name)_v\(version).mlmodelc")

        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: compiledURL, to: destination)

        return destination
    }

    func checkForUpdate(name: String, currentVersion: Int) async throws -> Bool {
        // Check your server for newer model version
        // Return true if update available
        let metadata = try await fetchModelMetadata(name: name)
        return metadata.latestVersion > currentVersion
    }

    private func modelsDirectory() throws -> URL {
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let modelsDir = appSupport.appendingPathComponent("MLModels")
        if !fileManager.fileExists(atPath: modelsDir.path) {
            try fileManager.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        }
        return modelsDir
    }
}
```

### Graceful Degradation

```swift
func loadBestAvailableModel(named name: String) async throws -> MLModel {
    // Try downloaded (newer) model first
    if let downloadedURL = try? latestDownloadedModel(named: name) {
        do {
            return try await MLModel.load(contentsOf: downloadedURL)
        } catch {
            // Downloaded model corrupted — fall back to bundled
            try? FileManager.default.removeItem(at: downloadedURL)
        }
    }

    // Fall back to bundled model
    guard let bundledURL = Bundle.main.url(forResource: name, withExtension: "mlmodelc") else {
        throw MLModelError.modelNotFound(name)
    }
    return try await MLModel.load(contentsOf: bundledURL)
}
```

## Testing ML Code Pattern

### Test with Known Inputs and Expected Outputs

```swift
import Testing
import CoreML

@Test
func imageClassifierRecognizesCat() async throws {
    let classifier = ImageClassifier()
    let catImage = UIImage(named: "test_cat", in: .test, with: nil)!

    let results = try await classifier.classify(catImage, maxResults: 3)

    #expect(!results.isEmpty)
    #expect(results[0].label == "cat" || results[0].label == "tabby")
    #expect(results[0].confidence > 0.7)
}
```

### Confidence Threshold Testing

```swift
@Test
func lowConfidenceResultsFiltered() async throws {
    let classifier = ImageClassifier()
    let ambiguousImage = UIImage(named: "test_ambiguous", in: .test, with: nil)!

    let results = try await classifier.classify(ambiguousImage, maxResults: 5)
    let filtered = results.filter { $0.confidence > 0.5 }

    // Ambiguous images should have no high-confidence results
    #expect(filtered.count <= 1)
}
```

### Performance Testing

```swift
@Test
func predictionLatencyUnder100ms() async throws {
    let classifier = ImageClassifier()
    let image = UIImage(named: "test_standard", in: .test, with: nil)!

    let start = ContinuousClock.now
    _ = try await classifier.classify(image)
    let elapsed = ContinuousClock.now - start

    #expect(elapsed < .milliseconds(100))
}
```

### Mock Model for Unit Tests

```swift
protocol ImageClassifying: Sendable {
    func classify(_ image: UIImage, maxResults: Int) async throws -> [Classification]
}

struct ImageClassifier: ImageClassifying {
    func classify(_ image: UIImage, maxResults: Int = 5) async throws -> [Classification] {
        // Real implementation using Vision
    }
}

struct MockImageClassifier: ImageClassifying {
    var stubbedResults: [Classification] = []
    var stubbedError: Error?

    func classify(_ image: UIImage, maxResults: Int) async throws -> [Classification] {
        if let error = stubbedError { throw error }
        return Array(stubbedResults.prefix(maxResults))
    }
}

// In tests
@Test
func viewModelUpdatesOnClassification() async {
    var mock = MockImageClassifier()
    mock.stubbedResults = [Classification(label: "dog", confidence: 0.95)]

    let viewModel = ClassifierViewModel(classifier: mock)
    await viewModel.classify(testImage)

    #expect(viewModel.topLabel == "dog")
    #expect(viewModel.confidence == 0.95)
}
```

### Edge Case Testing

```swift
@Test
func handlesEmptyImage() async {
    let classifier = ImageClassifier()
    let emptyImage = UIImage()

    await #expect(throws: MLModelError.self) {
        try await classifier.classify(emptyImage)
    }
}

@Test
func handlesVeryLargeImage() async throws {
    let classifier = ImageClassifier()
    // 4000x4000 image - should still work (Vision framework resizes internally)
    let largeImage = createTestImage(width: 4000, height: 4000)

    let results = try await classifier.classify(largeImage)
    #expect(!results.isEmpty)
}

@Test
func handlesModelNotFound() async {
    await #expect(throws: MLModelError.self) {
        try await MLModelManager.shared.model(named: "NonexistentModel")
    }
}
```

## Anti-Patterns to Avoid

### Don't Load Models Synchronously on Main Thread
```swift
// Wrong - blocks UI for seconds on large models
let model = try! MLModel(contentsOf: url)

// Right - async loading
let model = try await MLModel.load(contentsOf: url, configuration: config)
```

### Don't Process Every Camera Frame
```swift
// Wrong - overwhelms ML pipeline, drops frames, drains battery
func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, ...) {
    processWithML(sampleBuffer)  // Called 30-60 times per second
}

// Right - throttle to reasonable interval
guard Date().timeIntervalSince(lastProcessing) > 0.5 else { return }
```

### Don't Ignore Confidence Scores
```swift
// Wrong - trusts any result
let label = results.first!.identifier

// Right - filter by confidence
let label = results.first(where: { $0.confidence > 0.7 })?.identifier ?? "Unknown"
```

### Don't Hardcode Model Compute Units for All Devices
```swift
// Wrong - Neural Engine not available on all devices
config.computeUnits = .cpuAndNeuralEngine

// Right - let system choose
config.computeUnits = .all
```

### Don't Skip Error Handling for Predictions
```swift
// Wrong
let result = try! model.prediction(from: input)

// Right
do {
    let result = try model.prediction(from: input)
    handleResult(result)
} catch {
    handlePredictionError(error)
}
```
