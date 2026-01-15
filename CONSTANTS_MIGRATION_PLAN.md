# 常量迁移计划 / Constants Migration Plan

## 状态 / Status

- 创建日期: 2026-01-15
- 当前状态: 🟡 进行中 / In Progress
- 完成度: 15%

## 已完成 / Completed ✅

### 1. 基础设施 / Infrastructure

- [x] 创建 `AppConstants.swift` - 应用常量定义
- [x] 创建 `LocalizationKeys.swift` - 本地化键定义
- [x] 创建 `CONSTANTS_GUIDE.md` - 使用指南文档
- [x] 创建 `find_hardcoded_strings.sh` - 硬编码字符串查找工具
- [x] 添加 `String` 扩展 - 便捷的本地化方法

### 2. 核心服务迁移 / Core Services Migration

- [x] `AuthenticationService.swift`
  - Logger subsystem
  - Error localization keys
  - UserDefaults key for language

- [x] `AutoLockManager.swift`
  - UserDefaults key
  - Auto-lock timeout constants
  - Brief switch threshold

- [x] `ItemType.swift`
  - Localization keys
  - System icon names

## 进行中 / In Progress 🟡

### 3. View Models 迁移 / View Models Migration

- [ ] `SettingsViewModel.swift`
  - UserDefaults keys
  - Notification names
  - Auto-lock timeout values

### 4. Views 迁移 / Views Migration

#### Items Views
- [ ] `ItemListView.swift`
  - Localization keys
  - System icon names
  
- [ ] `ItemDetailView.swift`
  - Localization keys
  - System icons
  
- [ ] `CreateItemSheet.swift`
  - Localization keys
  - System icons
  
- [ ] `EditItemSheet.swift`
  - Localization keys

#### Settings Views
- [ ] `SettingsView.swift`
  - Localization keys
  - App URLs (PhotoPC, FoxVault)
  
#### Auth Views
- [ ] `WelcomeView.swift`
  - Localization keys
  
- [ ] `LockScreenView.swift`
  - Localization keys
  - System icons

### 5. Services 迁移 / Services Migration

- [ ] `LocalizationManager.swift`
  - UserDefaults key
  
- [ ] `CryptoService.swift`
  - Logger subsystem
  - Crypto constants (iterations, key sizes)
  
- [ ] `ItemService.swift`
  - Logger subsystem
  - Validation constants
  - CoreData entity names
  
- [ ] `FileStorageManager.swift`
  - File path helpers

## 待办 / To Do 📋

### 6. 测试文件 / Test Files

- [ ] `AuthenticationServiceTests.swift`
  - Keychain keys
  - UserDefaults keys
  
- [ ] `QuickVaultCoreTests` 其他测试文件

### 7. macOS App 迁移

- [ ] `QuickVault-macOS` 目录下所有文件
  - Views
  - Services
  - View Models

### 8. 旧代码清理 / Legacy Code Cleanup

- [ ] `QuickVault-iOS/Old/` 目录
- [ ] `QuickHold-iOS-App/` 目录（如果仍在使用）

## 迁移优先级 / Migration Priority

### 高优先级 / High Priority 🔴

1. **核心服务** - 已完成
   - AuthenticationService ✅
   - CryptoService
   - ItemService

2. **主要视图** - 进行中
   - ItemListView
   - ItemDetailView
   - SettingsView

3. **View Models**
   - SettingsViewModel
   - ItemListViewModel

### 中优先级 / Medium Priority 🟡

1. **辅助服务**
   - LocalizationManager
   - FileStorageManager
   - AutoLockManager ✅

2. **次要视图**
   - WelcomeView
   - LockScreenView
   - CreateItemSheet

### 低优先级 / Low Priority 🟢

1. **测试文件**
2. **工具类**
3. **示例代码**

## 迁移检查清单 / Migration Checklist

每个文件迁移时需要检查以下项目：

### 代码审查 / Code Review

- [ ] 所有硬编码字符串已识别
- [ ] UserDefaults 键已迁移到 `AppConstants.UserDefaultsKeys`
- [ ] 本地化键已迁移到 `LocalizationKeys`
- [ ] SF Symbols 图标名已迁移到 `AppConstants.SystemIcon`
- [ ] Logger 子系统已迁移到 `AppConstants.Logger`
- [ ] 通知名称已迁移到 `AppConstants.Notification`
- [ ] 魔法数字已迁移到相应常量

