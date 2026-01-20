package com.quickvault.presentation;

import com.quickvault.presentation.lifecycle.AppLifecycleObserver;
import com.quickvault.util.ThemeManager;
import dagger.MembersInjector;
import dagger.internal.DaggerGenerated;
import dagger.internal.InjectedFieldSignature;
import dagger.internal.QualifierMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

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
public final class MainActivity_MembersInjector implements MembersInjector<MainActivity> {
  private final Provider<AppLifecycleObserver> appLifecycleObserverProvider;

  private final Provider<ThemeManager> themeManagerProvider;

  public MainActivity_MembersInjector(Provider<AppLifecycleObserver> appLifecycleObserverProvider,
      Provider<ThemeManager> themeManagerProvider) {
    this.appLifecycleObserverProvider = appLifecycleObserverProvider;
    this.themeManagerProvider = themeManagerProvider;
  }

  public static MembersInjector<MainActivity> create(
      Provider<AppLifecycleObserver> appLifecycleObserverProvider,
      Provider<ThemeManager> themeManagerProvider) {
    return new MainActivity_MembersInjector(appLifecycleObserverProvider, themeManagerProvider);
  }

  @Override
  public void injectMembers(MainActivity instance) {
    injectAppLifecycleObserver(instance, appLifecycleObserverProvider.get());
    injectThemeManager(instance, themeManagerProvider.get());
  }

  @InjectedFieldSignature("com.quickvault.presentation.MainActivity.appLifecycleObserver")
  public static void injectAppLifecycleObserver(MainActivity instance,
      AppLifecycleObserver appLifecycleObserver) {
    instance.appLifecycleObserver = appLifecycleObserver;
  }

  @InjectedFieldSignature("com.quickvault.presentation.MainActivity.themeManager")
  public static void injectThemeManager(MainActivity instance, ThemeManager themeManager) {
    instance.themeManager = themeManager;
  }
}
