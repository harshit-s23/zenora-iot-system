package com.zenora.app

import android.content.Intent
import android.net.Uri
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "zenora/emergency"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "makeCall") {
                    val number = call.argument<String>("number") ?: ""
                    makeDirectCall(number, result)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun makeDirectCall(number: String, result: MethodChannel.Result) {
        android.util.Log.d("ZenoraCall", "makeDirectCall triggered for: $number")

        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE)
            == PackageManager.PERMISSION_GRANTED
        ) {
            android.util.Log.d("ZenoraCall", "Permission granted — placing call")
            val intent = Intent(Intent.ACTION_CALL)
            intent.data = Uri.parse("tel:$number")
            startActivity(intent)
            result.success(true)
        } else {
            android.util.Log.d("ZenoraCall", "Permission NOT granted — requesting")
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.CALL_PHONE),
                101
            )
            result.success(false)
        }
    }
}