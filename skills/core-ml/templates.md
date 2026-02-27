# Core ML Swift Code Templates

Production-ready Swift templates for Core ML, Vision, and NaturalLanguage integration. All code uses modern Swift patterns: actors, async/await, structured concurrency, and protocol-based architecture.

## 1. MLModelManager.swift — Central Model Management

```swift
import CoreML
import os

/// Actor-based model manager for safe concurrent model loading and caching.
/// Provides lazy loading, memory management, and error handling for Core ML models.
actor MLModelManager {
    static let shared = MLModelManager()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "MLModelManager")
    private var loadedModels: [String: MLModel] = [:]

    /// Load a compiled Core ML model from the app bundle, caching it for reuse.
    /// - Parameters:
    ///   - name: The model filename without extension (e.g., "ImageClassifier")
    ///   - computeUnits: Hardware to use for inference. Defaults to `.all` (system chooses best).
    /// - Returns: The loaded MLModel instance.
    func model(named name: String, computeUnits: MLComputeUnits = .all) async throws -> MLModel {
        if let cached = loadedModels[name] {
            return cached
        }

        guard let url = Bundle.main.url(forResource: name, withExtension: "mlmodelc") else {
            logger.error("Model not found in bundle: \(name)")
            throw MLModelManagerError.modelNotFound(name)
        }

        let config = MLModelConfiguration()
        config.computeUnits = computeUnits

        logger.info("Loading model: \(name) with compute units: \(String(describing: computeUnits))")

        do {
            let model = try await MLModel.load(contentsOf: url, configuration: config)
            loadedModels[name] = model
            logger.info("Model loaded successfully: \(name)")
            return model
        } catch {
            logger.error("Failed to load model \(name): \(error.localizedDescription)")
            throw MLModelManagerError.loadFailed(name, error)
        }
    }

    /// Load a model from an arbitrary URL (e.g., downloaded model in Application Support).
    func model(at url: URL, name: String, computeUnits: MLComputeUnits = .all) async throws -> MLModel {
        if let cached = loadedModels[name] {
            return cached
        }

        let config = MLModelConfiguration()
        config.computeUnits = computeUnits

        let model = try await MLModel.load(contentsOf: url, configuration: config)
        loadedModels[name] = model
        return model
    }

    /// Unload a specific model to free memory.
    func unloadModel(named name: String) {
        loadedModels.removeValue(forKey: name)
        logger.info("Model unloaded: \(name)")
    }

    /// Unload all models. Call on memory warning.
    func unloadAll() {
        let count = loadedModels.count
        loadedModels.removeAll()
        logger.info("All models unloaded (\(count) models)")
    }

    /// Compile a raw .mlmodel file and return the compiled URL.
    /// Use this for models downloaded at runtime.
    func compileAndCache(modelAt sourceURL: URL, name: String) async throws -> URL {
        let compiledURL = try MLModel.compileModel(at: sourceURL)

        let cacheDir = try modelsCacheDirectory()
        let destination = cacheDir.appendingPathComponent("\(name).mlmodelc")

        let fm = FileManager.default
        if fm.fileExists(atPath: destination.path) {
            try fm.removeItem(at: destination)
        }
        try fm.moveItem(at: compiledURL, to: destination)

        return destination
    }

    private func modelsCacheDirectory() throws -> URL {
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = appSupport.appendingPathComponent("MLModels")
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
}

enum MLModelManagerError: Error, LocalizedError {
    case modelNotFound(String)
    case loadFailed(String, Error)
    case compileFailed(Error)
    case predictionFailed(Error)

    var errorDescription: String? {
        switch self {
        case .modelNotFound(let name):
            return "ML model '\(name)' not found in app bundle"
        case .loadFailed(let name, let error):
            return "Failed to load model '\(name)': \(error.localizedDescription)"
        case .compileFailed(let error):
            return "Model compilation failed: \(error.localizedDescription)"
        case .predictionFailed(let error):
            return "Prediction failed: \(error.localizedDescription)"
        }
    }
}
```

