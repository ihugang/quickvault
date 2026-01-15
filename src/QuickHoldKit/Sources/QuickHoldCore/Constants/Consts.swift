//
//  Consts.swift
//  QuickHoldCore
//
//  Centralized identifiers/keys for consistent usage across the app.
//

import Foundation

public enum QuickHoldConstants {
  public enum CloudKit {
    public static let containerIdentifier = "iCloud.com.QuickHold.app"
  }

  public enum UserDefaultsKeys {
    public static let reportDeviceId = "com.quickhold.reportDeviceId"
    public static let autoLockTimeout = "com.quickhold.autoLockTimeout"
    public static let appearanceMode = "com.quickhold.appearanceMode"
    public static let biometricEnabled = "com.quickhold.biometricEnabled"
    public static let failedAttempts = "com.quickhold.failedAttempts"
    public static let lastFailedAttempt = "com.quickhold.lastFailedAttempt"
  }

  public enum KeychainKeys {
    public static let masterPassword = "com.quickhold.masterPassword"
    public static let biometricPassword = "com.quickhold.biometricPassword"
    public static let cryptoSalt = "crypto.salt"
  }
}
