package com.example.coach_android

/**
 * Channel names used for communication between Dart and native code
 * Keep these in sync with lib/constants/channel_names.dart
 */
object ChannelNames {
    // Main app methods (used by main Flutter engine)
    const val MAIN_METHODS = "com.example.coach_android/methods"
    
    // Background service channels (used by background Flutter engine)
    const val BACKGROUND_METHODS = "com.example.coach_android/background"
    const val BACKGROUND_EVENTS = "com.example.coach_android/background_events"
}