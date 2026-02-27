---
name: core-ml
description: Core ML, Create ML, Vision framework, Natural Language framework, on-device ML integration. Use when user wants image classification, text analysis, object detection, sound classification, model optimization, or custom model integration. Covers Core ML vs Foundation Models decision.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Core ML Skills

Combined advisory, generator, and workflow skill for integrating machine learning into Apple platform apps. Covers Core ML model integration, Vision framework image analysis, NaturalLanguage framework text processing, Create ML training, and on-device model optimization.

## When This Skill Activates

Use this skill when the user:
- Wants to add ML capabilities to their app
- Needs to integrate a Core ML model (.mlmodel) into an Xcode project
- Wants to use the Vision framework for image analysis (faces, text recognition, body pose, object detection)
- Wants to use the NaturalLanguage framework for text processing (sentiment, entities, language detection)
- Needs to train a custom model with Create ML
- Wants to optimize a model for on-device use (quantization, pruning, palettization)
- Needs to choose between Core ML and Foundation Models (Apple Intelligence)
- Asks about image classification, object detection, sound classification, or tabular data prediction
- Wants real-time camera + ML processing

## Decision Guide: Core ML vs Foundation Models

Before generating code, determine which framework is appropriate.

### Use Foundation Models (Apple Intelligence) When:
- You need general-purpose text generation, summarization, or conversational AI
- Target is iOS 26+ / macOS 26+ (Foundation Models requires Apple Silicon + latest OS)
- The task is open-ended language understanding or generation
- You want `@Generable` structured output from natural language
- See `apple-intelligence/foundation-models/` skill for implementation

### Use Core ML When:
- You need specialized ML: image classification, object detection, sound classification, custom regression/classification
- You have a trained model (.mlmodel, .mlpackage) or plan to train one
- You need broad device support (iOS 14+ / macOS 11+)
- The task requires domain-specific predictions (medical imaging, product recognition, custom NLP)
- Performance-critical inference on Neural Engine or GPU

### Use Vision Framework When (No Custom Model Needed):
- Image classification using Apple's built-in models
- Face detection and facial landmark analysis
- Text recognition (OCR) with `VNRecognizeTextRequest`
- Body and hand pose detection
- Barcode and QR code scanning
- Image similarity and saliency detection
- Horizon detection, rectangle detection

### Use NaturalLanguage Framework When (No Custom Model Needed):
- Sentiment analysis on text
- Language identification
- Tokenization (word, sentence, paragraph boundaries)
- Named entity recognition (people, places, organizations)
- Word and sentence embeddings for similarity comparison
- Lemmatization and part-of-speech tagging

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check deployment target (Core ML requires iOS 11+ / macOS 10.13+; Vision requires iOS 11+; NaturalLanguage requires iOS 12+)
- [ ] Check for existing ML code or models
- [ ] Identify project structure and source file locations
- [ ] Determine if SwiftUI or UIKit/AppKit

### 2. Conflict Detection
Search for existing ML integration:
```
Glob: **/*Model*.swift, **/*Classifier*.swift, **/*Predictor*.swift, **/*.mlmodel, **/*.mlmodelc, **/*.mlpackage
Grep: "import CoreML" or "import Vision" or "import NaturalLanguage"
```

If found, ask user:
- Extend existing ML setup?
- Replace with new implementation?
- Add additional model/capability?

## Configuration Questions

Ask user via AskUserQuestion:

1. **What ML capability do you need?**
   - Image classification (identify objects in photos)
   - Object detection (locate objects with bounding boxes)
   - Text analysis (sentiment, entities, language)
   - Custom Core ML model integration
   - Vision framework (OCR, faces, poses)
   - Sound classification
   - Tabular data prediction

2. **Do you have a trained model, or need to train one?**
   - I have a .mlmodel / .mlpackage file
   - I want to train with Create ML
   - I want to use Apple's built-in models (Vision / NaturalLanguage)

3. **Performance requirements?**
   - Real-time (camera feed, < 33ms per prediction)
   - Interactive (user-initiated, < 500ms acceptable)
   - Background processing (batch, latency not critical)

## Core ML Model Integration

### Adding a Model to Xcode
1. Drag `.mlmodel` or `.mlpackage` into Xcode project navigator
2. Xcode auto-generates a Swift class with the model name
3. The generated class provides type-safe input/output interfaces
4. Xcode compiles to `.mlmodelc` at build time (optimized for device)

### Loading Models

```swift
// Option 1: Auto-generated class (simplest)
let model = try MyImageClassifier(configuration: MLModelConfiguration())

// Option 2: Generic MLModel loading (flexible)
let url = Bundle.main.url(forResource: "MyModel", withExtension: "mlmodelc")!
let config = MLModelConfiguration()
config.computeUnits = .all  // CPU + GPU + Neural Engine
let model = try MLModel(contentsOf: url, configuration: config)

// Option 3: Async loading (recommended for large models)
let model = try await MLModel.load(contentsOf: url, configuration: config)
```

