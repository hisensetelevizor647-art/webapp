package com.oleksandrai.app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.DisplayMetrics
import android.util.Log
import android.view.WindowManager
import java.io.File
import java.io.FileOutputStream

/**
 * Transparent activity that requests the one-shot MediaProjection permission,
 * grabs the current screen contents, writes them to the app cache, and
 * returns the file path through [MainActivity.pendingScreenshotResult].
 *
 * Kept deliberately minimal: we take a single frame, tear everything down,
 * and close the activity. No long-lived foreground service.
 */
class ScreenshotActivity : Activity() {

    companion object {
        private const val TAG = "OAScreenshot"
        private const val REQ = 1001
    }

    private lateinit var projectionManager: MediaProjectionManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        projectionManager =
            getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(projectionManager.createScreenCaptureIntent(), REQ)
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQ) {
            finishWith(null)
            return
        }
        if (resultCode != RESULT_OK || data == null) {
            finishWith(null)
            return
        }

        try {
            val projection: MediaProjection =
                projectionManager.getMediaProjection(resultCode, data)

            val metrics = DisplayMetrics()
            (getSystemService(Context.WINDOW_SERVICE) as WindowManager)
                .defaultDisplay.getMetrics(metrics)

            val width = metrics.widthPixels
            val height = metrics.heightPixels
            val density = metrics.densityDpi

            val reader = ImageReader.newInstance(
                width, height, PixelFormat.RGBA_8888, 2
            )

            var virtualDisplay: VirtualDisplay? = null
            virtualDisplay = projection.createVirtualDisplay(
                "oa-screen",
                width, height, density,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                reader.surface, null, null
            )

            // Give the surface one frame to populate.
            Handler(Looper.getMainLooper()).postDelayed({
                try {
                    val image = reader.acquireLatestImage()
                    if (image == null) {
                        finishWith(null)
                        return@postDelayed
                    }
                    val plane = image.planes[0]
                    val buffer = plane.buffer
                    val pixelStride = plane.pixelStride
                    val rowStride = plane.rowStride
                    val rowPadding = rowStride - pixelStride * width
                    val bmp = Bitmap.createBitmap(
                        width + rowPadding / pixelStride,
                        height,
                        Bitmap.Config.ARGB_8888
                    )
                    bmp.copyPixelsFromBuffer(buffer)
                    image.close()

                    val cropped = Bitmap.createBitmap(bmp, 0, 0, width, height)
                    val outFile = File(
                        cacheDir,
                        "oa_screen_${System.currentTimeMillis()}.png"
                    )
                    FileOutputStream(outFile).use { out ->
                        cropped.compress(Bitmap.CompressFormat.PNG, 90, out)
                    }

                    finishWith(outFile.absolutePath)
                } catch (t: Throwable) {
                    Log.e(TAG, "capture failed", t)
                    finishWith(null)
                } finally {
                    try {
                        virtualDisplay?.release()
                    } catch (_: Throwable) {
                    }
                    try {
                        reader.close()
                    } catch (_: Throwable) {
                    }
                    try {
                        projection.stop()
                    } catch (_: Throwable) {
                    }
                }
            }, 250)
        } catch (t: Throwable) {
            Log.e(TAG, "projection error", t)
            finishWith(null)
        }
    }

    private fun finishWith(path: String?) {
        val pending = MainActivity.pendingScreenshotResult
        MainActivity.pendingScreenshotResult = null
        try {
            pending?.success(path)
        } catch (_: Throwable) {
        }
        finish()
    }
}
