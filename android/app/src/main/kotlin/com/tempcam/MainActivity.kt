package com.tempcam

import android.content.ContentValues
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val MEDIA_GALLERY_CHANNEL = "tempcam/media_gallery"
        private const val SYSTEM_CHANNEL = "tempcam/system"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MEDIA_GALLERY_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
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
