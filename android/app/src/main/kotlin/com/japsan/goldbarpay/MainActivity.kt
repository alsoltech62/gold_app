package com.japsan.goldbarpay

import android.os.Bundle
import com.facebook.FacebookSdk
import com.facebook.appevents.AppEventsLogger
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private lateinit var logger: AppEventsLogger

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize Facebook AppEventsLogger
        logger = AppEventsLogger.newLogger(this)
        
        // Log test event for Meta Dashboard verification
        logSentFriendRequestEvent()
    }

    /**
     * Logs custom test event to Facebook Analytics
     */
    fun logSentFriendRequestEvent() {
        if (::logger.isInitialized) {
            logger.logEvent("sentFriendRequest")
        }
    }
}