## 2. ImageClassifier.swift — Vision-Based Image Classification

```swift
import Vision
import UIKit
import os

/// Classifies images using Vision framework's built-in model.
/// No custom Core ML model required — uses Apple's on-device classification.
struct ImageClassifier {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "ImageClassifier")

    /// Classification result with label and confidence score.
    struct Classification: Sendable {
        let label: String
        let confidence: Float

        /// Confidence as a percentage string (e.g., "94.2%").
        var confidencePercent: String {
            String(format: "%.1f%%", confidence * 100)
        }
    }

    /// Classify an image using Vision's built-in image classifier.
    /// - Parameters:
    ///   - image: The UIImage to classify.
    ///   - maxResults: Maximum number of classifications to return (sorted by confidence).
    ///   - minimumConfidence: Minimum confidence threshold. Results below this are filtered out.
    /// - Returns: Array of classifications sorted by confidence (highest first).
    func classify(
        _ image: UIImage,
        maxResults: Int = 5,
        minimumConfidence: Float = 0.1
    ) async throws -> [Classification] {
        guard let cgImage = image.cgImage else {
            throw ImageClassifierError.invalidImage
        }

        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error {
                    continuation.resume(throwing: ImageClassifierError.visionError(error))
                    return
                }

                let results = (request.results as? [VNClassificationObservation] ?? [])
                    .filter { $0.confidence >= minimumConfidence }
                    .prefix(maxResults)
                    .map { Classification(label: $0.identifier, confidence: $0.confidence) }

                continuation.resume(returning: Array(results))
            }

            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: orientation,
                options: [:]
            )

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: ImageClassifierError.visionError(error))
            }
        }
    }

    /// Classify an image using a custom Core ML model via Vision.
    /// - Parameters:
    ///   - image: The UIImage to classify.
    ///   - modelURL: URL to the compiled .mlmodelc file.
    ///   - maxResults: Maximum number of results.
    /// - Returns: Array of classifications.
    func classify(
        _ image: UIImage,
        using modelURL: URL,
        maxResults: Int = 5
    ) async throws -> [Classification] {
        guard let cgImage = image.cgImage else {
            throw ImageClassifierError.invalidImage
        }

        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let vnModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: vnModel) { request, error in
                if let error {
                    continuation.resume(throwing: ImageClassifierError.visionError(error))
                    return
                }

                let results = (request.results as? [VNClassificationObservation] ?? [])
                    .prefix(maxResults)
                    .map { Classification(label: $0.identifier, confidence: $0.confidence) }

                continuation.resume(returning: Array(results))
            }

            // Let Vision handle image scaling
            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: orientation,
                options: [:]
            )

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: ImageClassifierError.visionError(error))
            }
        }
    }
}

enum ImageClassifierError: Error, LocalizedError {
    case invalidImage
    case visionError(Error)
    case noResults

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Could not extract image data for classification"
        case .visionError(let error):
            return "Vision framework error: \(error.localizedDescription)"
        case .noResults:
            return "No classification results returned"
        }
    }
}

// MARK: - CGImagePropertyOrientation Helper

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
```

## 3. TextAnalyzer.swift — NaturalLanguage Framework Wrapper

