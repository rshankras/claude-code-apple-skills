# CI/CD Setup Generator

Generate CI/CD configuration for automated builds, tests, and distribution of iOS/macOS apps.

## When to Use

- User wants to automate their build and test process
- User mentions GitHub Actions, Xcode Cloud, or fastlane
- User wants to set up TestFlight or App Store deployment
- User asks about continuous integration for their app

## Pre-Generation Checks

Before generating, verify:

1. **Existing CI Configuration**
   ```bash
   # Check for existing CI files
   ls -la .github/workflows/ 2>/dev/null
   ls -la ci_scripts/ 2>/dev/null
   ls -la fastlane/ 2>/dev/null
   ```

2. **Project Structure**
   ```bash
   # Find Xcode project/workspace
   find . -name "*.xcodeproj" -o -name "*.xcworkspace" | head -5
   ```

3. **Package Manager**
   ```bash
   # Check for SPM vs CocoaPods
   ls Package.swift 2>/dev/null
   ls Podfile 2>/dev/null
   ```

## Configuration Questions

### 1. CI/CD Platform
- **GitHub Actions** (Recommended) - Full control, extensive marketplace
- **Xcode Cloud** - Native Apple integration, simpler setup
- **Both** - GitHub for PRs/tests, Xcode Cloud for releases

### 2. Distribution Method
- **TestFlight** - Beta testing via App Store Connect
- **App Store** - Production releases
- **Direct** (macOS only) - Notarized DMG/PKG distribution
- **All** - Full pipeline from dev to production

### 3. Include fastlane?
- **Yes** - Advanced automation, match for code signing
- **No** - Simpler setup using xcodebuild directly

### 4. Code Signing Approach
- **Manual** - Certificates in GitHub Secrets
- **match** (fastlane) - Git-based certificate management
- **Xcode Cloud Managed** - Apple handles signing

## Generated Files

### GitHub Actions
```
.github/workflows/
├── build-test.yml        # PR checks, unit tests
├── deploy-testflight.yml # TestFlight deployment
└── deploy-appstore.yml   # App Store submission
```

### Xcode Cloud
```
ci_scripts/
├── ci_post_clone.sh      # Post-clone setup
└── ci_pre_xcodebuild.sh  # Pre-build configuration
```

### fastlane
```
fastlane/
├── Fastfile              # Lane definitions
├── Appfile               # App configuration
└── Matchfile             # Code signing (if using match)
```

## Integration Steps

### GitHub Actions Setup

1. **Add Repository Secrets** (Settings > Secrets and variables > Actions):
   - `APP_STORE_CONNECT_API_KEY_ID` - API Key ID
   - `APP_STORE_CONNECT_API_ISSUER_ID` - Issuer ID
   - `APP_STORE_CONNECT_API_KEY_CONTENT` - Private key (.p8 content)
   - `CERTIFICATE_P12` - Base64-encoded .p12 certificate
   - `CERTIFICATE_PASSWORD` - Certificate password
   - `PROVISIONING_PROFILE` - Base64-encoded provisioning profile

2. **Create App Store Connect API Key**:
   - Go to App Store Connect > Users and Access > Keys
   - Generate API Key with "App Manager" role
   - Download the .p8 file (only available once)

3. **Export Certificate**:
   ```bash
   # Export from Keychain as .p12, then base64 encode
   base64 -i certificate.p12 | pbcopy
   ```

### Xcode Cloud Setup

1. **Enable Xcode Cloud** in Xcode:
   - Product > Xcode Cloud > Create Workflow
   - Connect to App Store Connect

2. **Configure Workflow**:
   - Set start conditions (branch, PR, tag)
   - Configure environment variables
   - Set up post-actions (TestFlight, App Store)

3. **Add ci_scripts** to repository for customization

### fastlane Setup

1. **Install fastlane**:
   ```bash
   brew install fastlane
   ```

2. **Initialize** (if starting fresh):
   ```bash
   fastlane init
   ```

3. **Set up match** (optional, for code signing):
   ```bash
   fastlane match init
   fastlane match development
   fastlane match appstore
   ```

## Best Practices

### Caching
- Cache Swift Package Manager dependencies
- Cache DerivedData for faster builds
- Use selective caching to avoid stale artifacts

### Secrets Management
- Never commit certificates or keys
- Use environment variables for sensitive data
- Rotate API keys periodically

### Build Optimization
- Use incremental builds where possible
- Parallelize test execution
- Skip unnecessary steps on draft PRs

### Notifications
- Slack/Discord integration for build status
- Email notifications for failures
- GitHub status checks for PRs

## References

- [GitHub Actions for Xcode](https://github.com/actions/runner-images/blob/main/images/macos)
- [Xcode Cloud Documentation](https://developer.apple.com/documentation/xcode/xcode-cloud)
- [fastlane Documentation](https://docs.fastlane.tools)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
