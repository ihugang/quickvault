package com.quickvault.data.local.keystore;

import android.content.Context;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

@ScopeMetadata("javax.inject.Singleton")
@QualifierMetadata
@DaggerGenerated
@Generated(
    value = "dagger.internal.codegen.ComponentProcessor",
    comments = "https://dagger.dev"
)
@SuppressWarnings({
    "unchecked",
    "rawtypes",
    "KotlinInternal",
    "KotlinInternalInJava"
})
public final class SecureKeyManager_Factory implements Factory<SecureKeyManager> {
  private final Provider<Context> contextProvider;

  public SecureKeyManager_Factory(Provider<Context> contextProvider) {
    this.contextProvider = contextProvider;
  }

  @Override
  public SecureKeyManager get() {
    return newInstance(contextProvider.get());
  }

  public static SecureKeyManager_Factory create(Provider<Context> contextProvider) {
    return new SecureKeyManager_Factory(contextProvider);
  }

  public static SecureKeyManager newInstance(Context context) {
    return new SecureKeyManager(context);
  }
}
