package com.oleksandrai.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Renders the pinned-widget summary the user curates inside the Flutter app
 * ("WidgetRegistryService"). Values are written via the `home_widget`
 * package using the keys `oa_pinned_count` and `oa_pinned_titles`.
 *
 * Tapping the widget opens the app.
 */
class AiWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val count = widgetData.getString("oa_pinned_count", "0") ?: "0"
        val titles = widgetData.getString("oa_pinned_titles", "") ?: ""

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.ai_widget)
            views.setTextViewText(R.id.oa_title, "OleksandrAi")
            views.setTextViewText(
                R.id.oa_subtitle,
                if (titles.isBlank()) "Tap to open assistant"
                else "$count pinned: $titles"
            )

            val launch = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                    PendingIntent.FLAG_IMMUTABLE
            val pi = PendingIntent.getActivity(context, 0, launch, flags)
            views.setOnClickPendingIntent(R.id.oa_root, pi)

            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
