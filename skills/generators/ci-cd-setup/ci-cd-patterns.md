# CI/CD Patterns

Best practices for continuous integration and deployment of iOS/macOS apps.

## GitHub Actions

### Runner Selection

```yaml
# macOS runners for Xcode builds
runs-on: macos-14  # M1 runner with Xcode 15+
runs-on: macos-15  # Latest with Xcode 16+

# Available Xcode versions (check runner images for current list)
# https://github.com/actions/runner-images/blob/main/images/macos
```

### Xcode Version Selection

```yaml
- name: Select Xcode
  run: sudo xcode-select -s /Applications/Xcode_16.2.app/Contents/Developer

# Or use xcodes action for flexibility
- uses: maxim-lobanov/setup-xcode@v1
  with:
    xcode-version: '16.2'
```

### Caching Strategies

```yaml
# Swift Package Manager cache
- name: Cache SPM
  uses: actions/cache@v4
  with:
    path: |
      .build
      ~/Library/Caches/org.swift.swiftpm
    key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
    restore-keys: |
      ${{ runner.os }}-spm-

# DerivedData cache (use with caution - can cause stale builds)
- name: Cache DerivedData
  uses: actions/cache@v4
  with:
    path: ~/Library/Developer/Xcode/DerivedData
    key: ${{ runner.os }}-derived-${{ hashFiles('**/*.xcodeproj/project.pbxproj') }}
```

### Code Signing

```yaml
# Import certificate and provisioning profile
- name: Install Certificates
  env:
    CERTIFICATE_P12: ${{ secrets.CERTIFICATE_P12 }}
    CERTIFICATE_PASSWORD: ${{ secrets.CERTIFICATE_PASSWORD }}
    PROVISIONING_PROFILE: ${{ secrets.PROVISIONING_PROFILE }}
  run: |
    # Create temporary keychain
    KEYCHAIN_PATH=$RUNNER_TEMP/signing.keychain-db
    KEYCHAIN_PASSWORD=$(openssl rand -base64 32)

    security create-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
    security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
    security unlock-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH

    # Import certificate
    echo "$CERTIFICATE_P12" | base64 --decode > $RUNNER_TEMP/certificate.p12
    security import $RUNNER_TEMP/certificate.p12 \
      -P "$CERTIFICATE_PASSWORD" \
      -A -t cert -f pkcs12 \
      -k $KEYCHAIN_PATH

    security set-key-partition-list -S apple-tool:,apple: \
      -k "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
    security list-keychain -d user -s $KEYCHAIN_PATH

    # Install provisioning profile
    mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
    echo "$PROVISIONING_PROFILE" | base64 --decode \
      > ~/Library/MobileDevice/Provisioning\ Profiles/profile.mobileprovision

- name: Cleanup Keychain
  if: always()
  run: |
    security delete-keychain $RUNNER_TEMP/signing.keychain-db || true
```

### App Store Connect API

```yaml
- name: Upload to TestFlight
  env:
    API_KEY_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_ID }}
    API_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_API_ISSUER_ID }}
    API_KEY_CONTENT: ${{ secrets.APP_STORE_CONNECT_API_KEY_CONTENT }}
  run: |
    # Create API key file
    mkdir -p ~/.private_keys
    echo "$API_KEY_CONTENT" > ~/.private_keys/AuthKey_$API_KEY_ID.p8

    # Upload using xcrun altool or notarytool
    xcrun altool --upload-app \
      --type ios \
      --file "$IPA_PATH" \
      --apiKey "$API_KEY_ID" \
      --apiIssuer "$API_ISSUER_ID"
```

## Xcode Cloud

### Workflow Configuration

Xcode Cloud workflows are configured in App Store Connect or Xcode, but ci_scripts allow customization.

### ci_scripts Lifecycle

```
1. ci_post_clone.sh    - After repository clone
2. ci_pre_xcodebuild.sh - Before xcodebuild runs
3. ci_post_xcodebuild.sh - After successful build
```

### Environment Variables

```bash
# Available in ci_scripts
$CI                    # Always "TRUE" in Xcode Cloud
$CI_WORKSPACE          # Path to workspace
$CI_PRODUCT            # Product name
$CI_XCODE_PROJECT      # Project path
$CI_XCODE_SCHEME       # Scheme name
$CI_BRANCH             # Git branch
$CI_TAG                # Git tag (if triggered by tag)
$CI_COMMIT             # Commit SHA
$CI_BUILD_NUMBER       # Xcode Cloud build number
$CI_BUNDLE_ID          # Bundle identifier
$CI_TEAM_ID            # Apple Developer Team ID
```

### Custom Environment Variables

Set in App Store Connect > Xcode Cloud > Workflow > Environment:
- `API_BASE_URL` - Environment-specific URLs
- `FEATURE_FLAGS` - Build-time feature toggles
- `SENTRY_DSN` - Error monitoring (as secret)

## fastlane

### Lane Organization

