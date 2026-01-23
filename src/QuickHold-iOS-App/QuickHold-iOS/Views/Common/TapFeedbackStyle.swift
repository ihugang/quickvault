//
//  TapFeedbackStyle.swift
//  QuickHold
//
//  Unified tap feedback styles for consistent micro-interactions
//  统一的点击反馈样式，提供一致的微交互
//

import SwiftUI

// MARK: - Card Tap Feedback Style

/// Button style with subtle scale feedback for card-like elements
/// 为卡片类元素提供轻微缩放反馈的按钮样式
struct CardTapFeedbackStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.97
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Pill Tap Feedback Style

/// Button style with subtle scale feedback for pill-shaped elements (tags, filters)
/// 为胶囊形元素（标签、筛选器）提供轻微缩放反馈的按钮样式
struct PillTapFeedbackStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.95
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Icon Button Tap Feedback Style

/// Button style with subtle scale feedback for icon buttons
/// 为图标按钮提供轻微缩放反馈的按钮样式
struct IconButtonTapFeedbackStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.90
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Primary Action Tap Feedback Style

/// Button style with subtle scale and brightness feedback for primary action buttons
/// 为主要操作按钮提供轻微缩放和亮度反馈的按钮样式
struct PrimaryActionTapFeedbackStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.96
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply card tap feedback style
    /// 应用卡片点击反馈样式
    func cardTapFeedback(scaleAmount: CGFloat = 0.97) -> some View {
        buttonStyle(CardTapFeedbackStyle(scaleAmount: scaleAmount))
    }
    
    /// Apply pill tap feedback style
    /// 应用胶囊点击反馈样式
    func pillTapFeedback(scaleAmount: CGFloat = 0.95) -> some View {
        buttonStyle(PillTapFeedbackStyle(scaleAmount: scaleAmount))
    }
    
    /// Apply icon button tap feedback style
    /// 应用图标按钮点击反馈样式
    func iconButtonTapFeedback(scaleAmount: CGFloat = 0.90) -> some View {
        buttonStyle(IconButtonTapFeedbackStyle(scaleAmount: scaleAmount))
    }
    
    /// Apply primary action tap feedback style
    /// 应用主要操作按钮点击反馈样式
    func primaryActionTapFeedback(scaleAmount: CGFloat = 0.96) -> some View {
        buttonStyle(PrimaryActionTapFeedbackStyle(scaleAmount: scaleAmount))
    }
}

// MARK: - Animation Constants

/// Animation constants for consistent micro-interactions
/// 动画常量，用于保持微交互的一致性
enum AnimationConstants {
    /// Spring animation for quick interactions (buttons, toggles)
    /// 快速交互的弹簧动画（按钮、开关）
    static let quickSpring = Animation.spring(response: 0.25, dampingFraction: 0.7)
    
    /// Spring animation for smooth transitions (sheets, overlays)
    /// 平滑过渡的弹簧动画（表单、浮层）
    static let smoothSpring = Animation.spring(response: 0.35, dampingFraction: 0.8)
    
    /// Ease-in-out animation for state changes
    /// 状态变化的缓入缓出动画
    static let stateChange = Animation.easeInOut(duration: 0.25)
    
    /// Opacity transition for overlays
    /// 浮层的不透明度过渡
    static let opacityTransition: AnyTransition = .opacity
    
    /// Move and opacity combined transition for sheets
    /// 表单的移动和不透明度组合过渡
    static let sheetTransition: AnyTransition = .move(edge: .bottom).combined(with: .opacity)
}
