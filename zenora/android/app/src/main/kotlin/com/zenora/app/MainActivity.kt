package com.zenora.app

import android.content.Intent
import android.net.Uri
import android.Manifest
import android.content.pm.PackageManager
import android.telephony.SmsManager
import android.os.Build
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "zenora/emergency"
    private val REQ_CALL = 101
    private val REQ_SMS  = 102

    // Held while we wait for the user to grant CALL_PHONE permission
    private var pendingCallNumber: String = ""
    private var pendingCallResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "makeCall" -> {
                        val number = call.argument<String>("number") ?: ""
                        makeDirectCall(number, result)
                    }
                    "sendSms" -> {
                        val number  = call.argument<String>("number")  ?: ""
                        val message = call.argument<String>("message") ?: ""
                        sendDirectSms(number, message, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ── Direct call ─────────────────────────────────────────────────────────
    private fun makeDirectCall(number: String, result: MethodChannel.Result) {
        android.util.Log.d("ZenoraCall", "makeDirectCall → $number")

        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE)
            == PackageManager.PERMISSION_GRANTED
        ) {
            placeCall(number, result)
        } else {
            // Store everything; we'll complete the call in onRequestPermissionsResult
            pendingCallNumber = number
            pendingCallResult = result
            android.util.Log.d("ZenoraCall", "Requesting CALL_PHONE permission…")
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.CALL_PHONE),
                REQ_CALL
            )
            // Do NOT call result.success() here — we resolve it after the grant
        }
    }

    private fun placeCall(number: String, result: MethodChannel.Result) {
        try {
            android.util.Log.d("ZenoraCall", "Placing call to: $number")
            val intent = Intent(Intent.ACTION_CALL).apply {
                data = Uri.parse("tel:$number")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            android.util.Log.e("ZenoraCall", "Call failed: ${e.message}")
            result.error("CALL_FAILED", e.message, null)
        }
    }

    // ── Direct SMS via SmsManager (no app chooser) ───────────────────────────
    private fun sendDirectSms(number: String, message: String, result: MethodChannel.Result) {
        android.util.Log.d("ZenoraSMS", "sendDirectSms → $number")

        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            android.util.Log.d("ZenoraSMS", "Requesting SEND_SMS permission…")
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.SEND_SMS),
                REQ_SMS
            )
            result.success(false)
            return
        }

        try {
            val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                applicationContext.getSystemService(SmsManager::class.java)
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }
            val parts = smsManager.divideMessage(message)
            smsManager.sendMultipartTextMessage(number, null, parts, null, null)
            android.util.Log.d("ZenoraSMS", "SMS sent to: $number")
            result.success(true)
        } catch (e: Exception) {
            android.util.Log.e("ZenoraSMS", "SMS failed: ${e.message}")
            result.error("SMS_FAILED", e.message, null)
        }
    }

    // ── Permission result handler ────────────────────────────────────────────
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == REQ_CALL) {
            val granted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
            android.util.Log.d("ZenoraCall", "CALL_PHONE permission result: $granted")

            val savedResult = pendingCallResult
            val savedNumber = pendingCallNumber
            pendingCallResult = null
            pendingCallNumber = ""

            if (granted && savedResult != null && savedNumber.isNotEmpty()) {
                placeCall(savedNumber, savedResult)
            } else {
                savedResult?.error(
                    "PERMISSION_DENIED",
                    "CALL_PHONE permission was denied by the user.",
                    null
                )
            }
        }
    }
}