### 测试 / Testing

- [ ] 编译通过（无错误和警告）
- [ ] 单元测试通过
- [ ] UI 测试通过（如适用）
- [ ] 功能验证完成

### 文档 / Documentation

- [ ] 代码注释更新
- [ ] 迁移日志更新
- [ ] 如有新常量，已添加到常量文件

## 使用工具 / Tools Usage

### 查找硬编码字符串

```bash
cd /Volumes/SN770/Downloads/Dev/2026/Products/QuickVault
./scripts/find_hardcoded_strings.sh
```

### 批量替换示例

使用 `sed` 或 IDE 的查找替换功能：

```bash
# 示例：替换 UserDefaults 键
find src/QuickVault-iOS-App -name "*.swift" -exec sed -i '' \
  's/"app_language"/AppConstants.UserDefaultsKeys.appLanguage/g' {} \;
```

## 注意事项 / Important Notes

### ⚠️ 迁移时需要注意

1. **测试覆盖** - 每次迁移后运行测试
2. **git commit** - 每个文件或模块迁移后及时提交
3. **向后兼容** - 确保不破坏现有功能
4. **文档同步** - 更新相关文档

### 💡 最佳实践

1. **小步迁移** - 一次迁移一个文件或模块
2. **代码审查** - 迁移后进行代码审查
3. **逐步测试** - 不要积累太多未测试的变更
4. **保持一致** - 遵循既定的命名规范

## 进度追踪 / Progress Tracking

### 按模块统计 / By Module

| 模块 / Module | 文件数 / Files | 已完成 / Done | 进度 / Progress |
|--------------|----------------|---------------|-----------------|
| Constants    | 2              | 2             | 100% ✅         |
| Core Services| 5              | 2             | 40% 🟡          |
| View Models  | 3              | 0             | 0% 📋           |
| Views        | 8              | 0             | 0% 📋           |
| Tests        | 5              | 0             | 0% 📋           |
| **总计 / Total** | **23**     | **4**         | **17%**         |

### 按类型统计 / By Type

| 类型 / Type              | 估计数量 / Est. | 已迁移 / Migrated | 完成率 / Rate |
|-------------------------|----------------|-------------------|---------------|
| UserDefaults Keys       | 10             | 2                 | 20%           |
| Localization Keys       | 150+           | 8                 | 5%            |
| System Icons            | 30+            | 3                 | 10%           |
| Logger Subsystems       | 6              | 1                 | 17%           |
| Notification Names      | 7              | 0                 | 0%            |
| Magic Numbers           | 15+            | 5                 | 33%           |

## 下一步行动 / Next Actions

### 本周计划 / This Week

1. 完成 `SettingsViewModel.swift` 迁移
2. 完成 `ItemListView.swift` 迁移
3. 完成 `ItemDetailView.swift` 迁移
4. 运行查找脚本，更新统计数据

### 下周计划 / Next Week

1. 完成所有 Items 相关视图迁移
2. 完成 Settings 相关视图迁移
3. 开始 Services 迁移
4. 更新测试用例

### 月度目标 / Monthly Goal

- 完成所有 iOS App 核心代码迁移（90%+）
- 完成核心测试文件迁移
- 开始 macOS App 迁移规划

## 参考资源 / References

- [CONSTANTS_GUIDE.md](../CONSTANTS_GUIDE.md) - 常量使用指南
- [AppConstants.swift](../src/QuickVaultKit/Sources/QuickVaultCore/Constants/AppConstants.swift)
- [LocalizationKeys.swift](../src/QuickVaultKit/Sources/QuickVaultCore/Constants/LocalizationKeys.swift)

## 更新日志 / Changelog

### 2026-01-15
- ✅ 创建常量管理基础设施
- ✅ 迁移 `AuthenticationService.swift`
- ✅ 迁移 `AutoLockManager.swift`
- ✅ 迁移 `ItemType.swift`
- 📝 创建迁移计划文档
- 🔧 创建查找工具脚本

---

**负责人 / Owner**: AI Assistant  
**审核人 / Reviewer**: TBD  
**截止日期 / Deadline**: 2026-02-15
