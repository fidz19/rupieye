# Technical Architecture - TFLite + Groq Integration

## System Design

```
┌─────────────────────────────────────────────────────────────────┐
│                      Flutter Application                       │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                  ┌────────▼────────┐
                  │   app.dart      │
                  │ (Factory & DI)  │
                  └────────┬────────┘
                           │
          ┌────────────────▼────────────────┐
          │ Recognizer Selection Logic      │
          │ (Prioritized Chain)             │
          └───────┬──────────┬──────────┬────┘
                  │          │          │
        ┌─────────▼──────────▼──────────▼──────────┐
        │                                          │
   ┌────▼──────┐  ┌──────────┐  ┌──────────┐      │
   │   Groq    │  │Roboflow  │  │  Custom  │      │
   │  (NEW!)   │  │ (exist)  │  │   URL    │      │
   └────┬──────┘  └──────────┘  └──────────┘      │
        │                                │         │
        │    ┌────────────────────────────┘         │
        │    │                            ┌────────▼────────┐
        │    │                            │  TFLite Only    │
        │    │                            │  (Fallback)     │
        │    │                            └─────────────────┘
        │    │
        └────▼──────────────────────────────┐
             │                              │
     ┌───────▼────────┐            ┌────────▼──────────┐
     │   Hybrid       │            │  Online Only      │
     │  Recognizer    │            │  Recognizer       │
     │  (NEW!)        │            │  (if no Hybrid)   │
     └───────┬────────┘            └─────────────────┘
             │
             ├─────────────────┬──────────────────┐
             │                 │                  │
        ┌────▼──────┐  ┌───────▼────┐  ┌─────────▼──┐
        │  TFLite    │  │  Groq AI   │  │   Logging  │
        │ Recognizer │  │ Recognizer │  │  & Errors  │
        └────┬───────┘  └───────┬────┘  └────────────┘
             │                  │
             ├──────────┬───────┘
             │          │
             │    ┌─────▼──────────────┐
             │    │  Image Processing  │
             │    │  - Resize          │
             │    │  - Compress        │
             │    │  - Base64 Encode   │
             │    └────────────────────┘
             │
             ├─────────────────────────┐
             │                         │
        ┌────▼──────┐          ┌──────▼─────────┐
        │  Local    │          │ Groq API       │
        │ TFLite    │          │ https://api... │
        │ Model     │          │ (Internet)     │
        └───────────┘          └────────────────┘
```

## Class Hierarchy

```
CurrencyRecognizer (Abstract)
├── DemoCurrencyRecognizer
├── TfliteCurrencyRecognizer
├── OnlineCurrencyRecognizer
├── RoboflowCurrencyRecognizer
├── GroqCurrencyRecognizer (NEW)
├── HybridCurrencyRecognizer
│   ├── TfliteGroqCurrencyRecognizer (NEW)
│   ├── Other Hybrid Variants
```

## Data Flow

### Scenario 1: Successful TFLite Recognition

```
Image File
    ↓
TfliteGroqRecognizer.recognizeCurrency()
    ↓
Try TfliteCurrencyRecognizer
    ├─ Read Image Bytes
    ├─ Decode Image
    ├─ Resize to Model Input (224x224)
    ├─ Normalize Pixel Values (0-1)
    ├─ Run Inference
    └─ Get Confidence Scores
    ↓
Success? (Confidence > Threshold)
    ├─ YES → Return CurrencyRecognition ✓
    └─ NO → Continue to Groq...
```

### Scenario 2: TFLite Fails, Groq Fallback

```
Image File
    ↓
TfliteGroqRecognizer.recognizeCurrency()
    ↓
Try TfliteCurrencyRecognizer
    ├─ Process Image
    ├─ Run Model
    └─ Confidence too low or Error
    ↓
TfliteCurrencyRecognizer throws Exception
    ↓
Catch Exception → Try GroqCurrencyRecognizer
    ├─ Read Image Bytes
    ├─ Resize Image (max 1024)
    ├─ Compress to JPEG (quality: 78)
    ├─ Encode to Base64
    ├─ Create HTTP Request
    └─ POST to https://api.groq.com/openai/v1/chat/completions
    ↓
API Returns Response
    ├─ Parse JSON
    ├─ Extract Amount from nested response
    ├─ Extract Confidence
    └─ Validate (1000, 2000, ... 100000)
    ↓
Success? → Return CurrencyRecognition ✓
Fail? → Throw Exception ✗
```

## File Interactions

### groq_currency_recognizer.dart

