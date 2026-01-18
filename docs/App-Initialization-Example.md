# QuickVault 应用初始化示例

本文档展示如何在 iOS 和 macOS 应用中正确初始化 `AuthenticationService`，以支持多设备 iCloud 同步。

---

## ⚠️ 重要说明

**必须在 App 启动时调用 `checkInitialState()`**，否则：
- ❌ 第二台设备会误判为首次设置，要求用户重新初始化密码
- ❌ 即使 CloudKit 中有数据，也无法正确识别
- ❌ 用户体验非常糟糕

---

## iOS SwiftUI 应用示例

### 方案 1：在 @main App 中初始化（推荐）

```swift
import SwiftUI
import QuickHoldCore

@main
struct QuickHoldApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .task {
                    // App 启动时检查认证状态
                    await appState.checkInitialState()
                }
        }
    }
}

// MARK: - App State

@MainActor
class AppState: ObservableObject {
    @Published var authenticationState: AuthenticationState = .initializing

    let persistenceController: PersistenceController
    let keychainService: KeychainService
    let authService: AuthenticationService

    init() {
        self.persistenceController = PersistenceController.shared
        self.keychainService = KeychainServiceImpl()
        self.authService = AuthenticationServiceImpl(
            keychainService: keychainService,
            persistenceController: persistenceController
        )

        // 订阅状态变化
        Task {
            for await state in authService.authenticationStatePublisher.values {
                self.authenticationState = state
            }
        }
    }

    func checkInitialState() async {
        await authService.checkInitialState()
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        switch appState.authenticationState {
        case .initializing:
            // 显示加载界面
            LoadingView()

        case .setupRequired:
            // 显示初始化密码界面（首次设置）
            SetupPasswordView()

        case .locked:
            // 显示登录界面
            LoginView()

        case .waitingForCloudSync:
            // 显示等待 iCloud 同步界面
            WaitingForSyncView()

        case .unlocked:
            // 显示主界面
            MainView()
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
            Text("正在初始化...")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Waiting For Sync View

struct WaitingForSyncView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()

            Text("等待 iCloud 同步...")
                .font(.headline)

            Text("正在从主设备同步加密密钥，请稍候")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("重试") {
                Task {
                    await appState.checkInitialState()
                }
            }
            .buttonStyle(.bordered)
            .padding(.top)

            Text("提示：请确保已登录 iCloud 并启用 iCloud 钥匙串")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 20)
        }
        .padding()
    }
}
```

---

### 方案 2：在 SceneDelegate 中初始化（UIKit）

```swift
import UIKit
import QuickHoldCore

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var appCoordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // 创建 window
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // 初始化服务
        let persistenceController = PersistenceController.shared
        let keychainService = KeychainServiceImpl()
        let authService = AuthenticationServiceImpl(
            keychainService: keychainService,
            persistenceController: persistenceController
        )

        // 创建 coordinator
        let coordinator = AppCoordinator(
            window: window,
            authService: authService,
            persistenceController: persistenceController
        )
        self.appCoordinator = coordinator

        // 启动应用
        coordinator.start()

        // 异步检查初始状态
        Task {
            await authService.checkInitialState()
        }
    }
}

// MARK: - App Coordinator

class AppCoordinator {
    private let window: UIWindow
    private let authService: AuthenticationService
    private let persistenceController: PersistenceController
    private var cancellables = Set<AnyCancellable>()

    init(window: UIWindow, authService: AuthenticationService, persistenceController: PersistenceController) {
        self.window = window
        self.authService = authService
        self.persistenceController = persistenceController
    }

    func start() {
        // 订阅认证状态变化
        authService.authenticationStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleAuthenticationStateChange(state)
            }
            .store(in: &cancellables)

        // 显示初始界面
        handleAuthenticationStateChange(authService.authenticationState)

        window.makeKeyAndVisible()
    }

    private func handleAuthenticationStateChange(_ state: AuthenticationState) {
        let viewController: UIViewController

        switch state {
        case .initializing:
            viewController = LoadingViewController()

        case .setupRequired:
            viewController = SetupPasswordViewController(authService: authService)

        case .locked:
            viewController = LoginViewController(authService: authService)

        case .waitingForCloudSync:
            viewController = WaitingForSyncViewController(authService: authService)

        case .unlocked:
            viewController = MainTabBarController(
                authService: authService,
                persistenceController: persistenceController
            )
        }

        window.rootViewController = viewController
    }
}
```

---

## macOS AppKit 应用示例

```swift
import Cocoa
import QuickHoldCore

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var authService: AuthenticationService!
    private var persistenceController: PersistenceController!
    private var windowController: NSWindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 初始化服务
        persistenceController = PersistenceController.shared
        let keychainService = KeychainServiceImpl()
        authService = AuthenticationServiceImpl(
            keychainService: keychainService,
            persistenceController: persistenceController
        )

        // 订阅认证状态变化
        authService.authenticationStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleAuthenticationStateChange(state)
            }
            .store(in: &cancellables)

        // 异步检查初始状态
        Task {
            await authService.checkInitialState()
        }
    }

    private var cancellables = Set<AnyCancellable>()

    private func handleAuthenticationStateChange(_ state: AuthenticationState) {
        switch state {
        case .initializing:
            showLoadingWindow()

        case .setupRequired:
            showSetupPasswordWindow()

        case .locked:
            showLoginWindow()

        case .waitingForCloudSync:
            showWaitingForSyncWindow()

        case .unlocked:
            showMainWindow()
        }
    }

    private func showLoadingWindow() {
        let viewController = LoadingViewController()
        let window = NSWindow(contentViewController: viewController)
        window.title = "QuickVault"
        window.center()

        let windowController = NSWindowController(window: window)
        windowController.showWindow(nil)
        self.windowController = windowController
    }

    // ... 其他窗口显示方法
}
```

