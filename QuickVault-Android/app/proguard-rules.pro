# QuickVault ProGuard Rules

# Keep Hilt generated classes
-keep class dagger.hilt.** { *; }
-keep class javax.inject.** { *; }
-keep class * extends dagger.hilt.android.internal.managers.ViewComponentManager$FragmentContextWrapper { *; }

# Keep Room entities
-keep class com.quickvault.data.local.database.entity.** { *; }

# Keep DTO classes
-keep class com.quickvault.data.model.** { *; }

# Keep Compose
-keep class androidx.compose.** { *; }

# Keep Crypto classes
-keep class com.google.crypto.tink.** { *; }
-keep class androidx.security.crypto.** { *; }

# Keep coroutines
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}
