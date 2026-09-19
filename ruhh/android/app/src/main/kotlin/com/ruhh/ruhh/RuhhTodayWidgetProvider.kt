package com.ruhh.ruhh

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject

class RuhhTodayWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
        val summaryRaw = prefs.getString("summary", "{}") ?: "{}"
        var label = "Open app to sync"
        try {
            val json = JSONObject(summaryRaw)
            label = json.optString("label", label)
        } catch (_: Exception) {
        }

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.ruhh_today_widget)
            views.setTextViewText(R.id.widget_summary, label)
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