```
┌─────────────────────────────────────┐
│  GroqCurrencyRecognizer             │
├─────────────────────────────────────┤
│ Properties                          │
│ - apiKey: String                    │
│ - model: String (meta-llama/llama-4-scout-17b-16e-instruct) │
│ - timeout: Duration                 │
│ - confidenceThreshold: double       │
│ - httpClient: HttpClient            │
├─────────────────────────────────────┤
│ Methods                             │
│ + recognizeCurrency()               │
│   - _prepareImageBase64()           │
│   - _callGroqApi()                  │
│   - _extractAmount()                │
│   - _extractConfidence()            │
└─────────────────────────────────────┘
       ↓
    Uses: dart:io (HttpClient)
    Uses: dart:convert (JSON, Base64)
    Uses: image package (Image processing)
    Returns: CurrencyRecognition or throws Exception
```

### tflite_groq_currency_recognizer.dart

```
┌─────────────────────────────────────────────┐
│  TfliteGroqCurrencyRecognizer               │
├─────────────────────────────────────────────┤
│ Properties                                  │
│ - tfliteRecognizer: CurrencyRecognizer      │
│ - groqRecognizer: CurrencyRecognizer        │
│ - tfliteHighConfidenceThreshold: double     │
│ - enableLogging: bool                       │
├─────────────────────────────────────────────┤
│ Methods                                     │
│ + recognizeCurrency()                       │
│   1. Try tfliteRecognizer.recognizeCurrency()
│   2. If fail → Try groqRecognizer           │
│   3. If both fail → Throw combined error    │
│ - _log(): void                              │
└─────────────────────────────────────────────┘
       ↓
    Delegates to:
    - TfliteCurrencyRecognizer (Primary)
    - GroqCurrencyRecognizer (Fallback)
```

### app.dart Integration

```
┌──────────────────────────────────────────┐
│  RupieyeApp._createDefaultRecognizer()   │
├──────────────────────────────────────────┤
│ Inputs:                                  │
│ - _groqApiKey (env)                      │
│ - _roboflowApiKey (env)                  │
│ - _onlineRecognizerUrl (env)             │
├──────────────────────────────────────────┤
│ Priority Chain:                          │
│ 1. If Groq Key exists                    │
│    → TfliteGroqCurrencyRecognizer ✓ NEW  │
│ 2. Else if Roboflow Key exists           │
│    → HybridCurrencyRecognizer (TF+RF)    │
│ 3. Else if URL exists                    │
│    → HybridCurrencyRecognizer (TF+URL)   │
│ 4. Else                                  │
│    → TfliteCurrencyRecognizer (TF only)  │
└──────────────────────────────────────────┘
```

## Environment Variables

```
String.fromEnvironment() di app.dart:

RUPIEYE_GROQ_API_KEY (NEW)
├─ Format: gsk_...
├─ Source: console.groq.com
├─ Passed: flutter build --dart-define=RUPIEYE_GROQ_API_KEY=xxx
└─ Used: Create GroqCurrencyRecognizer

RUPIEYE_ROBOFLOW_API_KEY (existing)
├─ Format: xxx
├─ Source: console.roboflow.com
└─ Used: Create RoboflowCurrencyRecognizer

RUPIEYE_ONLINE_RECOGNIZER_URL (existing)
├─ Format: http://localhost:8787
├─ Source: Backend server
└─ Used: Create OnlineCurrencyRecognizer
```

## Error Handling Chain

```
recognizeCurrency(imagePath) called
    ↓
1. Validate imagePath != null
2. Try TFLite:
   - File read error → CurrencyRecognitionException
   - Image decode error → CurrencyRecognitionException
   - Model not loaded → CurrencyRecognitionException
   - Confidence too low → CurrencyRecognitionException
   ↓ If any error → continue
3. Try Groq:
   - Network error → CurrencyRecognitionException
   - API 401/403 error → CurrencyRecognitionException
   - Invalid JSON response → CurrencyRecognitionException
   - Invalid denomination → CurrencyRecognitionException
   ↓ If all fail
4. Combine errors → Throw combined CurrencyRecognitionException
   with both TFLite error + Groq error
```

## Performance Characteristics

### TFLite (groq_currency_recognizer.dart)

```
Operation               Time        Notes
─────────────────────────────────────────────
Image Load             1-5ms       File I/O
Image Decode          20-50ms      Depends on format
Image Resize          30-100ms     224x224 target
Model Inference       50-150ms     CPU-bound
Post-processing       5-20ms       Score extraction
─────────────────────────────────────────────
Total                100-500ms     Typical
```