```swift
import NaturalLanguage
import os

/// Wrapper around Apple's NaturalLanguage framework for text analysis.
/// Provides sentiment analysis, language detection, tokenization, and entity recognition.
struct TextAnalyzer {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "TextAnalyzer")

    // MARK: - Sentiment Analysis

    /// Analyze sentiment of text.
    /// - Parameter text: The text to analyze.
    /// - Returns: Score from -1.0 (very negative) to +1.0 (very positive). 0.0 is neutral.
    func detectSentiment(_ text: String) -> Double {
        guard !text.isEmpty else { return 0.0 }

        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        let (tag, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        return Double(tag?.rawValue ?? "0") ?? 0.0
    }

    /// Sentiment category based on score thresholds.
    enum Sentiment: String, Sendable {
        case positive, neutral, negative

        init(score: Double) {
            if score > 0.1 { self = .positive }
            else if score < -0.1 { self = .negative }
            else { self = .neutral }
        }
    }

    /// Detect sentiment as a category.
    func sentimentCategory(_ text: String) -> Sentiment {
        Sentiment(score: detectSentiment(text))
    }

    // MARK: - Language Detection

    /// Detect the dominant language of text.
    /// - Parameter text: The text to analyze (best results with 20+ characters).
    /// - Returns: The detected language, or nil if undetermined.
    func detectLanguage(_ text: String) -> NLLanguage? {
        NLLanguageRecognizer.dominantLanguage(for: text)
    }

    /// Detect multiple possible languages with confidence scores.
    /// - Parameters:
    ///   - text: The text to analyze.
    ///   - maxResults: Maximum number of language hypotheses.
    /// - Returns: Dictionary mapping languages to confidence scores (0.0 to 1.0).
    func detectLanguages(_ text: String, maxResults: Int = 5) -> [(NLLanguage, Double)] {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.languageHypotheses(withMaximum: maxResults)
            .sorted { $0.value > $1.value }
            .map { ($0.key, $0.value) }
    }

    // MARK: - Tokenization

    /// Tokenize text into units (words, sentences, or paragraphs).
    /// - Parameters:
    ///   - text: The text to tokenize.
    ///   - unit: The tokenization unit (.word, .sentence, .paragraph).
    /// - Returns: Array of token strings.
    func tokenize(_ text: String, unit: NLTokenUnit = .word) -> [String] {
        guard !text.isEmpty else { return [] }

        let tokenizer = NLTokenizer(unit: unit)
        tokenizer.string = text

        return tokenizer.tokens(for: text.startIndex..<text.endIndex).map { range in
            String(text[range])
        }
    }

    /// Count words in text (language-aware, handles CJK and other scripts correctly).
    func wordCount(_ text: String) -> Int {
        tokenize(text, unit: .word).count
    }

    // MARK: - Named Entity Recognition

    /// Recognized entity with its text and type.
    struct Entity: Sendable {
        let text: String
        let type: EntityType
    }

    enum EntityType: String, Sendable {
        case person
        case place
        case organization
        case other

        init(tag: NLTag) {
            switch tag {
            case .personalName:      self = .person
            case .placeName:         self = .place
            case .organizationName:  self = .organization
            default:                 self = .other
            }
        }
    }

    /// Recognize named entities (people, places, organizations) in text.
    /// - Parameter text: The text to analyze.
    /// - Returns: Array of recognized entities with their types.
    func recognizeEntities(_ text: String) -> [Entity] {
        guard !text.isEmpty else { return [] }

        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        var entities: [Entity] = []
        let range = text.startIndex..<text.endIndex

        tagger.enumerateTags(in: range, unit: .word, scheme: .nameType, options: [.omitWhitespace, .omitPunctuation, .joinNames]) { tag, tokenRange in
            if let tag, tag != .other {
                entities.append(Entity(
                    text: String(text[tokenRange]),
                    type: EntityType(tag: tag)
                ))
            }
            return true
        }

        return entities
    }

    // MARK: - Part of Speech

    /// Tagged word with its part-of-speech tag.
    struct TaggedWord: Sendable {
        let word: String
        let tag: NLTag
    }

    /// Tag each word with its part of speech (noun, verb, adjective, etc.).
    func tagPartsOfSpeech(_ text: String) -> [TaggedWord] {
        guard !text.isEmpty else { return [] }

        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text

        var tagged: [TaggedWord] = []
        let range = text.startIndex..<text.endIndex

        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: [.omitWhitespace, .omitPunctuation]) { tag, tokenRange in
            if let tag {
                tagged.append(TaggedWord(word: String(text[tokenRange]), tag: tag))
            }
            return true
        }

        return tagged
    }

    // MARK: - Word Embedding / Similarity

    /// Compute cosine distance between two words using Apple's word embedding.
    /// - Parameters:
    ///   - word1: First word.
    ///   - word2: Second word.
    ///   - language: Language for the embedding model.
    /// - Returns: Distance from 0.0 (identical) to 2.0 (maximally different), or nil if embedding unavailable.
    func wordDistance(_ word1: String, _ word2: String, language: NLLanguage = .english) -> Double? {
        guard let embedding = NLEmbedding.wordEmbedding(for: language) else { return nil }
        return embedding.distance(between: word1, and: word2)
    }

    /// Find words similar to the given word.
    /// - Parameters:
    ///   - word: The reference word.
    ///   - maxResults: Maximum similar words to return.
    ///   - language: Language for the embedding model.
    /// - Returns: Array of (word, distance) tuples sorted by similarity.
    func similarWords(to word: String, maxResults: Int = 10, language: NLLanguage = .english) -> [(String, Double)] {
        guard let embedding = NLEmbedding.wordEmbedding(for: language) else { return [] }

        var results: [(String, Double)] = []
        embedding.enumerateNeighbors(for: word, maximumCount: maxResults) { neighbor, distance in
            results.append((neighbor, distance))
            return true
        }
        return results
    }
}
```

