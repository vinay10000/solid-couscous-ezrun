package com.ezrun.ezrun.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.TypedValue
import android.widget.RemoteViews
import com.ezrun.ezrun.R
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.TimeUnit
import kotlin.math.abs

class DaysCounterWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { appWidgetId ->
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
        WidgetUpdateWorker.schedule(context)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetUpdateWorker.schedule(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        WidgetUpdateWorker.cancel(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        updateAppWidget(context, appWidgetManager, appWidgetId)
    }

    companion object {
        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, DaysCounterWidgetProvider::class.java)
            val widgetIds = appWidgetManager.getAppWidgetIds(component)
            widgetIds.forEach { appWidgetId ->
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val config = DaysCounterWidgetConfig.load(context)
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val layoutId = resolveLayout(options)
            val views = RemoteViews(context.packageName, layoutId)

            // Calculate target date based on mode
            val targetDate = if (config.useGoalDaysMode) {
                val today = Calendar.getInstance().apply {
                    set(Calendar.HOUR_OF_DAY, 12)
                    set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }
                today.add(Calendar.DAY_OF_YEAR, config.goalDays)
                val formatter = SimpleDateFormat("yyyy-MM-dd", Locale.US)
                formatter.format(today.time)
            } else {
                config.goalDate
            }
            
            val dayCount = abs(calculateDays(targetDate))
            val title = if (config.title.isBlank()) "DAYS" else config.title
            val subtitle = if (config.subtitle.isBlank()) "Your next goal" else config.subtitle

            val daysDisplay = if (config.useGoalDaysMode) {
                "$dayCount / ${config.goalDays} days"
            } else {
                dayCount.toString()
            }

            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_days_count, daysDisplay)
            views.setTextViewText(R.id.widget_subtitle, subtitle)
            views.setImageViewResource(R.id.widget_icon, R.mipmap.launcher_icon)

            val background = resolveBackground(config.themeColor)
            views.setInt(R.id.widget_root, "setBackgroundResource", background)

            val textSizes = resolveTextSizes(config.textSize)
            views.setTextViewTextSize(
                R.id.widget_days_count,
                TypedValue.COMPLEX_UNIT_SP,
                textSizes.days,
            )
            views.setTextViewTextSize(
                R.id.widget_title,
                TypedValue.COMPLEX_UNIT_SP,
                textSizes.title,
            )
            views.setTextViewTextSize(
                R.id.widget_subtitle,
                TypedValue.COMPLEX_UNIT_SP,
                textSizes.subtitle,
            )

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    appWidgetId,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun calculateDays(goalDate: String): Long {
            val formatter = SimpleDateFormat("yyyy-MM-dd", Locale.US)
            formatter.timeZone = TimeZone.getDefault()
            val targetDate = formatter.parse(goalDate) ?: return 0

            val today = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 12)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }

            val target = Calendar.getInstance().apply {
                time = targetDate
                set(Calendar.HOUR_OF_DAY, 12)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }

            val diffMillis = target.timeInMillis - today.timeInMillis
            return TimeUnit.MILLISECONDS.toDays(diffMillis)
        }

        private fun resolveLayout(options: Bundle?): Int {
            val minWidth = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) ?: 0
            val minHeight = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT) ?: 0
            return when {
                minWidth < 120 || minHeight < 120 -> R.layout.widget_days_counter_small
                minWidth >= 250 -> R.layout.widget_days_counter_large
                else -> R.layout.widget_days_counter
            }
        }

        private fun resolveBackground(theme: String): Int {
            return when (theme) {
                "purple" -> R.drawable.widget_background_gradient_purple
                "green" -> R.drawable.widget_background_gradient_green
                "orange" -> R.drawable.widget_background_gradient_orange
                "pink" -> R.drawable.widget_background_gradient_pink
                "cyan" -> R.drawable.widget_background_gradient_cyan
                else -> R.drawable.widget_background_gradient_blue
            }
        }

        private fun resolveTextSizes(textSize: String): TextSizes {
            return when (textSize) {
                "small" -> TextSizes(days = 34f, title = 12f, subtitle = 11f)
                "large" -> TextSizes(days = 56f, title = 16f, subtitle = 14f)
                else -> TextSizes(days = 44f, title = 14f, subtitle = 12f)
            }
        }
    }
}

private data class TextSizes(
    val days: Float,
    val title: Float,
    val subtitle: Float,
)