```ruby
# Fastfile structure
default_platform(:ios)

platform :ios do
  # Shared setup
  before_all do
    setup_ci if is_ci
  end

  # Development
  lane :test do
    run_tests(scheme: "MyApp")
  end

  # Beta distribution
  lane :beta do
    increment_build_number
    build_app(scheme: "MyApp")
    upload_to_testflight
  end

  # Production release
  lane :release do
    increment_build_number
    build_app(scheme: "MyApp")
    upload_to_app_store(
      submit_for_review: true,
      automatic_release: false
    )
  end

  # Error handling
  error do |lane, exception|
    # Notify on failure (Slack, etc.)
  end
end
```

### Code Signing with match

```ruby
# Matchfile
git_url("git@github.com:yourorg/certificates.git")
storage_mode("git")
type("appstore")  # development, adhoc, appstore
app_identifier(["com.yourcompany.app"])
username("your@email.com")

# In Fastfile
lane :sync_certificates do
  match(type: "development")
  match(type: "appstore")
end
```

### Build Actions

```ruby
# Build for testing
lane :build_for_testing do
  build_app(
    scheme: "MyApp",
    configuration: "Debug",
    build_for_testing: true,
    derived_data_path: "build/DerivedData"
  )
end

# Build for release
lane :build_release do
  build_app(
    scheme: "MyApp",
    configuration: "Release",
    export_method: "app-store",
    output_directory: "build",
    output_name: "MyApp.ipa"
  )
end
```

### Versioning

```ruby
# Increment version
lane :bump_version do |options|
  increment_version_number(
    bump_type: options[:type] || "patch"  # major, minor, patch
  )
end

# Increment build number
lane :bump_build do
  increment_build_number(
    build_number: latest_testflight_build_number + 1
  )
end
```

## macOS Notarization

### Using notarytool

```bash
# Submit for notarization
xcrun notarytool submit MyApp.dmg \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "$APP_SPECIFIC_PASSWORD" \
  --wait

# Staple the notarization ticket
xcrun stapler staple MyApp.dmg
```

### In GitHub Actions

```yaml
- name: Notarize App
  env:
    APPLE_ID: ${{ secrets.APPLE_ID }}
    TEAM_ID: ${{ secrets.TEAM_ID }}
    APP_PASSWORD: ${{ secrets.APP_SPECIFIC_PASSWORD }}
  run: |
    xcrun notarytool submit build/MyApp.dmg \
      --apple-id "$APPLE_ID" \
      --team-id "$TEAM_ID" \
      --password "$APP_PASSWORD" \
      --wait

    xcrun stapler staple build/MyApp.dmg
```

### With fastlane

```ruby
lane :notarize do
  notarize(
    package: "build/MyApp.dmg",
    bundle_id: "com.yourcompany.app",
    username: ENV["APPLE_ID"],
    asc_provider: ENV["TEAM_ID"]
  )
end
```

## Testing Strategies

### Unit Tests

```yaml
- name: Run Unit Tests
  run: |
    xcodebuild test \
      -scheme MyApp \
      -destination 'platform=iOS Simulator,name=iPhone 16' \
      -resultBundlePath TestResults.xcresult \
      | xcbeautify
```

### UI Tests

```yaml
- name: Run UI Tests
  run: |
    xcodebuild test \
      -scheme MyAppUITests \
      -destination 'platform=iOS Simulator,name=iPhone 16' \
      -testPlan UITests \
      | xcbeautify
```

### Parallel Testing

```yaml
- name: Run Tests in Parallel
  run: |
    xcodebuild test \
      -scheme MyApp \
      -destination 'platform=iOS Simulator,name=iPhone 16' \
      -parallel-testing-enabled YES \
      -parallel-testing-worker-count 4
```

## Build Matrix

### Multiple Platform Builds

```yaml
strategy:
  matrix:
    include:
      - platform: iOS
        destination: 'platform=iOS Simulator,name=iPhone 16'
      - platform: macOS
        destination: 'platform=macOS'
      - platform: watchOS
        destination: 'platform=watchOS Simulator,name=Apple Watch Series 10'

steps:
  - name: Build for ${{ matrix.platform }}
    run: |
      xcodebuild build \
        -scheme MyApp \
        -destination '${{ matrix.destination }}'
```

### Multiple Xcode Versions

```yaml
strategy:
  matrix:
    xcode: ['15.4', '16.0', '16.2']

steps:
  - uses: maxim-lobanov/setup-xcode@v1
    with:
      xcode-version: ${{ matrix.xcode }}
```

## Workflow Triggers

### Branch-Based

```yaml
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
```

### Tag-Based Releases

```yaml
on:
  push:
    tags:
      - 'v*.*.*'
```

### Manual Triggers

```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deployment environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production
```

## Notifications

### Slack Integration

```yaml
- name: Notify Slack
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "Build failed for ${{ github.repository }}",
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "*Build Failed* :x:\n*Repo:* ${{ github.repository }}\n*Branch:* ${{ github.ref_name }}"
            }
          }
        ]
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

### GitHub Status Checks

```yaml
- name: Update Commit Status
  uses: actions/github-script@v7
  with:
    script: |
      github.rest.repos.createCommitStatus({
        owner: context.repo.owner,
        repo: context.repo.repo,
        sha: context.sha,
        state: 'success',
        description: 'Build passed',
        context: 'CI/Build'
      })
```
