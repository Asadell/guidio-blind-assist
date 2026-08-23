package com.pens.vinara

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.atan2

/**
 * Menyediakan intrinsik lensa kamera belakang ke sisi Dart.
 *
 * Estimasi jarak Vinara memakai rumus pinhole: `jarak = tinggi_asli × fokus_px
 * / tinggi_kotak_px`. Selama ini `fokus_px` adalah konstanta 615 - angka
 * rata-rata yang benar untuk *tidak satu pun* perangkat tertentu. Padahal
 * Android sudah menyimpan angka aslinya: panjang fokus dalam milimeter dan
 * ukuran fisik sensor. Dari keduanya, sudut pandang bisa dihitung persis, dan
 * dari sudut pandang itu fokus dalam piksel bisa diturunkan untuk resolusi
 * berapa pun.
 *
 * Ini menggantikan kalibrasi manual dengan meteran di lapangan: tidak ada
 * model baru, tidak ada pengukuran, dan hasilnya benar per-perangkat alih-alih
 * benar rata-rata.
 */
class MainActivity : FlutterActivity() {

    private companion object {
        const val CHANNEL = "vinara/camera_intrinsics"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "lensInfo" -> result.success(readBackLensInfo())
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Sudut pandang kamera belakang, atau null kalau perangkat tidak
     * melaporkannya. Sisi Dart memperlakukan null sebagai "pakai bawaan" -
     * kegagalan di sini tidak boleh mematikan deteksi.
     */
    private fun readBackLensInfo(): Map<String, Any>? {
        return try {
            val manager = getSystemService(Context.CAMERA_SERVICE) as CameraManager

            val backId = manager.cameraIdList.firstOrNull { id ->
                manager.getCameraCharacteristics(id)
                    .get(CameraCharacteristics.LENS_FACING) ==
                    CameraCharacteristics.LENS_FACING_BACK
            } ?: return null

            val chars = manager.getCameraCharacteristics(backId)

            // Beberapa perangkat melaporkan banyak panjang fokus (lensa
            // zoom/ultrawide). Yang dipakai `camera` plugin untuk preview
            // adalah lensa utama, yaitu entri pertama.
            val focalMm = chars
                .get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)
                ?.firstOrNull() ?: return null

            val sensor = chars
                .get(CameraCharacteristics.SENSOR_INFO_PHYSICAL_SIZE) ?: return null

            if (focalMm <= 0f || sensor.width <= 0f || sensor.height <= 0f) return null

            // FOV = 2 · atan(ukuran_sensor / (2 · fokus))
            val hFovRad = 2.0 * atan2(sensor.width.toDouble() / 2.0, focalMm.toDouble())
            val vFovRad = 2.0 * atan2(sensor.height.toDouble() / 2.0, focalMm.toDouble())

            mapOf(
                "focalLengthMm" to focalMm.toDouble(),
                "sensorWidthMm" to sensor.width.toDouble(),
                "sensorHeightMm" to sensor.height.toDouble(),
                "horizontalFovRad" to hFovRad,
                "verticalFovRad" to vFovRad,
            )
        } catch (e: Exception) {
            null
        }
    }
}
