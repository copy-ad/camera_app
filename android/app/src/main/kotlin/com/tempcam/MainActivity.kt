package com.tempcam

import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.util.UUID

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val MEDIA_GALLERY_CHANNEL = "tempcam/media_gallery"
        private const val SYSTEM_CHANNEL = "tempcam/system"
        private const val PICK_IMPORTABLE_MEDIA_REQUEST_CODE = 4107
    }

    private var pendingImportResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MEDIA_GALLERY_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickImportableMedia" -> launchImportableMediaPicker(result)
                "consumeImportedMedia" -> consumeImportedMedia(call, result)
                "saveVideoToGallery" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val displayName = call.argument<String>("displayName")
                        ?: "tempcam_${System.currentTimeMillis()}.mp4"
                    if (sourcePath.isNullOrBlank()) {
                        result.error("bad_args", "sourcePath is required.", null)
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(saveVideoToGallery(sourcePath, displayName))
                    } catch (exception: Exception) {
                        result.error("save_failed", exception.message, null)
                    }
                }
                "saveImageToGallery" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val displayName = call.argument<String>("displayName")
                        ?: "tempcam_${System.currentTimeMillis()}.jpg"
                    if (sourcePath.isNullOrBlank()) {
                        result.error("bad_args", "sourcePath is required.", null)
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(saveImageToGallery(sourcePath, displayName))
                    } catch (exception: Exception) {
                        result.error("save_failed", exception.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SYSTEM_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openExternalUrl" -> {
                    val url = call.argument<String>("url")
                    if (url.isNullOrBlank()) {
                        result.error("bad_args", "url is required.", null)
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(openExternalUrl(url))
                    } catch (exception: Exception) {
                        result.error("open_failed", exception.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != PICK_IMPORTABLE_MEDIA_REQUEST_CODE) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }

        val result = pendingImportResult
        pendingImportResult = null
        if (result == null) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }

        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(emptyList<Map<String, Any?>>())
            return
        }

        try {
            val persistedFlags = data.flags and
                (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            val pickedItems = mutableListOf<Map<String, Any?>>()
            for (uri in extractUris(data)) {
                if (persistedFlags != 0) {
                    try {
                        contentResolver.takePersistableUriPermission(uri, persistedFlags)
                    } catch (_: SecurityException) {
                        // Some providers do not grant persistable permissions. We can still
                        // import the temporary copy and attempt deletion later when possible.
                    }
                }
                pickedItems.add(createImportedMediaPayload(uri))
            }
            result.success(pickedItems)
        } catch (exception: Exception) {
            result.error("pick_failed", exception.message, null)
        }
    }

    private fun launchImportableMediaPicker(result: MethodChannel.Result) {
        if (pendingImportResult != null) {
            result.error("picker_active", "Another media import is already in progress.", null)
            return
        }

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/*", "video/*"))
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }

        pendingImportResult = result
        try {
            startActivityForResult(intent, PICK_IMPORTABLE_MEDIA_REQUEST_CODE)
        } catch (exception: Exception) {
            pendingImportResult = null
            result.error("picker_unavailable", exception.message, null)
        }
    }

    private fun consumeImportedMedia(call: MethodCall, result: MethodChannel.Result) {
        val rawItems = call.argument<List<*>>("items") ?: emptyList<Any>()
        var failedOriginalDeletes = 0

        for (rawItem in rawItems) {
            val item = rawItem as? Map<*, *> ?: continue
            val sourceHandle = item["sourceHandle"]?.toString()
            val tempPath = item["tempPath"]?.toString()

            if (!sourceHandle.isNullOrBlank()) {
                val deleted = deleteOriginalFromHandle(sourceHandle)
                if (!deleted) {
                    failedOriginalDeletes += 1
                }
                releasePersistedPermission(sourceHandle)
            }

            if (!tempPath.isNullOrBlank()) {
                deleteTempFile(tempPath)
            }
        }

        result.success(
            mapOf(
                "failedOriginalDeletes" to failedOriginalDeletes,
            ),
        )
    }

    private fun extractUris(data: Intent): List<Uri> {
        val uris = mutableListOf<Uri>()
        val clipData = data.clipData
        if (clipData != null) {
            for (index in 0 until clipData.itemCount) {
                clipData.getItemAt(index).uri?.let(uris::add)
            }
        } else {
            data.data?.let(uris::add)
        }
        return uris.distinctBy { it.toString() }
    }

    private fun createImportedMediaPayload(uri: Uri): Map<String, Any?> {
        val tempPath = copyUriToCache(uri)
        return mapOf(
            "tempPath" to tempPath,
            "sourceHandle" to uri.toString(),
            "mediaType" to inferMediaType(uri),
        )
    }

    private fun copyUriToCache(uri: Uri): String {
        val fileName = fileNameForUri(uri)
        val targetDir = File(cacheDir, "imported_media/${UUID.randomUUID()}").apply {
            mkdirs()
        }
        val targetFile = File(targetDir, fileName)
        contentResolver.openInputStream(uri)?.use { input ->
            FileOutputStream(targetFile).use { output ->
                input.copyTo(output)
            }
        } ?: error("Unable to read the selected media.")
        return targetFile.absolutePath
    }

    private fun fileNameForUri(uri: Uri): String {
        val displayName = queryDisplayName(uri)
        if (!displayName.isNullOrBlank()) {
            return displayName
        }

        val extension = extensionForUri(uri)
        val suffix = if (extension.isNullOrBlank()) "" else ".$extension"
        return "tempcam_import_${System.currentTimeMillis()}$suffix"
    }

    private fun queryDisplayName(uri: Uri): String? {
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val columnIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (columnIndex >= 0) {
                    return cursor.getString(columnIndex)
                }
            }
        }
        return null
    }

    private fun extensionForUri(uri: Uri): String? {
        val mimeType = contentResolver.getType(uri) ?: return null
        return MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType)
    }

    private fun inferMediaType(uri: Uri): String {
        val mimeType = contentResolver.getType(uri)
        if (mimeType?.startsWith("video/") == true) {
            return "video"
        }
        return "photo"
    }

    private fun deleteOriginalFromHandle(handle: String): Boolean {
        val uri = Uri.parse(handle)
        return try {
            if (DocumentsContract.isDocumentUri(this, uri)) {
                DocumentsContract.deleteDocument(contentResolver, uri)
            } else {
                contentResolver.delete(uri, null, null) > 0
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun releasePersistedPermission(handle: String) {
        val uri = Uri.parse(handle)
        try {
            contentResolver.releasePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
        } catch (_: Exception) {
            // The provider may not have granted persistable access.
        }
    }

    private fun deleteTempFile(path: String) {
        try {
            val file = File(path)
            if (file.exists()) {
                file.delete()
            }
            file.parentFile?.delete()
        } catch (_: Exception) {
            // Temp cleanup is best-effort only.
        }
    }

    private fun openExternalUrl(url: String): Boolean {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
            addCategory(Intent.CATEGORY_BROWSABLE)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
        return true
    }

    private fun saveVideoToGallery(sourcePath: String, displayName: String): String {
        val sourceFile = File(sourcePath)
        require(sourceFile.exists()) { "Recorded video file was not found." }
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.Video.Media.DISPLAY_NAME, displayName)
                put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
                put(MediaStore.Video.Media.RELATIVE_PATH, Environment.DIRECTORY_DCIM + "/TempCam")
                put(MediaStore.Video.Media.IS_PENDING, 1)
            }
            val uri = resolver.insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values)
                ?: error("Unable to create the gallery video entry.")
            resolver.openOutputStream(uri)?.use { outputStream ->
                FileInputStream(sourceFile).use { inputStream ->
                    inputStream.copyTo(outputStream)
                }
            } ?: error("Unable to open the gallery output stream.")
            values.clear()
            values.put(MediaStore.Video.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            uri.toString()
        } else {
            val dcimDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM)
            val targetDir = File(dcimDir, "TempCam").apply {
                if (!exists()) {
                    mkdirs()
                }
            }
            val targetFile = File(targetDir, displayName)
            FileInputStream(sourceFile).use { inputStream ->
                FileOutputStream(targetFile).use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
            }
            MediaScannerConnection.scanFile(this, arrayOf(targetFile.absolutePath), arrayOf("video/mp4"), null)
            targetFile.absolutePath
        }
    }

    private fun saveImageToGallery(sourcePath: String, displayName: String): String {
        val sourceFile = File(sourcePath)
        require(sourceFile.exists()) { "Image file was not found." }
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, displayName)
                put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_DCIM + "/TempCam")
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                ?: error("Unable to create the gallery image entry.")
            resolver.openOutputStream(uri)?.use { outputStream ->
                FileInputStream(sourceFile).use { inputStream ->
                    inputStream.copyTo(outputStream)
                }
            } ?: error("Unable to open the gallery output stream.")
            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            uri.toString()
        } else {
            val dcimDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM)
            val targetDir = File(dcimDir, "TempCam").apply {
                if (!exists()) {
                    mkdirs()
                }
            }
            val targetFile = File(targetDir, displayName)
            FileInputStream(sourceFile).use { inputStream ->
                FileOutputStream(targetFile).use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
            }
            MediaScannerConnection.scanFile(this, arrayOf(targetFile.absolutePath), arrayOf("image/jpeg"), null)
            targetFile.absolutePath
        }
    }
}
