# Xcode Cloud Setup Guide

## Prerequisites

1. **Apple Developer Program** membership
2. **App Store Connect** access with Admin or App Manager role
3. Repository connected to Xcode Cloud (GitHub, GitLab, or Bitbucket)

## Initial Setup

### 1. Enable Xcode Cloud in Xcode

1. Open your project in Xcode
2. Navigate to **Product > Xcode Cloud > Create Workflow**
3. Sign in to App Store Connect if prompted
4. Select your app or create a new App Store Connect record

### 2. Connect Repository

1. Choose your source code provider (GitHub, GitLab, Bitbucket)
2. Authorize Xcode Cloud to access your repository
3. Select the repository containing your project

### 3. Create Your First Workflow

Xcode Cloud will suggest a default workflow. Customize as needed:

#### Start Conditions
- **Branch Changes**: Build on push to specific branches
- **Pull Request**: Build on PR creation/update
- **Tag Changes**: Build when tags are pushed
- **On Schedule**: Scheduled builds (e.g., nightly)

#### Environment
- Select Xcode version
- Select macOS version
- Set custom environment variables

#### Actions
- **Build**: Compile the project
- **Test**: Run unit tests
- **Analyze**: Static analysis
- **Archive**: Create deployable archive

#### Post-Actions
- **TestFlight Internal**: Distribute to internal testers
- **TestFlight External**: Distribute to external testers
- **App Store**: Submit to App Store

## Workflow Configurations

### Development Workflow (Feature Branches)

```
Start Condition: Branch starts with "feature/"
Actions: Build, Test
Post-Actions: None
```

### Pull Request Workflow

```
Start Condition: Pull Request to "main"
Actions: Build, Test, Analyze
Post-Actions: None
```

### Beta Workflow (develop branch)

```
Start Condition: Push to "develop"
Actions: Build, Test, Archive
Post-Actions: TestFlight Internal
```

### Release Workflow (version tags)

```
Start Condition: Tag matches "v*.*.*"
Actions: Build, Test, Archive
Post-Actions: TestFlight External, then App Store
```

## Environment Variables

Set in App Store Connect > Xcode Cloud > Workflow > Environment:

| Variable | Description | Secret |
|----------|-------------|--------|
| `API_BASE_URL` | Backend API URL | No |
| `SENTRY_DSN` | Error tracking DSN | Yes |
| `ANALYTICS_KEY` | Analytics API key | Yes |
| `FEATURE_FLAGS` | Build-time flags | No |

### Accessing in Code

```swift
// In your Swift code
let apiURL = ProcessInfo.processInfo.environment["API_BASE_URL"]
```

### Accessing in ci_scripts

```bash
# In ci_scripts
echo "API URL: $API_BASE_URL"
```

## ci_scripts

Place scripts in `ci_scripts/` directory at repository root:

| Script | When it runs |
|--------|--------------|
| `ci_post_clone.sh` | After repository clone |
| `ci_pre_xcodebuild.sh` | Before xcodebuild |
| `ci_post_xcodebuild.sh` | After successful build |

### Making Scripts Executable

```bash
chmod +x ci_scripts/*.sh
git add ci_scripts/
git commit -m "Add Xcode Cloud ci_scripts"
```

## Code Signing

Xcode Cloud manages code signing automatically:

1. **Automatic**: Xcode Cloud generates certificates and profiles
2. **Manual**: Use your own certificates (uploaded to App Store Connect)

### For Automatic Signing
- Ensure "Automatically manage signing" is enabled in Xcode
- Xcode Cloud will create necessary certificates/profiles

### For Manual Signing
1. Upload certificates to App Store Connect
2. Create provisioning profiles in App Store Connect
3. Reference profiles in your Xcode project

## Build Number Management

Xcode Cloud provides `CI_BUILD_NUMBER` environment variable.

### Option 1: Use in ci_pre_xcodebuild.sh

```bash
agvtool new-version -all "$CI_BUILD_NUMBER"
```

### Option 2: Configure in Build Settings

Set `CURRENT_PROJECT_VERSION` to `$(CI_BUILD_NUMBER)` in Xcode.

## Troubleshooting

### Build Fails: Missing Dependencies

Add dependency installation to `ci_post_clone.sh`:

```bash
brew install swiftlint
```

### Build Fails: Code Signing

1. Verify App Store Connect has correct bundle ID
2. Check provisioning profiles are valid
3. Ensure certificates haven't expired

### Tests Fail: Simulator Issues

Specify exact simulator in test action:
- Destination: iPhone 16
- OS Version: Latest

### Slow Builds

1. Use selective trigger conditions
2. Avoid installing unnecessary dependencies
3. Use caching where possible

## Monitoring

### In Xcode
- **Report Navigator** > Cloud tab shows all builds
- Click any build for detailed logs

### In App Store Connect
- **Xcode Cloud** section shows all workflows and builds
- Download build artifacts
- View test results

### Notifications
Configure in App Store Connect:
- Email notifications for build status
- Slack integration (via webhooks in ci_scripts)

## Best Practices

1. **Use ci_scripts sparingly** - Keep builds fast
2. **Cache dependencies** - Homebrew packages persist
3. **Use secrets for sensitive data** - Never hardcode API keys
4. **Test locally first** - Use `xcodebuild` commands locally
5. **Monitor build minutes** - Xcode Cloud has usage limits

## Pricing

Xcode Cloud includes:
- **25 compute hours/month** free (Apple Developer Program)
- Additional hours available for purchase
- Build minutes vary by Xcode version and machine type
