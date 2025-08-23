/// Channel names used for communication between Dart and native code
class ChannelNames {
  // Main app methods (used by main Flutter engine)
  static const String mainMethods = 'com.example.coach_android/methods';
  
  // Background service channels (used by background Flutter engine)
  static const String backgroundMethods = 'com.example.coach_android/background';
  static const String backgroundEvents = 'com.example.coach_android/background_events';
}