# Repository Guidelines

## Project Structure & Module Organization
- `QuickVault/Sources/` holds the Swift package code. Core logic lives in `Core/`, features in `Features/`, and SwiftUI views in `Views/`.
- `QuickVault/Resources/` contains app assets, entitlements, and `Info.plist`.
- `QuickVault/Tests/` contains XCTest and SwiftCheck suites (one file per feature/service).
- `src/QuickVault/QuickVault.xcodeproj/` provides the Xcode project wrapper.
- Root `Resources/` is for product/design artifacts (not app runtime assets).

## Build, Test, and Development Commands
- `swift build` — build the Swift package in debug.
- `swift build -c release` — build optimized release artifacts.
- `swift package clean` — remove build outputs.
- `swift run` — run the app via SwiftPM.
- `open Package.swift` or `open QuickVault.xcodeproj` — open in Xcode.
- `swift test` — run the full test suite.
- `swift test --filter QuickVaultTests` — run a specific test suite.
- `swift test --enable-code-coverage` — generate coverage data.

## Coding Style & Naming Conventions
- Indentation: 2 spaces (match existing Swift files).
- Swift naming: `UpperCamelCase` for types, `lowerCamelCase` for functions/vars.
- User-facing strings follow bilingual format: `"中文 / English"`.
- Prefer MVVM + service layer separation (see `QuickVault/Sources/Core/`).

## Testing Guidelines
- Frameworks: XCTest for unit tests and SwiftCheck for property-based tests.
- File naming: `*Tests.swift` in `QuickVault/Tests/`.
- Property tests should cover core security paths; see design requirements in `.kiro/specs/quick-vault-macos/`.

## Commit & Pull Request Guidelines
- Commits follow a lightweight Conventional Commit style: `feat: ...`, `refactor: ...`, `fix: ...`.
- Keep subjects imperative and scoped to a single change.
- PRs should describe behavior changes, link related issues, and include screenshots/GIFs for UI updates.
- Note any security-relevant changes (crypto, Keychain, auth, entitlements) in the PR description.

## Security & Configuration Tips
- Encryption is field-level (AES-256-GCM); avoid storing secrets in plaintext models.
- Key material is stored in macOS Keychain; update `QuickVault/Resources/QuickVault.entitlements` if access needs change.
