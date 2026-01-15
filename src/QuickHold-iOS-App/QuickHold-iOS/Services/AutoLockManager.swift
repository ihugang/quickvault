import Combine
import Foundation
import SwiftUI
import UIKit
import QuickHoldCore

/// Auto-lock manager / 自动锁定管理器
/// 仅在以下情况触发安全验证：
/// 1. 应用从后台返回前台
/// 2. 系统锁屏后解锁
class AutoLockManager: ObservableObject {

    // MARK: - Properties

    private var backgroundTime: Date?
    private var cancellables = Set<AnyCancellable>()

    private let lockAction: () -> Void
    private let authService: AuthenticationService
    private let userDefaults = UserDefaults.standard
    private let autoLockTimeoutKey = "com.quickhold.autoLockTimeout"

    // 短暂切换豁免时间(秒): 如果切换时间少于此值,不触发锁定
    // Brief switch exemption: don't lock if background time is less than this
    private let briefSwitchThreshold: TimeInterval = 30

    // MARK: - Initialization

    init(authService: AuthenticationService, lockAction: @escaping () -> Void) {
        self.authService = authService
        self.lockAction = lockAction
        setupNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup Notifications
    
    private func setupNotifications() {
        // App enters background - 记录进入后台的时间
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleBackgroundTransition()
            }
            .store(in: &cancellables)
        
        // App becomes active - 从后台返回前台时检查是否需要验证
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
    
    // MARK: - Activity Tracking
    
    func recordActivity() {
        // 不再需要记录活动时间，因为我们只在后台返回时验证
    }
    
    // MARK: - Background/Foreground Handling
    
    private func handleBackgroundTransition() {
        // 记录进入后台的时间
        backgroundTime = Date()
    }
    
    private func handleForegroundTransition() {
        // 从后台返回前台时，检查是否需要重新验证

        // 首次启动时 backgroundTime 为 nil
        // 此时无需锁定,让 App 自然显示当前认证状态即可
        guard let bgTime = backgroundTime else {
            return
        }

        let timeout = getAutoLockTimeout()
        let elapsed = Date().timeIntervalSince(bgTime)

        // 如果设置为永不锁定（-1），则不需要验证
        if timeout < 0 {
            backgroundTime = nil
            return
        }

        // 短暂切换豁免：如果后台时间少于 30 秒,不触发锁定
        // Brief switch exemption: don't lock if background time is less than 30 seconds
        if elapsed < briefSwitchThreshold {
            backgroundTime = nil
            return
        }

        // 如果设置为立即锁定（0），或者后台时间超过设定值，则需要验证
        if timeout == 0 || elapsed >= TimeInterval(timeout) {
            lockAction()
        }

        backgroundTime = nil
    }
    
    private func handleResignActive() {
        // 进入应用切换器时，不锁定，但隐私屏幕会显示
    }
    
    // MARK: - Settings
    
    private func getAutoLockTimeout() -> Int {
        // 检查是否已设置过超时值
        if userDefaults.object(forKey: autoLockTimeoutKey) == nil {
            // 首次使用，设置默认值为 5 分钟 (300 秒)
            // First time, set default to 5 minutes (300 seconds)
            let defaultTimeout = 300
            userDefaults.set(defaultTimeout, forKey: autoLockTimeoutKey)
            return defaultTimeout
        }

        let timeout = userDefaults.integer(forKey: autoLockTimeoutKey)
        // -1 表示永不锁定 / Never lock
        // 0 表示立即锁定 / Lock immediately
        // >0 表示后台超过该秒数后锁定 / Lock after N seconds in background
        return timeout
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
                Image("center-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                
                Text("随取 / QuickHold")
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
