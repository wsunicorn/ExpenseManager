package com.nnlan.so_thu_chi

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Mở các trang cài đặt hệ thống liên quan tới việc giữ app chạy nền.
 *
 * Đặc tả: `ke-hoach-app/01_DAC_TA_TINH_NANG.md` mục H.2 — MIUI giết tiến trình
 * nền rất mạnh, nên app phải có nút đưa người dùng thẳng tới trang bật
 * "Tự khởi động" và "Không giới hạn pin".
 *
 * Viết bằng MethodChannel thay vì thêm một package như `app_settings`: chỉ cần
 * ba intent, và intent tự khởi động của MIUI vốn không nằm trong package nào —
 * phải tự gọi tên component của Xiaomi.
 */
class MainActivity : FlutterActivity() {

    private val channelName = "sothuchi/system_settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openAppSettings" -> result.success(openAppSettings())
                "openBatterySettings" -> result.success(openBatterySettings())
                "openAutoStartSettings" -> result.success(openAutoStartSettings())
                "isMiui" -> result.success(isMiui())
                else -> result.notImplemented()
            }
        }
    }

    /** Trang thông tin app — luôn tồn tại trên mọi máy Android. */
    private fun openAppSettings(): Boolean = tryStart(
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", packageName, null)
        }
    )

    /**
     * Trang tối ưu hoá pin. Trên máy không có trang riêng thì lùi về trang
     * thông tin app, nơi vẫn vào được mục pin.
     */
    private fun openBatterySettings(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (tryStart(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))) {
                return true
            }
        }
        return openAppSettings()
    }

    /**
     * Trang "Tự khởi động" của MIUI.
     *
     * Không có API chuẩn cho việc này — phải gọi thẳng tên component của
     * Xiaomi. Tên đó có thể đổi giữa các bản MIUI, nên luôn có đường lùi về
     * trang thông tin app thay vì để app văng.
     */
    private fun openAutoStartSettings(): Boolean {
        val ungVien = listOf(
            // MIUI / HyperOS
            ComponentName(
                "com.miui.securitycenter",
                "com.miui.permcenter.autostart.AutoStartManagementActivity"
            ),
            // ColorOS (Oppo)
            ComponentName(
                "com.coloros.safecenter",
                "com.coloros.safecenter.permission.startup.StartupAppListActivity"
            ),
            // Realme UI
            ComponentName(
                "com.coloros.safecenter",
                "com.coloros.safecenter.startupapp.StartupAppListActivity"
            ),
            // Funtouch OS (Vivo)
            ComponentName(
                "com.vivo.permissionmanager",
                "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"
            ),
            // Huawei
            ComponentName(
                "com.huawei.systemmanager",
                "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
            )
        )

        for (component in ungVien) {
            if (tryStart(Intent().setComponent(component))) return true
        }
        return openAppSettings()
    }

    private fun isMiui(): Boolean =
        Build.MANUFACTURER.equals("Xiaomi", ignoreCase = true) ||
            Build.MANUFACTURER.equals("Redmi", ignoreCase = true) ||
            Build.MANUFACTURER.equals("POCO", ignoreCase = true)

    /**
     * Mở một intent, trả về false nếu máy không có Activity nào nhận.
     *
     * Bắt Exception rộng là cố ý: các ROM tuỳ biến ném đủ loại lỗi khác nhau
     * khi component không tồn tại, và không đáng để app văng chỉ vì không mở
     * được một trang cài đặt.
     */
    private fun tryStart(intent: Intent): Boolean = try {
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        true
    } catch (e: Exception) {
        false
    }
}
