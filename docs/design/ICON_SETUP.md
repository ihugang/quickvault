# Icon Setup Guide / 图标设置指南

## Current Status / 当前状态

✅ Icon asset structure created / 图标资源结构已创建
✅ IconProvider utility class created / IconProvider 工具类已创建
✅ SF Symbols fallback implemented / SF Symbols 备用方案已实现

## Icon System / 图标系统

The app uses a flexible icon system that:
应用程序使用灵活的图标系统：

1. **First tries to load custom icons** from Assets.xcassets / 首先尝试从 Assets.xcassets 加载自定义图标
2. **Falls back to SF Symbols** if custom icons are not available / 如果自定义图标不可用，则回退到 SF Symbols
3. **Provides placeholder images** as ultimate fallback / 提供占位符图像作为最终备用

## How to Add Your Custom Icons / 如何添加自定义图标

### Step 1: Prepare Icon Files / 步骤 1：准备图标文件

From your `Icon.psd` or `Icon.png` file, export the following:
从您的 `Icon.psd` 或 `Icon.png` 文件导出以下内容：

#### App Icon (for Dock/Finder) / 应用图标（用于 Dock/Finder）

-   icon_16x16.png (16x16)
-   icon_16x16@2x.png (32x32)
-   icon_32x32.png (32x32)
-   icon_32x32@2x.png (64x64)
-   icon_128x128.png (128x128)
-   icon_128x128@2x.png (256x256)
-   icon_256x256.png (256x256)
-   icon_256x256@2x.png (512x512)
-   icon_512x512.png (512x512)
-   icon_512x512@2x.png (1024x1024)

#### Menu Bar Icons / 菜单栏图标

-   menubar_icon.png (18x18) - Unlocked state / 解锁状态
-   menubar_icon@2x.png (36x36)
-   menubar_icon@3x.png (54x54)
-   menubar_icon_locked.png (18x18) - Locked state / 锁定状态
-   menubar_icon_locked@2x.png (36x36)
-   menubar_icon_locked@3x.png (54x54)

### Step 2: Place Files / 步骤 2：放置文件

Copy the files to their respective folders:
将文件复制到各自的文件夹：

```bash
# App Icon
cp icon_*.png QuickVault/Resources/Assets.xcassets/AppIcon.appiconset/

# Menu Bar Icon (Unlocked)
cp menubar_icon*.png QuickVault/Resources/Assets.xcassets/MenuBarIcon.imageset/

# Menu Bar Icon (Locked)
cp menubar_icon_locked*.png QuickVault/Resources/Assets.xcassets/MenuBarIconLocked.imageset/
```

### Step 3: Verify / 步骤 3：验证

Open the project in Xcode and verify that:
在 Xcode 中打开项目并验证：

1. Assets.xcassets shows all icons / Assets.xcassets 显示所有图标
2. No warnings about missing assets / 没有关于缺少资源的警告
3. Icons appear correctly in the app / 图标在应用中正确显示

## Icon Design Guidelines / 图标设计指南

### App Icon / 应用图标

-   **Style**: Modern, minimal, Apple-like / 现代、简约、类似 Apple 风格
-   **Shape**: Square (no rounded corners, macOS adds them) / 正方形（无圆角，macOS 会添加）
-   **Colors**: Single primary color with highlights / 单一主色配高光
-   **No text**: Icons should be recognizable without text / 无文字：图标应该无需文字即可识别

### Menu Bar Icon / 菜单栏图标

-   **Style**: Simple, monochrome line art / 简单的单色线条艺术
-   **Size**: 18x18 points (template rendering) / 18x18 点（模板渲染）
-   **Colors**: Black on transparent (system will adapt) / 透明背景上的黑色（系统会适配）
-   **Locked variant**: Add a small lock indicator / 锁定变体：添加小锁指示器

## Current Fallback Icons / 当前备用图标

The app currently uses SF Symbols as fallbacks:
应用程序当前使用 SF Symbols 作为备用：

-   **Unlocked**: `lock.open.fill`
-   **Locked**: `lock.fill`
-   **Address card**: `location.fill`
-   **Invoice card**: `doc.text.fill`
-   **General card**: `note.text`
-   **Copy**: `doc.on.doc`
-   **Settings**: `gearshape.fill`
-   **Dashboard**: `square.grid.2x2`
-   **Pin**: `pin.fill`
-   **Attachment**: `paperclip`

These work well but custom icons will provide better branding.
这些效果很好，但自定义图标将提供更好的品牌形象。

## Usage in Code / 代码中的使用

```swift
// Get menu bar icon based on lock state
let icon = isLocked ? IconProvider.menuBarLocked : IconProvider.menuBarUnlocked

// Get icon for card type
let cardIcon = IconProvider.cardIcon(for: "address")

// Get action icons
let copyIcon = IconProvider.copyIcon
let settingsIcon = IconProvider.settingsIcon
```

## Tools for Icon Generation / 图标生成工具

Recommended tools for generating icon sizes:
推荐的图标尺寸生成工具：

-   **macOS**: Preview (File > Export with different sizes) / 预览（文件 > 以不同尺寸导出）
-   **Online**: [AppIconGenerator](https://appicon.co/)
-   **CLI**: ImageMagick or sips (built into macOS)

Example using sips:
使用 sips 的示例：

```bash
# Generate 2x version
sips -z 36 36 menubar_icon.png --out menubar_icon@2x.png

# Generate 3x version
sips -z 54 54 menubar_icon.png --out menubar_icon@3x.png
```

## Next Steps / 后续步骤

1. ✅ Icon structure created / 图标结构已创建
2. ⏳ Add actual icon files from design / 从设计中添加实际图标文件
3. ⏳ Test icons in light and dark mode / 在浅色和深色模式下测试图标
4. ⏳ Verify menu bar icon rendering / 验证菜单栏图标渲染
