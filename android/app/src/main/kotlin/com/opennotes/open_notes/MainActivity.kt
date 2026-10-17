package com.opennotes.open_notes

import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "opennotes/file")
            .setMethodCallHandler { call, result ->
                if (call.method != "displayName") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                result.success(displayName(call.arguments as String))
            }
    }

    // Name the system reports for a document, also when its URI is opaque.
    private fun displayName(uriString: String): String? {
        return try {
            contentResolver.query(Uri.parse(uriString), arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { cursor ->
                    val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (cursor.moveToFirst() && index >= 0 && !cursor.isNull(index)) cursor.getString(index) else null
                }
        } catch (error: Exception) {
            null
        }
    }
}
