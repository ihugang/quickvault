package com.quickvault.util.extensions

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper

/**
 * Context 扩展函数
 */

/**
 * 从 Context 中查找 Activity
 * 递归遍历 ContextWrapper 链，直到找到 Activity
 */
fun Context.findActivity(): Activity? {
    var context = this
    while (context is ContextWrapper) {
        if (context is Activity) return context
        context = context.baseContext
    }
    return null
}