---

## 关键要点总结

### ✅ 必须做的事

1. **在 App 启动时调用 `checkInitialState()`**
   ```swift
   await authService.checkInitialState()
   ```

2. **订阅 `authenticationStatePublisher`**
   ```swift
   authService.authenticationStatePublisher
       .sink { state in
           // 根据状态更新 UI
       }
   ```

3. **处理所有 5 种状态**
   - `.initializing` - 显示加载界面
   - `.setupRequired` - 显示初始化密码界面
   - `.locked` - 显示登录界面
   - `.waitingForCloudSync` - 显示等待同步界面
   - `.unlocked` - 显示主界面

### ❌ 不要做的事

1. **不要跳过 `checkInitialState()`**
   ```swift
   // ❌ 错误：直接根据初始状态显示界面
   switch authService.authenticationState {
       case .setupRequired: showSetup()
       // ...
   }

   // ✅ 正确：先检查初始状态
   await authService.checkInitialState()
   ```

2. **不要在 init 之后立即访问 state**
   ```swift
   // ❌ 错误：init 之后状态可能是 .initializing
   let authService = AuthenticationServiceImpl(...)
   if authService.authenticationState == .setupRequired {
       // 可能误判
   }

   // ✅ 正确：等待 checkInitialState 完成
   let authService = AuthenticationServiceImpl(...)
   await authService.checkInitialState()
   // 现在状态是准确的
   ```

3. **不要忽略 `.waitingForCloudSync` 状态**
   ```swift
   // ❌ 错误：没有处理等待同步状态
   switch state {
       case .setupRequired, .locked: // 合并处理
           showLoginOrSetup()
   }

   // ✅ 正确：分别处理
   switch state {
       case .setupRequired: showSetup()
       case .locked: showLogin()
       case .waitingForCloudSync: showWaitingScreen()
   }
   ```

---

## 调试日志示例

### 首台设备（正常流程）

```
🔐 [AuthService] ========== AuthenticationService INIT ==========
📊 [AuthService] hasPassword: false, hasSalt: false
🔍 [AuthService] No local credentials found
⏳ [AuthService] Setting state to .initializing
✅ [AuthService] ========== AuthenticationService INIT COMPLETE ==========

🔍 [AuthService] ========== checkInitialState START ==========
☁️ [AuthService] Checking for existing data in iCloud CloudKit...
📊 [AuthService] hasCloudData: false
🆕 [AuthService] FIRST DEVICE SCENARIO: No existing data in CloudKit
📝 [AuthService] Setting state to .setupRequired
✅ [AuthService] ========== checkInitialState COMPLETE ==========
```

### 第二台设备（Salt 已同步）

```
🔐 [AuthService] ========== AuthenticationService INIT ==========
📊 [AuthService] hasPassword: false, hasSalt: true
⚠️ [AuthService] Salt exists but password missing (multi-device scenario?)
🔄 [AuthService] Setting state to .locked (will prompt for login)
✅ [AuthService] ========== AuthenticationService INIT COMPLETE ==========
```

### 第二台设备（Salt 未同步）

```
🔐 [AuthService] ========== AuthenticationService INIT ==========
📊 [AuthService] hasPassword: false, hasSalt: false
🔍 [AuthService] No local credentials found
⏳ [AuthService] Setting state to .initializing
✅ [AuthService] ========== AuthenticationService INIT COMPLETE ==========

🔍 [AuthService] ========== checkInitialState START ==========
☁️ [AuthService] Checking for existing data in iCloud CloudKit...
📊 [AuthService] hasCloudData: true
🔍 [AuthService] MULTI-DEVICE SCENARIO: Found existing data in CloudKit
🔑 [AuthService] Checking if salt has synced from iCloud Keychain...
📊 [AuthService] hasSalt: false
⏳ [AuthService] Salt not yet synced from iCloud Keychain
⏱️ [AuthService] Setting state to .waitingForCloudSync
🔄 [AuthService] Starting background task to wait for salt sync...
✅ [AuthService] ========== checkInitialState COMPLETE ==========

⏳ [AuthService] ========== waitForSaltSyncIfNeeded START ==========
⚠️ [AuthService] Salt NOT found locally, waiting for iCloud Keychain sync...
⏱️ [AuthService] Attempt 1/4: Waiting 1 second(s)...
🔍 [AuthService] Checking if salt has synced...
🎉 [AuthService] SUCCESS! Salt received from iCloud Keychain after 2 attempt(s)
✅ [AuthService] ========== waitForSaltSyncIfNeeded SUCCESS ==========
🔓 [AuthService] Updating state to .locked
```

---

## 测试检查清单

测试时请确认以下场景：

- [ ] **首台设备首次启动** → 显示初始化密码界面
- [ ] **首台设备第二次启动** → 显示登录界面
- [ ] **第二台设备（Salt 已同步）** → 直接显示登录界面
- [ ] **第二台设备（Salt 未同步）** → 显示等待界面，然后切换到登录界面
- [ ] **第二台设备（Salt 同步超时）** → 显示等待界面，提供重试按钮
- [ ] **重新安装应用（无 iCloud 恢复）** → 显示初始化密码界面
- [ ] **设置密码但不添加卡片** → 第二次启动显示登录界面（不是初始化）

所有测试都应该在真机上进行，因为 iCloud 同步在模拟器上可能不稳定。
