package com.quickvault.util

import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.OpenableColumns

fun readBytesFromUri(context: Context, uri: Uri): ByteArray? {
    return context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
}

fun getFileName(context: Context, uri: Uri): String {
    var name = "file"
    val cursor: Cursor? = context.contentResolver.query(uri, null, null, null, null)
    cursor?.use {
        val nameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
        if (nameIndex != -1 && it.moveToFirst()) {
            name = it.getString(nameIndex)
        }
    }
    return name
}

fun getMimeType(context: Context, uri: Uri): String {
    return context.contentResolver.getType(uri) ?: "application/octet-stream"
}