## 4. ModelConfiguration.swift — Configuration and Compute Unit Selection

```swift
import CoreML

/// Configuration presets for Core ML model inference.
/// Choose based on your app's performance and power requirements.
struct ModelConfig {
    let computeUnits: MLComputeUnits
    let maxPredictionBatchSize: Int
    let allowLowPrecision: Bool

    /// Maximum performance. Uses CPU, GPU, and Neural Engine.
    /// Best for: real-time camera processing, time-critical predictions.
    static let highPerformance = ModelConfig(
        computeUnits: .all,
        maxPredictionBatchSize: 10,
        allowLowPrecision: true
    )

    /// CPU only. Predictable latency, no GPU contention with UI rendering.
    /// Best for: background processing, when GPU is busy with rendering.
    static let lowPower = ModelConfig(
        computeUnits: .cpuOnly,
        maxPredictionBatchSize: 1,
        allowLowPrecision: false
    )

    /// CPU + Neural Engine. Good balance of speed and efficiency.
    /// Best for: most apps. Avoids GPU contention while using Neural Engine acceleration.
    static let balanced = ModelConfig(
        computeUnits: .cpuAndNeuralEngine,
        maxPredictionBatchSize: 5,
        allowLowPrecision: true
    )

    /// CPU + GPU. For devices without Neural Engine or when NE is unavailable.
    /// Best for: older devices, GPU-optimized models.
    static let gpuAccelerated = ModelConfig(
        computeUnits: .cpuAndGPU,
        maxPredictionBatchSize: 5,
        allowLowPrecision: true
    )

    /// Create an MLModelConfiguration from this config.
    func mlConfiguration() -> MLModelConfiguration {
        let config = MLModelConfiguration()
        config.computeUnits = computeUnits
        config.allowLowPrecisionAccumulationOnGPU = allowLowPrecision
        return config
    }
}
```

## 5. VisionService.swift — Vision Request Pipeline