### Making Predictions

```swift
// Type-safe prediction with auto-generated class
let input = MyImageClassifierInput(image: pixelBuffer)
let output = try model.prediction(input: input)
print(output.classLabel)       // "cat"
print(output.classLabelProbs)  // ["cat": 0.95, "dog": 0.04, ...]

// Batch predictions
let batch = MLArrayBatchProvider(array: inputs)
let results = try model.predictions(from: batch)
```

## Create ML Training Overview

### Image Classification
- **Minimum**: 10 images per category; **Recommended**: 40+ per category
- Organize images in folders named by category
- Supports JPEG, PNG, HEIC formats
- Data augmentation applied automatically (rotation, flip, crop)
- Transfer learning from Apple's base models

### Text Classification
- Training data: text samples with labels (CSV or JSON)
- Use cases: sentiment analysis, spam detection, topic classification, intent recognition
- Minimum 10 samples per class; 100+ recommended for accuracy

### Tabular Classification / Regression
- Structured data in CSV or JSON
- Automatic feature engineering
- Supports: Boosted Tree, Random Forest, Linear Regression, Decision Tree

### Sound Classification
- Audio files organized by category
- Environmental sounds, speech detection, music genre
- Minimum 10 samples per category at 15+ seconds each

### Object Detection
- Images with bounding box annotations (JSON format)
- Outputs bounding boxes + class labels + confidence
- Minimum 30 annotated images per class; 300+ recommended

### Training Approach
- **Xcode Create ML App**: Visual interface, drag-and-drop, no code required
- **CreateML Framework**: Programmatic training in Swift Playgrounds or macOS apps
- **coremltools (Python)**: Convert models from TensorFlow, PyTorch, ONNX to Core ML format

## Vision Framework Capabilities

| Capability | Request Class | Custom Model Needed? |
|---|---|---|
| Image classification | `VNClassifyImageRequest` | No (built-in) |
| Object detection | `VNDetectObjectsRequest` (custom model) | Yes |
| Face detection | `VNDetectFaceRectanglesRequest` | No |
| Face landmarks | `VNDetectFaceLandmarksRequest` | No |
| Text recognition (OCR) | `VNRecognizeTextRequest` | No |
| Body pose | `VNDetectHumanBodyPoseRequest` | No |
| Hand pose | `VNDetectHumanHandPoseRequest` | No |
| Barcode detection | `VNDetectBarcodesRequest` | No |
| Image saliency | `VNGenerateAttentionBasedSaliencyImageRequest` | No |
| Horizon detection | `VNDetectHorizonRequest` | No |
| Rectangle detection | `VNDetectRectanglesRequest` | No |
| Image similarity | `VNGenerateImageFeaturePrintRequest` | No |

### Vision Request Pipeline
```swift
// Multiple requests on the same image
let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try handler.perform([
    textRequest,     // OCR
    faceRequest,     // Face detection
    barcodeRequest   // Barcode scanning
])
// Each request's results are populated independently
```

## NaturalLanguage Framework

### Sentiment Analysis
Returns a score from -1.0 (negative) to +1.0 (positive):
```swift
let tagger = NLTagger(tagSchemes: [.sentimentScore])
tagger.string = "This app is amazing!"
let (tag, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
// tag?.rawValue == "0.9" (positive)
```

### Language Detection
```swift
let language = NLLanguageRecognizer.dominantLanguage(for: "Bonjour le monde")
// language == .french
```

### Tokenization
```swift
let tokenizer = NLTokenizer(unit: .word)
tokenizer.string = "Hello, world!"
tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
    print(text[range])  // "Hello" then "world"
    return true
}
```

### Named Entity Recognition
```swift
let tagger = NLTagger(tagSchemes: [.nameType])
tagger.string = "Tim Cook visited Apple Park in Cupertino."
tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, range in
    if let tag, tag != .other {
        print("\(text[range]): \(tag.rawValue)")
        // "Tim": PersonalName, "Cook": PersonalName
        // "Apple Park": OrganizationName, "Cupertino": PlaceName
    }
    return true
}
```

## Model Optimization

### Quantization (coremltools Python)
Reduces model size by lowering numerical precision:
- **Float32 to Float16**: ~50% size reduction, minimal accuracy loss
- **Float16 to Int8**: ~50% further reduction, test accuracy carefully

```python
import coremltools as ct
from coremltools.models.neural_network import quantization_utils

model = ct.models.MLModel("MyModel.mlmodel")

# Float16 quantization (safe default)
model_fp16 = quantization_utils.quantize_weights(model, nbits=16)
model_fp16.save("MyModel_fp16.mlmodel")

# Int8 quantization (aggressive, test accuracy)
model_int8 = quantization_utils.quantize_weights(model, nbits=8)
model_int8.save("MyModel_int8.mlmodel")
```

