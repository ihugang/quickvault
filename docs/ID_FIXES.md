# Correct IDs (current)

This document records the correct identifiers to match the current build configuration.

## iOS App (QuickVault)
- Bundle ID (app): com.codans.quickvault.ios
- Bundle ID (tests): com.quickvault.ios.tests
- Bundle ID prefix (XcodeGen): com.quickvault

## CloudKit / iCloud
- CloudKit container identifier (entitlements): iCloud.com.QuickHold.app
- CloudKit container identifier (code): iCloud.com.QuickHold.app
  - NOTE: These two must match exactly (case-sensitive), and the provisioning profile must include this container.

## Entitlements (iOS)
- App Group: group.com.QuickHold.app
- Ubiquity KV store identifier: $(TeamIdentifierPrefix)com.QuickHold.app
- Keychain access group: $(AppIdentifierPrefix)com.QuickHold.ios
