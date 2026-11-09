# FirebaseContentKit

**Layer**: AppCore
**Purpose**: Firebase (Firestore + App Check; paket içerikleri Firestore `packContents` belgelerinde gzip'li) ile `RemoteContentSource`. GoogleService-Info.plist yoksa devre dışı.

## Public API

```swift
enum FirebaseBootstrap { configureIfAvailable() -> Bool; isConfigured }
struct FirebaseContentSource: RemoteContentSource
```

## Structure

Sources/FirebaseContentKit.swift

## Dependencies

- ContentKit, firebase-ios-sdk (FirebaseCore, FirebaseFirestore, FirebaseAppCheck)
