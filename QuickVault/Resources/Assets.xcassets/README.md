# Icon Assets / 图标资源

## Required Icons / 所需图标

### App Icon (AppIcon.appiconset)

应用程序图标，用于 Dock 和 Finder。

Required sizes / 所需尺寸:

-   16x16 (1x and 2x)
-   32x32 (1x and 2x)
-   128x128 (1x and 2x)
-   256x256 (1x and 2x)
-   512x512 (1x and 2x)

### Menu Bar Icon (MenuBarIcon.imageset)

菜单栏图标（解锁状态）

-   Should be a simple, monochrome icon / 应该是简单的单色图标
-   Recommended size: 18x18 points / 推荐尺寸：18x18 点
-   Template rendering for automatic dark/light mode / 模板渲染以自动适配深色/浅色模式

### Menu Bar Icon Locked (MenuBarIconLocked.imageset)

菜单栏图标（锁定状态）

-   Similar to MenuBarIcon but with a lock indicator / 类似于 MenuBarIcon 但带有锁定指示器
-   Recommended size: 18x18 points / 推荐尺寸：18x18 点

## How to Add Icons / 如何添加图标

1. Export your icon from the design file (Icon.psd) / 从设计文件导出图标 (Icon.psd)
2. Generate all required sizes / 生成所有所需尺寸
3. Place the files in the corresponding .imageset or .appiconset folders / 将文件放入相应的 .imageset 或 .appiconset 文件夹
4. Ensure filenames match those in Contents.json / 确保文件名与 Contents.json 中的匹配

## Using SF Symbols (Alternative) / 使用 SF Symbols（替代方案)

For menu bar icons, you can also use SF Symbols:
对于菜单栏图标，您也可以使用 SF Symbols：

```swift
// Unlocked icon
NSImage(systemSymbolName: "lock.open.fill", accessibilityDescription: "Unlocked")

// Locked icon
NSImage(systemSymbolName: "lock.fill", accessibilityDescription: "Locked")
```

## Current Status / 当前状态

⚠️ Placeholder icons are currently used. Replace with actual design assets.
⚠️ 当前使用占位符图标。请替换为实际的设计资源。
