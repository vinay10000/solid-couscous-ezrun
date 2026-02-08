package com.ezrun.ezrun

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.os.Build
import com.ezrun.ezrun.widgets.DaysCounterWidgetProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.ezrun.ezrun/days_counter_widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateWidget" -> {
                        DaysCounterWidgetProvider.updateAllWidgets(this)
                        result.success(true)
                    }
                    "checkWidgetExists" -> {
                        val manager = AppWidgetManager.getInstance(this)
                        val component = ComponentName(this, DaysCounterWidgetProvider::class.java)
                        val ids = manager.getAppWidgetIds(component)
                        result.success(ids.isNotEmpty())
                    }
                    "requestPinWidget" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val manager = AppWidgetManager.getInstance(this)
                            val component = ComponentName(this, DaysCounterWidgetProvider::class.java)
                            val success = manager.requestPinAppWidget(component, null, null)
                            result.success(success)
                        } else {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
