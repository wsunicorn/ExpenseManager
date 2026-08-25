package com.nnlan.so_thu_chi

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import android.content.SharedPreferences

/**
 * Widget màn hình chính. Đặc tả: `ke-hoach-app/01_DAC_TA_TINH_NANG.md` mục I.
 *
 * Dữ liệu không được đọc thẳng từ SQLite ở đây — tiến trình widget chạy tách
 * biệt với app và không nên mở database. Thay vào đó phía Dart ghi vài con số
 * đã tính sẵn vào SharedPreferences dùng chung (qua `home_widget`), còn lớp
 * này chỉ đọc ra và vẽ.
 *
 * Đổi lại: widget hiển thị số của lần cập nhật gần nhất, không phải số theo
 * thời gian thực. Với một widget xem nhanh thì đó là đánh đổi đúng.
 */
class BalanceWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_balance).apply {
                setTextViewText(
                    R.id.widget_total_balance,
                    widgetData.getString("total_balance", "—") ?: "—"
                )
                setTextViewText(
                    R.id.widget_today_expense,
                    widgetData.getString("today_expense", "—") ?: "—"
                )
                setTextViewText(
                    R.id.widget_month_summary,
                    widgetData.getString("month_summary", "") ?: ""
                )

                // Chạm vào widget mở app. Deep link đưa thẳng vào tab Nhập vào.
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("sothuchi://nhap-vao")
                    )
                )

                // Nút nhập nhanh — mở thẳng màn hình nhập.
                setOnClickPendingIntent(
                    R.id.widget_quick_add,
                    HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("sothuchi://nhap-vao?nhanh=1")
                    )
                )
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