```swift
import Vision
import UIKit
import os

/// Service for executing Vision framework requests with proper error handling
/// and image orientation support.
struct VisionService {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "VisionService")

    // MARK: - Text Recognition (OCR)

    /// Recognize text in an image.
    /// - Parameters:
    ///   - image: The image to scan.
    ///   - level: Recognition accuracy level. `.accurate` is slower but better.
    ///   - languages: Languages to recognize (e.g., ["en-US", "fr-FR"]). Nil for automatic.
    /// - Returns: Array of recognized text strings, ordered top-to-bottom.
    func recognizeText(
        in image: UIImage,
        level: VNRequestTextRecognitionLevel = .accurate,
        languages: [String]? = nil
    ) async throws -> [String] {
        guard let cgImage = image.cgImage else {
            throw VisionServiceError.invalidImage
        }

        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: VisionServiceError.requestFailed(error))
                    return
                }

                let results = (request.results ?? [])
                    .compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: results)
            }

            request.recognitionLevel = level
            if let languages {
                request.recognitionLanguages = languages
            }

            performRequest(request, on: cgImage, orientation: orientation, continuation: continuation)
        }
    }

    // MARK: - Face Detection

    /// Detected face with bounding box and optional landmarks.
    struct DetectedFace: Sendable {
        /// Bounding box in normalized coordinates (0.0 to 1.0, origin at bottom-left).
        let boundingBox: CGRect
        let landmarks: VNFaceLandmarks2D?
    }

    /// Detect faces in an image.
    /// - Parameters:
    ///   - image: The image to scan.
    ///   - includeLandmarks: Whether to detect facial landmarks (eyes, nose, mouth, etc.).
    /// - Returns: Array of detected faces.
    func detectFaces(
        in image: UIImage,
        includeLandmarks: Bool = false
    ) async throws -> [DetectedFace] {
        guard let cgImage = image.cgImage else {
            throw VisionServiceError.invalidImage
        }

        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        return try await withCheckedThrowingContinuation { continuation in
            if includeLandmarks {
                let request = VNDetectFaceLandmarksRequest { request, error in
                    if let error {
                        continuation.resume(throwing: VisionServiceError.requestFailed(error))
                        return
                    }

                    let results = (request.results ?? []).map { face in
                        DetectedFace(boundingBox: face.boundingBox, landmarks: face.landmarks)
                    }
                    continuation.resume(returning: results)
                }
                performRequest(request, on: cgImage, orientation: orientation, continuation: continuation)
            } else {
                let request = VNDetectFaceRectanglesRequest { request, error in
                    if let error {
                        continuation.resume(throwing: VisionServiceError.requestFailed(error))
                        return
                    }

                    let results = (request.results ?? []).map { face in
                        DetectedFace(boundingBox: face.boundingBox, landmarks: nil)
                    }
                    continuation.resume(returning: results)
                }
                performRequest(request, on: cgImage, orientation: orientation, continuation: continuation)
            }
        }
    }

    // MARK: - Barcode Detection

    /// Detected barcode with payload and symbology.
    struct DetectedBarcode: Sendable {
        let payload: String
        let symbology: VNBarcodeSymbology
        let boundingBox: CGRect
    }

    /// Detect barcodes and QR codes in an image.
    /// - Parameters:
    ///   - image: The image to scan.
    ///   - symbologies: Specific barcode types to look for. Nil for all supported types.
    /// - Returns: Array of detected barcodes.
    func detectBarcodes(
        in image: UIImage,
        symbologies: [VNBarcodeSymbology]? = nil
    ) async throws -> [DetectedBarcode] {
        guard let cgImage = image.cgImage else {
            throw VisionServiceError.invalidImage
        }

        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, error in
                if let error {
                    continuation.resume(throwing: VisionServiceError.requestFailed(error))
                    return
                }

                let results = (request.results ?? []).compactMap { barcode -> DetectedBarcode? in
                    guard let payload = barcode.payloadStringValue else { return nil }
                    return DetectedBarcode(
                        payload: payload,
                        symbology: barcode.symbology,
                        boundingBox: barcode.boundingBox
                    )
                }
                continuation.resume(returning: results)
            }

            if let symbologies {
                request.symbologies = symbologies
            }

            performRequest(request, on: cgImage, orientation: orientation, continuation: continuation)
        }
    }

    // MARK: - Body Pose Detection

    /// Detected body pose with joint positions.
    struct BodyPose: Sendable {
        let joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
        let confidence: Float
    }

    /// Detect human body poses in an image.
    /// - Parameter image: The image to analyze.
    /// - Returns: Array of detected body poses with joint positions.
    func detectBodyPose(in image: UIImage) async throws -> [BodyPose] {
        guard let cgImage = image.cgImage else {
            throw VisionServiceError.invalidImage
        }

        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectHumanBodyPoseRequest { request, error in
                if let error {
                    continuation.resume(throwing: VisionServiceError.requestFailed(error))
                    return
                }

                let results = (request.results ?? []).compactMap { observation -> BodyPose? in
                    guard let points = try? observation.recognizedPoints(.all) else { return nil }
                    let joints = points.reduce(into: [VNHumanBodyPoseObservation.JointName: CGPoint]()) { dict, pair in
                        if pair.value.confidence > 0.3 {
                            dict[pair.key] = pair.value.location
                        }
                    }
                    return BodyPose(joints: joints, confidence: observation.confidence)
                }
                continuation.resume(returning: results)
            }

            performRequest(request, on: cgImage, orientation: orientation, continuation: continuation)
        }
    }

    // MARK: - Private Helpers

    private func performRequest<T>(
        _ request: VNRequest,
        on cgImage: CGImage,
        orientation: CGImagePropertyOrientation,
        continuation: CheckedContinuation<T, Error>
    ) {
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: orientation,
            options: [:]
        )

        do {
            try handler.perform([request])
        } catch {
            continuation.resume(throwing: VisionServiceError.requestFailed(error))
        }
    }
}

enum VisionServiceError: Error, LocalizedError {
    case invalidImage
    case requestFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Could not extract image data for Vision processing"
        case .requestFailed(let error):
            return "Vision request failed: \(error.localizedDescription)"
        }
    }
}
```

