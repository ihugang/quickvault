import Combine
import Foundation
import SwiftUI
import UIKit

/// Auto-lock manager / 自动锁定管理器
class AutoLockManager: ObservableObject {
    
    // MARK: - Properties
    
    private var lastActivityTime: Date = Date()
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private let lockAction: () -> Void
    private let userDefaults = UserDefaults.standard
    private let autoLockTimeoutKey = "com.quickvault.autoLockTimeout"
    
    // MARK: - Initialization
    
    init(lockAction: @escaping () -> Void) {
        self.lockAction = lockAction
        setupNotifications()
        startTimer()
    }
    
    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup Notifications
    
    private func setupNotifications() {
        // App enters background
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleBackgroundTransition()
            }
            .store(in: &cancellables)
        
        // App becomes active
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleForegroundTransition()
            }
            .store(in: &cancellables)
        
        // App will resign active (for app switcher)
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.handleResignActive()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkInactivity()
        }
    }
    
    private func checkInactivity() {
        let timeout = getAutoLockTimeout()
        
        // Never lock if timeout is -1
        guard timeout > 0 else { return }
        
        let elapsed = Date().timeIntervalSince(lastActivityTime)
        if elapsed >= TimeInterval(timeout) {
            lockAction()
        }
    }
    
    // MARK: - Activity Tracking
    
    func recordActivity() {
        lastActivityTime = Date()
    }
    
    // MARK: - Background/Foreground Handling
    
    private func handleBackgroundTransition() {
        // Lock immediately when entering background
        lockAction()
    }
    
    private func handleForegroundTransition() {
        // Reset activity time when coming back
        lastActivityTime = Date()
    }
    
    private func handleResignActive() {
        // This is called when app switcher is shown
        // We don't lock here, but the privacy screen should be shown
    }
    
    // MARK: - Settings
    
    private func getAutoLockTimeout() -> Int {
        let timeout = userDefaults.integer(forKey: autoLockTimeoutKey)
        // Default to 5 minutes if not set
        return timeout == 0 ? 300 : timeout
    }
}

/// Privacy screen overlay / 隐私屏幕遮罩
struct PrivacyScreenModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @State private var showPrivacyScreen = false
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if showPrivacyScreen {
                    PrivacyScreenView()
                        .transition(.opacity)
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                withAnimation(.easeInOut(duration: 0.2)) {
                    showPrivacyScreen = newPhase != .active
                }
            }
    }
}

/// Privacy screen view / 隐私屏幕视图
struct PrivacyScreenView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                Text("随取 / QuickVault")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
        }
    }
}

extension View {
    func privacyScreen() -> some View {
        modifier(PrivacyScreenModifier())
    }
}