### Palettization
Reduces unique weight values using k-means clustering:
```python
from coremltools.optimize.coreml import palettize_weights, OpPalettizerConfig

config = OpPalettizerConfig(nbits=4)  # 16 unique values per tensor
model_palettized = palettize_weights(model, config)
```

### Pruning
Removes near-zero weights (sparse model):
```python
from coremltools.optimize.torch.pruning import MagnitudePruner, MagnitudePrunerConfig

config = MagnitudePrunerConfig(target_sparsity=0.75)  # Remove 75% of weights
pruner = MagnitudePruner(model, config)
```

### Optimization Guidelines
- Always benchmark accuracy after optimization
- Start with Float16 (safest, best effort-to-reward ratio)
- Test on target device (Neural Engine behavior differs from GPU)
- Profile with Xcode Instruments > Core ML Performance

## Performance Patterns

### Compute Unit Selection
```swift
let config = MLModelConfiguration()

// Best performance — let system choose CPU, GPU, or Neural Engine
config.computeUnits = .all

// CPU only — predictable latency, no GPU/NE contention
config.computeUnits = .cpuOnly

// CPU + Neural Engine — good balance, avoids GPU contention with UI
config.computeUnits = .cpuAndNeuralEngine

// CPU + GPU — when Neural Engine unavailable
config.computeUnits = .cpuAndGPU
```

### Async Prediction for UI Responsiveness
```swift
func classify(_ image: UIImage) async throws -> String {
    let model = try await MLModelManager.shared.model(named: "Classifier")
    // Prediction runs off main thread via structured concurrency
    let input = try MLDictionaryFeatureProvider(dictionary: ["image": image.pixelBuffer!])
    let result = try await Task.detached {
        try model.prediction(from: input)
    }.value
    return result.featureValue(for: "classLabel")?.stringValue ?? "unknown"
}
```

### Batch Processing
```swift
// Process multiple images efficiently
let inputs = images.map { MyModelInput(image: $0.pixelBuffer!) }
let batch = MLArrayBatchProvider(array: inputs)
let results = try model.predictions(from: batch)

for i in 0..<results.count {
    let output = results.features(at: i)
    print(output.featureValue(for: "classLabel")?.stringValue ?? "")
}
```

### Compile Model at Install Time
```swift
// Compile .mlmodel to .mlmodelc at install (not runtime)
// This is done automatically when you add .mlmodel to Xcode target
// For downloaded models, compile once and cache:
let compiledURL = try MLModel.compileModel(at: downloadedModelURL)
let permanentURL = appSupportDir.appendingPathComponent("MyModel.mlmodelc")
try FileManager.default.copyItem(at: compiledURL, to: permanentURL)
```

## Generation Process

### Step 1: Determine Capability
Based on user's answer to configuration questions, select the appropriate template(s) from `templates.md`.

### Step 2: Generate Core Files

| Capability | Files Generated |
|---|---|
| Any Core ML | `MLModelManager.swift` |
| Image classification | `ImageClassifier.swift` |
| Text analysis | `TextAnalyzer.swift` |
| Vision requests | `VisionService.swift` |
| Custom model | `ModelConfig.swift` + model-specific predictor |
| Camera + ML | `CameraMLPipeline.swift` |

### Step 3: Determine File Location

Check project structure:
- If `Sources/` exists -> `Sources/ML/`
- If `App/Services/` exists -> `App/Services/ML/`
- If `App/` exists -> `App/ML/`
- Otherwise -> `ML/`

## Output Format

After generation, provide:

### Files Created
```
ML/
├── MLModelManager.swift        # Central model lifecycle management
├── ImageClassifier.swift       # Vision-based image classification (if needed)
├── TextAnalyzer.swift          # NaturalLanguage wrapper (if needed)
├── ModelConfig.swift           # Compute unit configuration
└── VisionService.swift         # Vision request pipeline (if needed)
```

### Integration Steps
1. Add `.mlmodel` file to Xcode project (if using custom model)
2. Import the generated ML service files
3. Initialize the service in your app's dependency injection
4. Call prediction methods from your views/view models
5. Handle errors and display results

### Testing
- Use known test inputs with expected outputs
- Verify confidence thresholds
- Profile prediction latency on target device
- Test graceful degradation when model unavailable

## References

- **patterns.md** — Architecture patterns, model manager, Vision pipeline, camera + ML, testing
- **templates.md** — Production-ready Swift code templates for all ML capabilities
- Apple Docs: [Core ML Documentation](https://developer.apple.com/documentation/coreml)
- Apple Docs: [Vision Documentation](https://developer.apple.com/documentation/vision)
- Apple Docs: [NaturalLanguage Documentation](https://developer.apple.com/documentation/naturallanguage)
- Apple Docs: [Create ML Documentation](https://developer.apple.com/documentation/createml)