## 6. SwiftUI Integration Examples

### Image Classification View

```swift
import SwiftUI

struct ClassifierView: View {
    @State private var selectedImage: UIImage?
    @State private var classifications: [ImageClassifier.Classification] = []
    @State private var isClassifying = false
    @State private var error: String?
    @State private var showingImagePicker = false

    private let classifier = ImageClassifier()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if isClassifying {
                    ProgressView("Classifying...")
                }

                if !classifications.isEmpty {
                    List(classifications, id: \.label) { item in
                        HStack {
                            Text(item.label)
                            Spacer()
                            Text(item.confidencePercent)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listStyle(.plain)
                }

                if let error {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            .padding()
            .navigationTitle("Image Classifier")
            .toolbar {
                Button("Choose Photo") { showingImagePicker = true }
            }
            .sheet(isPresented: $showingImagePicker) {
                // Use your image picker implementation
            }
            .onChange(of: selectedImage) { _, newImage in
                guard let newImage else { return }
                Task { await classifyImage(newImage) }
            }
        }
    }

    private func classifyImage(_ image: UIImage) async {
        isClassifying = true
        error = nil
        defer { isClassifying = false }

        do {
            classifications = try await classifier.classify(image, maxResults: 5, minimumConfidence: 0.05)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
```

### Text Analysis View

```swift
import SwiftUI

struct TextAnalysisView: View {
    @State private var inputText = ""
    @State private var sentiment: Double = 0
    @State private var language: String = ""
    @State private var entities: [TextAnalyzer.Entity] = []
    @State private var wordCount: Int = 0

    private let analyzer = TextAnalyzer()

    var body: some View {
        NavigationStack {
            Form {
                Section("Input") {
                    TextEditor(text: $inputText)
                        .frame(minHeight: 100)
                }

                if !inputText.isEmpty {
                    Section("Analysis") {
                        LabeledContent("Sentiment") {
                            HStack {
                                Text(sentimentEmoji)
                                Text(String(format: "%.2f", sentiment))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        LabeledContent("Language", value: language)
                        LabeledContent("Word Count", value: "\(wordCount)")
                    }

                    if !entities.isEmpty {
                        Section("Entities") {
                            ForEach(entities, id: \.text) { entity in
                                LabeledContent(entity.text, value: entity.type.rawValue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Text Analysis")
            .onChange(of: inputText) { _, newText in
                analyzeText(newText)
            }
        }
    }

    private func analyzeText(_ text: String) {
        sentiment = analyzer.detectSentiment(text)
        language = analyzer.detectLanguage(text)?.rawValue ?? "Unknown"
        entities = analyzer.recognizeEntities(text)
        wordCount = analyzer.wordCount(text)
    }

    private var sentimentEmoji: String {
        if sentiment > 0.1 { return "+" }
        else if sentiment < -0.1 { return "-" }
        else { return "~" }
    }
}
```