### Groq API Call

```
Operation               Time         Notes
─────────────────────────────────────────────
Image Process         100-200ms      Resize, compress
Request Build         10-20ms        JSON serialization
Network Upload        500-1000ms     Image base64
API Processing        1000-3000ms    Groq inference
Network Download      100-500ms      Response
Response Parse        20-50ms        JSON parsing
─────────────────────────────────────────────
Total                2000-5000ms     ~2-5 seconds
```

### Hybrid (tflite_groq_currency_recognizer.dart)

```
Case 1: TFLite Success
├─ Time: 100-500ms (fast path)
└─ Source: TFLite only

Case 2: TFLite Fail → Groq Success
├─ Time: 100-500ms + 2000-5000ms = 2100-5500ms
└─ Source: TFLite + Groq

Case 3: Both Fail
├─ Time: 100-500ms + 2000-5000ms = 2100-5500ms
└─ Source: TFLite + Groq (both fail)
```

## Dependencies

### Direct Dependencies Used

```
TfliteCurrencyRecognizer:
├─ tflite_flutter (plugin)
├─ image (pub.dev)
├─ flutter/services.dart
└─ dart:io, dart:math

GroqCurrencyRecognizer (NEW):
├─ image (pub.dev)
├─ dart:io (HttpClient)
├─ dart:convert (JSON, Base64)
└─ http (not needed - using dart:io)

TfliteGroqCurrencyRecognizer (NEW):
├─ No new dependencies
└─ Uses existing classes only
```

### No Additional Dependencies Required

The integration uses:
- ✓ `dart:io` - Built-in
- ✓ `dart:convert` - Built-in
- ✓ `image` package - Already in pubspec.yaml
- ✓ `tflite_flutter` - Already in pubspec.yaml

No new pubspec.yaml entries needed!

## Thread Safety

```
TfliteCurrencyRecognizer:
├─ TFLite Interpreter: NOT thread-safe
├─ Solution: Async/await ensures single execution
└─ Status: Safe ✓

GroqCurrencyRecognizer:
├─ HttpClient: Thread-safe
├─ Image processing: Thread-safe
└─ Status: Safe ✓

TfliteGroqCurrencyRecognizer:
├─ Sequential execution (no concurrency)
├─ No shared mutable state
└─ Status: Safe ✓
```

## Testing Strategy

### Unit Tests

```dart
test('GroqCurrencyRecognizer extracts amount correctly', () {
  final recognizer = GroqCurrencyRecognizer(apiKey: 'test_key');
  final amount = recognizer._extractAmount(mockJsonResponse);
  expect(amount, equals(100000));
});
```

### Integration Tests

```dart
testWidgets('Hybrid recognizer tries TFLite first', (tester) async {
  // Setup
  var tfliteCalled = false;
  var groqCalled = false;
  
  final hybrid = TfliteGroqCurrencyRecognizer(
    tfliteRecognizer: MockTFLiteRecognizer(onCall: () => tfliteCalled = true),
    groqRecognizer: MockGroqRecognizer(onCall: () => groqCalled = true),
  );
  
  // Execute
  await hybrid.recognizeCurrency(imagePath: 'test.jpg');
  
  // Assert
  expect(tfliteCalled, isTrue);
  expect(groqCalled, isFalse);
});
```

## Security Considerations

1. **API Key Management**
   - ✓ Not hardcoded in source
   - ✓ Passed via environment variable
   - ✓ Loaded at runtime from build context

2. **Image Handling**
   - ✓ Temporary files deleted after processing
   - ✓ Image compressed before transmission
   - ✓ Base64 encoding is reversible

3. **Network Communication**
   - ✓ HTTPS enforced (api.groq.com)
   - ✓ Standard TLS/SSL encryption
   - ✓ No sensitive data in URLs

## Future Enhancements

```
Potential improvements:

1. Caching
   - Cache recent recognition results
   - Reduce redundant API calls

2. Offline Mode
   - Queue requests when offline
   - Sync when connection restored

3. Multi-language Support
   - Translate Groq prompts
   - Localize error messages

4. Custom Model Support
   - Allow different Groq models
   - Model fallback chain

5. Analytics
   - Track recognition success rates
   - Monitor API usage
   - Performance metrics
```

---

**Architecture Version**: 1.0  
**Last Updated**: 2026-06-22  
**Compatibility**: Flutter 3.11.0+, Dart 3.11.0+
