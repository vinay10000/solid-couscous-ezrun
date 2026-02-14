package com.ezrun.ezrun.widgets

import android.content.Context
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

data class DaysCounterWidgetConfig(
    val goalDate: String,
    val title: String,
    val subtitle: String,
    val themeColor: String,
    val textSize: String,
    val goalDays: Int,
    val useGoalDaysMode: Boolean,
) {
    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val PREFIX = "flutter."

        private const val KEY_GOAL_DATE = PREFIX + "widget_goal_date"
        private const val KEY_TITLE = PREFIX + "widget_title"
        private const val KEY_SUBTITLE = PREFIX + "widget_subtitle"
        private const val KEY_THEME_COLOR = PREFIX + "widget_theme_color"
        private const val KEY_TEXT_SIZE = PREFIX + "widget_text_size"
        private const val KEY_GOAL_DAYS = PREFIX + "widget_goal_days"
        private const val KEY_USE_GOAL_DAYS_MODE = PREFIX + "widget_use_goal_days_mode"

        fun load(context: Context): DaysCounterWidgetConfig {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            return DaysCounterWidgetConfig(
                goalDate = prefs.getString(KEY_GOAL_DATE, defaultGoalDate()) ?: defaultGoalDate(),
                title = prefs.getString(KEY_TITLE, "DAYS TO") ?: "DAYS TO",
                subtitle = prefs.getString(KEY_SUBTITLE, "Your next goal") ?: "Your next goal",
                themeColor = prefs.getString(KEY_THEME_COLOR, "blue") ?: "blue",
                textSize = prefs.getString(KEY_TEXT_SIZE, "medium") ?: "medium",
                goalDays = prefs.getString(KEY_GOAL_DAYS, "30")?.toIntOrNull() ?: 30,
                useGoalDaysMode = prefs.getString(KEY_USE_GOAL_DAYS_MODE, "false") == "true",
            )
        }

        private fun defaultGoalDate(): String {
            val calendar = Calendar.getInstance()
            val formatter = SimpleDateFormat("yyyy-MM-dd", Locale.US)
            return formatter.format(calendar.time)
        }
    }
}
