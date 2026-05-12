package com.example.english_learning_ap

import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "voxly/test_notifications"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			channelName
		).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
			when (call.method) {
				"isNotificationActive" -> {
					val id = call.argument<Int>("id")
					if (id == null) {
						result.error("missing_id", "Expected integer 'id' argument", null)
						return@setMethodCallHandler
					}

					if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
						result.success(false)
						return@setMethodCallHandler
					}

					val manager =
						getSystemService(NOTIFICATION_SERVICE) as NotificationManager
					val active = manager.activeNotifications.any { statusBarNotification ->
						statusBarNotification.id == id
					}
					result.success(active)
				}

				else -> result.notImplemented()
			}
		}
	}
}
