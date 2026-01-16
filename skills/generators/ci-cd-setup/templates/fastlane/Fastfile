# Fastfile
# Automated build and deployment lanes for iOS/macOS apps
#
# Installation:
#   brew install fastlane
#
# Usage:
#   fastlane test           # Run tests
#   fastlane beta           # Deploy to TestFlight
#   fastlane release        # Deploy to App Store
#   fastlane build_macos    # Build macOS app
#
# Documentation: https://docs.fastlane.tools

default_platform(:ios)

# ============================================
# iOS Platform
# ============================================

platform :ios do
  # ----------------------------------------
  # Before all lanes
  # ----------------------------------------
  before_all do
    # Setup CI environment if running on CI
    setup_ci if is_ci

    # Ensure we're on a clean git state (optional)
    # ensure_git_status_clean
  end

  # ----------------------------------------
  # Testing
  # ----------------------------------------
  desc "Run all tests"
  lane :test do
    run_tests(
      scheme: ENV["SCHEME"] || "YourApp",  # TODO: Replace with your scheme
      device: "iPhone 16",
      clean: true,
      code_coverage: true,
      result_bundle: true
    )
  end

  desc "Run tests and generate coverage report"
  lane :test_coverage do
    test

    # Generate coverage report (requires slather)
    # slather(
    #   scheme: ENV["SCHEME"] || "YourApp",
    #   proj: "YourApp.xcodeproj",
    #   html: true,
    #   output_directory: "coverage"
    # )
  end

  # ----------------------------------------
  # Code Signing
  # ----------------------------------------
  desc "Sync certificates and profiles using match"
  lane :sync_certificates do
    match(type: "development")
    match(type: "appstore")
  end

  desc "Sync development certificates"
  lane :sync_dev_certs do
    match(type: "development", readonly: is_ci)
  end

  desc "Sync distribution certificates"
  lane :sync_dist_certs do
    match(type: "appstore", readonly: is_ci)
  end

  # ----------------------------------------
  # Building
  # ----------------------------------------
  desc "Build for testing"
  lane :build do
    build_app(
      scheme: ENV["SCHEME"] || "YourApp",  # TODO: Replace with your scheme
      configuration: "Debug",
      skip_archive: true,
      skip_codesigning: true
    )
  end

  desc "Build release archive"
  lane :build_release do
    # Sync certificates first
    sync_dist_certs if is_ci

    build_app(
      scheme: ENV["SCHEME"] || "YourApp",  # TODO: Replace with your scheme
      configuration: "Release",
      export_method: "app-store",
      output_directory: "build",
      output_name: "YourApp.ipa"  # TODO: Replace with your app name
    )
  end

  # ----------------------------------------
  # TestFlight Deployment
  # ----------------------------------------
  desc "Deploy to TestFlight"
  lane :beta do
    # Increment build number
    increment_build_number(
      build_number: latest_testflight_build_number + 1
    )

    # Build
    build_release

    # Upload to TestFlight
    upload_to_testflight(
      skip_waiting_for_build_processing: true,
      distribute_external: false
    )

    # Commit version bump (optional)
    # commit_version_bump(
    #   message: "Bump build number [skip ci]"
    # )
  end

  desc "Deploy to TestFlight with external testers"
  lane :beta_external do
    beta

    # Distribute to external testers
    upload_to_testflight(
      distribute_external: true,
      groups: ["Beta Testers"],  # TODO: Set your tester group name
      changelog: "Bug fixes and improvements"
    )
  end

  # ----------------------------------------
  # App Store Deployment
  # ----------------------------------------
  desc "Deploy to App Store"
  lane :release do |options|
    # Bump version if specified
    if options[:bump]
      increment_version_number(bump_type: options[:bump])
    end

    # Run tests first
    test

    # Build release
    build_release

    # Upload to App Store
    upload_to_app_store(
      submit_for_review: options[:submit] || false,
      automatic_release: false,
      skip_screenshots: true,
      skip_metadata: true,
      precheck_include_in_app_purchases: false
    )
  end

  desc "Deploy to App Store and submit for review"
  lane :release_and_submit do
    release(submit: true)
  end

  # ----------------------------------------
  # Versioning
  # ----------------------------------------
  desc "Bump version number"
  lane :bump do |options|
    bump_type = options[:type] || "patch"
    increment_version_number(bump_type: bump_type)

    version = get_version_number
    UI.success("Version bumped to #{version}")
  end

  desc "Bump build number"
  lane :bump_build do
    increment_build_number

    build = get_build_number
    UI.success("Build number bumped to #{build}")
  end

  # ----------------------------------------
  # Utilities
  # ----------------------------------------
  desc "Generate app icons"
  lane :icons do
    # Requires appicon plugin: fastlane add_plugin appicon
    # appicon(
    #   appicon_image_file: "fastlane/metadata/app_icon.png",
    #   appicon_devices: [:iphone, :ipad],
    #   appicon_path: "YourApp/Assets.xcassets"
    # )
    UI.important("Icon generation requires appicon plugin")
  end

  desc "Take screenshots"
  lane :screenshots do
    capture_screenshots(
      scheme: ENV["SCHEME"] || "YourAppUITests",
      devices: [
        "iPhone 16 Pro Max",
        "iPhone 16",
        "iPad Pro (12.9-inch)"
      ],
      languages: ["en-US"],
      clear_previous_screenshots: true
    )
  end

  # ----------------------------------------
  # Error handling
  # ----------------------------------------
  error do |lane, exception|
    # Notify on error (configure as needed)
    # slack(
    #   message: "Error in lane #{lane}: #{exception.message}",
    #   success: false
    # )
    UI.error("Lane #{lane} failed: #{exception.message}")
  end

  after_all do |lane|
    UI.success("Successfully completed #{lane}")
  end
end

# ============================================
# macOS Platform
# ============================================

platform :mac do
  desc "Build macOS app"
  lane :build do
    build_mac_app(
      scheme: ENV["SCHEME"] || "YourApp",  # TODO: Replace with your scheme
      configuration: "Release",
      export_method: "developer-id",  # or "app-store" for Mac App Store
      output_directory: "build"
    )
  end

  desc "Build and notarize macOS app"
  lane :release do
    build

    # Notarize the app
    notarize(
      package: "build/YourApp.app",  # TODO: Replace with your app name
      bundle_id: ENV["BUNDLE_ID"] || "com.yourcompany.yourapp",
      username: ENV["APPLE_ID"],
      asc_provider: ENV["TEAM_ID"],
      print_log: true,
      verbose: true
    )
  end

  desc "Build for Mac App Store"
  lane :appstore do
    build_mac_app(
      scheme: ENV["SCHEME"] || "YourApp",
      configuration: "Release",
      export_method: "app-store",
      output_directory: "build"
    )

    upload_to_app_store(
      platform: "osx",
      skip_screenshots: true,
      skip_metadata: true
    )
  end
end
