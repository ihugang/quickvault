package com.quickvault.presentation;

import com.quickvault.presentation.lifecycle.AppLifecycleObserver;
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

  public MainActivity_MembersInjector(Provider<AppLifecycleObserver> appLifecycleObserverProvider) {
    this.appLifecycleObserverProvider = appLifecycleObserverProvider;
  }

  public static MembersInjector<MainActivity> create(
      Provider<AppLifecycleObserver> appLifecycleObserverProvider) {
    return new MainActivity_MembersInjector(appLifecycleObserverProvider);
  }

  @Override
  public void injectMembers(MainActivity instance) {
    injectAppLifecycleObserver(instance, appLifecycleObserverProvider.get());
  }

  @InjectedFieldSignature("com.quickvault.presentation.MainActivity.appLifecycleObserver")
  public static void injectAppLifecycleObserver(MainActivity instance,
      AppLifecycleObserver appLifecycleObserver) {
    instance.appLifecycleObserver = appLifecycleObserver;
  }
}
